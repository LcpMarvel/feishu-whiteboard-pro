#!/usr/bin/env node
// fit-check — predict text/layout defects from an SVG BEFORE rendering.
//
// The whiteboard's text reflows by character (RULES.md): CJK/full-width ≈ 1em,
// Latin/digit/punct ≈ 0.6em. Most defects on these boards came from hand-placed
// coordinates where a label was wider than its box, or a between-box label spilled
// into a neighbour. This estimates every <text>'s width and checks it against the
// geometry, so those are caught before the render → look loop, not during it.
//
// Usage:  node fit-check.mjs <diagram.svg> [--pad N] [--margin N]
//   --pad     min breathing space inside a box, each side (default 12)
//   --margin  min distance content must keep from the canvas edge (default 40)
//
// Exit 1 if any defect is found. It is a predictor, not a renderer: treat hits as
// "look here", and still trust your eyes on the rendered image.

import { readFileSync } from "node:fs";

const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith("--"));
const opt = (name, def) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? Number(args[i + 1]) : def;
};
if (!file) {
  console.error("usage: node fit-check.mjs <diagram.svg> [--pad N] [--margin N]");
  process.exit(2);
}
const PAD = opt("pad", 12);
const MARGIN = opt("margin", 40);
const svg = readFileSync(file, "utf8");

// ---- viewBox ----------------------------------------------------------------
const vb = svg.match(/viewBox\s*=\s*"([\d.\s-]+)"/);
let [vbx, vby, vbw, vbh] = vb ? vb[1].trim().split(/\s+/).map(Number) : [0, 0, Infinity, Infinity];

// ---- character width model (RULES.md ratios) --------------------------------
function isWide(cp) {
  return (
    (cp >= 0x1100 && cp <= 0x115f) || // Hangul Jamo
    (cp >= 0x2e80 && cp <= 0x9fff) || // CJK radicals … unified
    (cp >= 0x3000 && cp <= 0x303f) || // CJK symbols & punctuation
    (cp >= 0x3040 && cp <= 0x30ff) || // kana
    (cp >= 0x3400 && cp <= 0x4dbf) || // CJK ext A
    (cp >= 0xac00 && cp <= 0xd7a3) || // Hangul syllables
    (cp >= 0xf900 && cp <= 0xfaff) || // CJK compat
    (cp >= 0xff00 && cp <= 0xff60) || // full-width forms
    (cp >= 0xffe0 && cp <= 0xffe6)
  );
}
function textWidth(str, fs) {
  let w = 0;
  for (const ch of str) {
    const cp = ch.codePointAt(0);
    if (ch === " ") w += fs * 0.3;
    else if (isWide(cp)) w += fs;
    else w += fs * 0.6;
  }
  return w;
}

function decode(s) {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#160;|&nbsp;/g, " ")
    .replace(/　/g, "　");
}

// ---- parse rects ------------------------------------------------------------
const rects = [];
for (const m of svg.matchAll(/<rect\b([^>]*)\/?>/g)) {
  const a = m[1];
  const num = (k) => {
    const r = a.match(new RegExp(`\\b${k}\\s*=\\s*"([\\d.-]+)"`));
    return r ? Number(r[1]) : null;
  };
  const x = num("x"), y = num("y"), w = num("width"), h = num("height");
  if (x == null || y == null || w == null || h == null) continue;
  rects.push({ x, y, w, h, area: w * h });
}

// ---- parse texts ------------------------------------------------------------
const texts = [];
for (const m of svg.matchAll(/<text\b([^>]*)>([\s\S]*?)<\/text>/g)) {
  const a = m[1];
  const raw = m[2];
  const content = decode(raw.replace(/<[^>]+>/g, "")); // flatten tspans
  if (!content.trim()) continue;
  const num = (k, def = null) => {
    const r = a.match(new RegExp(`\\b${k}\\s*=\\s*"([\\d.-]+)"`));
    return r ? Number(r[1]) : def;
  };
  const anchorM = a.match(/text-anchor\s*=\s*"(start|middle|end)"/);
  texts.push({
    x: num("x", 0),
    y: num("y", 0),
    fs: num("font-size", 16),
    anchor: anchorM ? anchorM[1] : "start",
    str: content,
  });
}

// ---- analysis ---------------------------------------------------------------
const issues = [];
const label = (t) => `"${t.str.length > 34 ? t.str.slice(0, 33) + "…" : t.str}"`;

for (const t of texts) {
  const w = textWidth(t.str, t.fs);
  let L, R;
  if (t.anchor === "middle") { L = t.x - w / 2; R = t.x + w / 2; }
  else if (t.anchor === "end") { L = t.x - w; R = t.x; }
  else { L = t.x; R = t.x + w; }

  // canvas bleed
  if (L < vbx + MARGIN || R > vbx + vbw - MARGIN) {
    issues.push(`BLEED   ${label(t)} extent [${Math.round(L)},${Math.round(R)}] < ${MARGIN}px from canvas edge (canvas ${vbx}..${vbx + vbw})`);
  }

  // smallest rect containing the anchor point = its box
  const inside = rects
    .filter((r) => t.x >= r.x && t.x <= r.x + r.w && t.y >= r.y && t.y <= r.y + r.h)
    .sort((a, b) => a.area - b.area)[0];

  if (inside) {
    const innerL = inside.x + PAD, innerR = inside.x + inside.w - PAD;
    if (L < innerL || R > innerR) {
      const over = Math.round(Math.max(innerL - L, R - innerR));
      issues.push(`OVERFLOW ${label(t)} ${t.fs}px ≈${Math.round(w)}px wide, box inner width ${Math.round(inside.w - 2 * PAD)}px — over by ${over}px (box x=${inside.x} w=${inside.w})`);
    }
  } else {
    // between-box label: does its horizontal extent intrude into any box at this y?
    for (const r of rects) {
      if (t.y >= r.y && t.y <= r.y + r.h && R > r.x && L < r.x + r.w) {
        const into = Math.round(Math.min(R, r.x + r.w) - Math.max(L, r.x));
        if (into > 2) {
          issues.push(`INTRUDE  ${label(t)} extent [${Math.round(L)},${Math.round(R)}] spills ${into}px into box x=${r.x}..${r.x + r.w} (it sits in no box)`);
          break;
        }
      }
    }
  }
}

// rects beyond canvas
for (const r of rects) {
  if (r.x < vbx - 1 || r.y < vby - 1 || r.x + r.w > vbx + vbw + 1 || r.y + r.h > vby + vbh + 1) {
    issues.push(`CLIP    rect x=${r.x} y=${r.y} ${r.w}×${r.h} extends past canvas ${vbw}×${vbh}`);
  }
}

// ---- report -----------------------------------------------------------------
console.log(`fit-check ${file}`);
console.log(`  canvas ${vbw}×${vbh} · ${rects.length} rects · ${texts.length} texts · pad ${PAD} · margin ${MARGIN}`);
if (!issues.length) {
  console.log("  ✓ no predicted fit defects");
  process.exit(0);
}
console.log(`  ${issues.length} predicted defect(s):`);
for (const i of issues) console.log("   • " + i);
console.log("\n  Fix in the SVG (widen the box, shorten the label, or open the gutter), then re-run. Still confirm on the render.");
process.exit(1);
