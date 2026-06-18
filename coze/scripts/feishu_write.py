#!/usr/bin/env python3
"""
feishu_write.py — 把一张 SVG 写进用户飞书、成为可编辑白板，并导出预览图。

授权模型：扣子「平台授权」。用户在扣子里一键授权飞书后，扣子把用户的 user_access_token
注入环境变量 COZE_{CREDENTIAL_NAME 大写}_{后缀}（如 COZE_FEISHU_WHITEBOARD_<id>，后缀因环境而异，
故下方按前缀扫）。**该变量只在技能被扣子运行时调用时注入，裸终端 shell 没有。** 注入值是占位符——
只有当出网请求经 `coze_workload_identity` 的 requests 发出、且域名在凭证 allowed_domain 内时，
扣子服务端代理才把它换成真 token。**因此第三方 API 必须用 coze_workload_identity.requests，不能用 urllib/原生 requests。**

两发 OpenAPI（已对真实飞书验证）：
  POST /open-apis/docs_ai/v1/documents               建带内嵌 <whiteboard type="svg"> 的文档，
                                                      服务端解析 SVG 成可编辑白板节点
  GET  /open-apis/board/v1/whiteboards/<t>/download_as_image   导出白板预览图

凭证 feishu_whiteboard 需含 scope：docx:document(建文档) · board:whiteboard:node:read(导出图)。

用法：
  python3 feishu_write.py --svg <path> [--title <str>] [--image <out.png>]
"""
import argparse
import json
import os
import sys

# 第三方 API 调用必须从此包导入：凭证代理在这一层把占位符 token 换成真值并校验域名。
from coze_workload_identity import requests

BASE = "https://open.feishu.cn/open-apis"
CREDENTIAL_NAME = "feishu_whiteboard"   # 须与扣子项目里声明的 credential_name 一致


def token():
    """平台授权注入的 user_access_token。变量名形如 COZE_{CREDENTIAL_NAME 大写}_{后缀}，
    后缀是 project_id 还是 skill_id 因环境而异，故按前缀扫，不写死后缀。
    注意：凭证只在「技能被扣子运行时调用」的上下文注入，裸终端 shell 不会有——早暴露早修。"""
    prefix = f"COZE_{CREDENTIAL_NAME.upper()}_"
    hits = {k: v.strip() for k, v in os.environ.items() if k.startswith(prefix) and v.strip()}
    if not hits:
        sys.exit(f"未找到注入凭证（前缀 {prefix}*）：确认本技能是被扣子运行时调用（裸终端不会注入），"
                 f"且凭证 {CREDENTIAL_NAME!r} 已声明并完成平台授权")
    if len(hits) > 1:
        sys.exit(f"匹配到多个凭证变量，无法判定用哪个：{list(hits)}")
    return next(iter(hits.values()))


def call(method, path, body=None):
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    url = BASE + path
    if method == "GET":
        r = requests.get(url, headers=headers, timeout=30)
    elif method == "POST":
        r = requests.post(url, headers=headers, json=body, timeout=30)
    else:
        sys.exit(f"unexpected method {method}")
    if r.status_code >= 400:
        sys.exit(f"飞书 API {method} {path} HTTP {r.status_code}：{r.text[:800]}")
    return r


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
    j = call("POST", "/docs_ai/v1/documents", {"content": content, "format": "xml"}).json()
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
        img = call("GET", f"/board/v1/whiteboards/{wb_token}/download_as_image").content
        if img[:3] not in (b"\x89PN", b"\xff\xd8\xff"):
            sys.exit(f"导出非图片：{img[:300]!r}")
        with open(a.image, "wb") as f:
            f.write(img)
        print(f"IMAGE={a.image}")


if __name__ == "__main__":
    main()
