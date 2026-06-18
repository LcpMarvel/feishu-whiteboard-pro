#!/usr/bin/env python3
"""
feishu_write.py — 把一张 SVG 写进用户飞书、成为可编辑白板，并导出预览图。

授权模型：扣子「平台授权」。用户在扣子里一键授权飞书后，扣子把用户的 user_access_token
按命名约定 COZE_{CREDENTIAL_NAME 大写}_{COZE_PROJECT_ID} 注入环境变量（如
COZE_FEISHU_BOARD_7652555566874656814）——加载时是占位符，出网到 open.feishu.cn 时由扣子
服务端代理换成真 token 并校验域名。本脚本不碰 OAuth、不依赖 lark-cli。

两发 OpenAPI（已对真实飞书验证通过）：
  POST /open-apis/docs_ai/v1/documents               建带内嵌 <whiteboard type="svg"> 的文档，
                                                      服务端解析 SVG 成可编辑白板节点
  GET  /open-apis/board/v1/whiteboards/<t>/download_as_image   导出白板预览图

需要的 scope（在 skill_credentials 平台授权里声明）：
  docx:document:create · board:whiteboard:node:create · board:whiteboard:node:read

用法：
  python3 feishu_write.py --svg <path> [--title <str>] [--image <out.png>]
"""
import argparse
import json
import os
import sys
import urllib.request
import urllib.error

BASE = "https://open.feishu.cn"
CREDENTIAL_NAME = "feishu_board"   # 须与 skill_credentials 的 credential_name 一致


def token():
    """平台授权注入的 user_access_token。变量名 = COZE_{CREDENTIAL_NAME 大写}_{COZE_PROJECT_ID}。
    任一缺失直接抛——没有兜底，早暴露早修。"""
    pid = os.environ.get("COZE_PROJECT_ID", "").strip()
    if not pid:
        sys.exit("COZE_PROJECT_ID 未设置：本脚本须在扣子运行时环境内执行")
    var = f"COZE_{CREDENTIAL_NAME.upper()}_{pid}"
    t = os.environ.get(var, "").strip()
    if not t:
        sys.exit(f"{var} 未注入：检查扣子平台授权是否完成、"
                 f"skill_credentials 的 credential_name 是否为 {CREDENTIAL_NAME!r}")
    return t


def call(method, path, body=None, binary=False):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token()}")
    if data is not None:
        req.add_header("Content-Type", "application/json; charset=utf-8")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return raw if binary else json.loads(raw.decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        sys.exit(f"飞书 API {method} {path} HTTP {e.code}：{e.read().decode('utf-8', 'replace')[:800]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--svg", required=True)
    ap.add_argument("--title", default="白板")
    ap.add_argument("--image")
    a = ap.parse_args()

    with open(a.svg, encoding="utf-8") as f:
        svg = f.read()
    content = f'<title>{a.title}</title><whiteboard type="svg">{svg}</whiteboard>'

    # ① 建文档（内嵌白板，用户本人身份）
    j = call("POST", "/open-apis/docs_ai/v1/documents", {"content": content, "format": "xml"})
    if j.get("code") not in (0, None):
        sys.exit(f"建文档失败 code={j.get('code')} msg={j.get('msg')!r}")
    doc = (j.get("data") or {}).get("document") or {}
    doc_url = doc.get("url")
    wb_token = next((b.get("block_token") for b in (doc.get("new_blocks") or [])
                     if b.get("block_type") == "whiteboard"), None)
    if not (doc_url and wb_token):
        sys.exit(f"建文档返回缺 url/whiteboard token：{json.dumps(j, ensure_ascii=False)[:800]}")
    print(f"DOC_URL={doc_url}")
    print(f"WHITEBOARD_TOKEN={wb_token}")

    # ② 导出预览图（飞书返回 ~2560×2560 固定方图，仅供核对实时白板，不作交付图）
    if a.image:
        img = call("GET", f"/open-apis/board/v1/whiteboards/{wb_token}/download_as_image", binary=True)
        if img[:3] not in (b"\x89PN", b"\xff\xd8\xff"):
            sys.exit(f"导出非图片：{img[:300]!r}")
        with open(a.image, "wb") as f:
            f.write(img)
        print(f"IMAGE={a.image}")


if __name__ == "__main__":
    main()
