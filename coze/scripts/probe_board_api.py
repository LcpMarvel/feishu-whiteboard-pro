#!/usr/bin/env python3
"""
probe_board_api.py — 验证「换授权后」白板写入层那两发 OpenAPI，并打出当前 token 的精确 scope。

它做三件事，跑完给一份结论：
  0. 打印 lark-cli 当前已授权身份的 scope（A-prime 既能建文档又能导白板，
     所以这串 scope 就是「平台授权同意页」要逐条比对的清单）。
  1. POST /open-apis/docs_ai/v1/documents       —— 建带内嵌 SVG 白板的文档
  2. GET  /open-apis/board/v1/whiteboards/<t>/download_as_image —— 导出预览图

两种取数模式，自动选：
  - 设了环境变量 FEISHU_TOKEN（裸 user_access_token，模拟扣子注入）→ 走 urllib + Bearer，
    这是重写后的真实代码路径。
  - 没设 → 借已授权的 lark-cli 身份透传（`lark-cli api` / `whiteboard +query`），零配置即可跑。

用法：
    python3 probe_board_api.py                 # 借 lark-cli 已有授权
    FEISHU_TOKEN=u-xxxx python3 probe_board_api.py   # 用裸 token 走真实重写路径
"""
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

BASE = "https://open.feishu.cn"
TOKEN = os.environ.get("FEISHU_TOKEN", "").strip()

# 一张最小的合法白板 SVG，足够触发服务端解析成白板节点。
SVG = ('<svg xmlns="http://www.w3.org/2000/svg" width="320" height="200">'
       '<rect x="20" y="20" width="120" height="80" rx="8" fill="#e8eef7" stroke="#3b5b8c"/>'
       '<text x="80" y="65" font-size="16" text-anchor="middle" fill="#1f2d3d">probe</text>'
       '</svg>')
CONTENT = f'<title>board-api-probe</title><whiteboard type="svg">{SVG}</whiteboard>'


def hr(title):
    print("\n" + "=" * 8 + f" {title} " + "=" * 8)


def lark(*args, binary=False):
    """跑 lark-cli，返回 (returncode, stdout, stderr)。优先用全局 lark-cli，否则 npx。"""
    base = ["lark-cli"] if _has_lark_cli() else ["npx", "-y", "@larksuite/cli@latest"]
    p = subprocess.run(base + list(args), capture_output=True)
    out = p.stdout if binary else p.stdout.decode("utf-8", "replace")
    return p.returncode, out, p.stderr.decode("utf-8", "replace")


_LARK_CACHE = None
def _has_lark_cli():
    global _LARK_CACHE
    if _LARK_CACHE is None:
        _LARK_CACHE = subprocess.run(["which", "lark-cli"], capture_output=True).returncode == 0
    return _LARK_CACHE


def http(method, path, body=None, binary=False):
    """裸 Bearer 调用（重写后的真实路径）。返回 (status, bytes/str)。"""
    url = BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {TOKEN}")
    if data is not None:
        req.add_header("Content-Type", "application/json; charset=utf-8")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return r.status, raw if binary else raw.decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")


# ── 0. 当前授权 scope ───────────────────────────────────────────────
hr("0 · 当前 lark-cli 授权状态 + scope")
for sub in (["auth", "status"], ["auth", "scopes"]):
    rc, out, err = lark(*sub)
    print(f"$ lark-cli {' '.join(sub)}")
    print((out or err).strip()[:4000] or "(空)")
    print()

# ── 1. 建文档 ───────────────────────────────────────────────────────
hr("1 · 建文档 POST /open-apis/docs_ai/v1/documents")
doc_url = wb_token = None
if TOKEN:
    print("模式：裸 Bearer（FEISHU_TOKEN）")
    status, text = http("POST", "/open-apis/docs_ai/v1/documents",
                        {"content": CONTENT, "format": "xml"})
    print(f"HTTP {status}\n{text[:2000]}")
    try:
        j = json.loads(text)
    except Exception:
        j = {}
else:
    print("模式：lark-cli 透传（未设 FEISHU_TOKEN）")
    rc, out, err = lark("api", "POST", "/open-apis/docs_ai/v1/documents",
                        "--data", json.dumps({"content": CONTENT, "format": "xml"}),
                        "--as", "user")
    print((out or err).strip()[:2000])
    try:
        j = json.loads(out)
    except Exception:
        j = {}

doc = (j.get("data") or {}).get("document") or j.get("document") or {}
doc_url = doc.get("url")
for b in (doc.get("new_blocks") or []):
    if b.get("block_type") == "whiteboard":
        wb_token = b.get("block_token")
        break
print(f"\n→ DOC_URL = {doc_url}\n→ WHITEBOARD_TOKEN = {wb_token}")

# Feishu 权限不足时 code 通常是 99991672 / 1254xxx，错误体里会点名缺的 scope。
code = j.get("code")
if code not in (0, None):
    print(f"\n⚠️ 接口返回非 0 code={code} msg={j.get('msg')!r} —— 若是权限错误，上面错误体里会写明缺的 scope")

# ── 2. 导出图 ───────────────────────────────────────────────────────
hr("2 · 导出白板图 GET /open-apis/board/v1/whiteboards/<t>/download_as_image")
if not wb_token:
    print("没拿到 whiteboard token，跳过导出（先看第 1 步是不是权限/参数错）")
else:
    out_png = "probe_board.png"
    if TOKEN:
        status, raw = http("GET", f"/open-apis/board/v1/whiteboards/{wb_token}/download_as_image", binary=True)
        if status == 200 and isinstance(raw, bytes) and raw[:4] in (b"\x89PNG", b"\xff\xd8\xff\xe0"):
            with open(out_png, "wb") as f:
                f.write(raw)
            print(f"HTTP 200 → 已存 {out_png}（{len(raw)} bytes）")
        else:
            print(f"HTTP {status} → 非图片，错误体：\n{raw[:1500] if isinstance(raw, str) else raw[:200]}")
    else:
        rc, out, err = lark("whiteboard", "+query", "--whiteboard-token", wb_token,
                            "--output_as", "image", "--output", out_png, "--overwrite", "--as", "user")
        print((out or err).strip()[:1500])
        print(f"(rc={rc}) 若成功，图在 ./{out_png}")

# ── 结论 ────────────────────────────────────────────────────────────
hr("结论")
print(f"建文档: {'OK ' + doc_url if doc_url else '失败 —— 看第 1 步输出'}")
print(f"导白板: {'见第 2 步' }")
print("\n下一步：把第 0 步打出的 scope 清单，拿去和扣子飞书『平台授权』同意页逐条比对。")
print("两个接口域名都是 open.feishu.cn → skill_credentials 的 allowed_domain 就填它。")
