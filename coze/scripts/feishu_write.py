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

凭证 feishu_whiteboard 需含 scope（缺失症状见 CREDENTIALS.md）：
  docx:document:create（建文档）· board:whiteboard:node:create（解析 SVG 成节点）· board:whiteboard:node:read（导出图）

用法：
  python3 feishu_write.py --check                                       # 写前自检凭证是否注入
  python3 feishu_write.py --svg <path> [--title <str>] [--image <out.png>]
"""
import argparse
import json
import os
import sys

BASE = "https://open.feishu.cn/open-apis"
CREDENTIAL_NAME = "feishu_whiteboard"   # 须与扣子项目里声明的 credential_name 一致


PREFIX = f"COZE_{CREDENTIAL_NAME.upper()}_"

# 缺凭证时给 Agent 的结构化指引：照着转达用户，别自造方案。
AUTH_HINT = (
    f"未找到注入凭证（前缀 {PREFIX}*）。多半不是代码问题，而是上下文/授权问题：\n"
    f"  · 凭证只在「技能运行时」注入——主对话 / 裸终端不会有，请在扣子「调试/预览」里运行本技能。\n"
    f"  · 或凭证 {CREDENTIAL_NAME!r} 尚未在本项目注册/授权——在扣子为本项目注册 OAuth 凭证\n"
    f"    {CREDENTIAL_NAME}（平台授权、域名 open.feishu.cn）并完成授权。\n"
    f"  · 不要改用 lark-cli，也不要自造授权链接——本技能只依赖扣子注入。\n"
    f"  · 写入不可用 ≠ 任务失败：仍可把本地渲染的 PNG / SVG 交付用户，待授权后再写入。"
)


def find_credential():
    """返回 (变量名, token)；没有则 (None, None)。变量名形如 COZE_FEISHU_WHITEBOARD_<后缀>，
    后缀 project_id/skill_id 因环境而异，故按前缀扫，不写死后缀。"""
    hits = {k: v.strip() for k, v in os.environ.items() if k.startswith(PREFIX) and v.strip()}
    if len(hits) > 1:
        sys.exit(f"匹配到多个凭证变量，无法判定用哪个：{list(hits)}")
    return next(iter(hits.items())) if hits else (None, None)


def token():
    _, val = find_credential()
    if not val:
        sys.exit(AUTH_HINT)
    return val


def call(method, path, body=None):
    # 第三方 API 调用必须从此包导入：凭证代理在这一层把占位符 token 换成真值并校验域名。
    # 惰性导入 → --check 等不发请求的路径即使没有该模块也能跑。
    from coze_workload_identity import requests
    headers = {"Authorization": f"Bearer {token()}", "Content-Type": "application/json"}
    url = BASE + path
    if method == "GET":
        r = requests.get(url, headers=headers, timeout=30)
    elif method == "POST":
        r = requests.post(url, headers=headers, json=body, timeout=30)
    else:
        sys.exit(f"unexpected method {method}")
    if r.status_code >= 400:
        sys.exit(f"飞书 API {method} {path} HTTP {r.status_code}：{r.text[:800]}\n"
                 f"  · 若是权限/scope 错误码（如 99991672 / 99991679），对照 CREDENTIALS.md 的 scope 表补权限；"
                 f"建文档成功但导出图失败，通常是缺 board:whiteboard:node:read，可只交付文档链接，不影响白板本身。")
    return r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--svg")
    ap.add_argument("--title", default="白板")
    ap.add_argument("--image")
    ap.add_argument("--check", action="store_true",
                    help="自检：只报凭证注入状态，不写入。写飞书前先跑这个。")
    a = ap.parse_args()

    # 自检：写飞书前先确认凭证已注入，避免跑完整流程才炸。
    if a.check:
        name, val = find_credential()
        if val:
            print(f"READY: 凭证已注入（{name}），可写入飞书。")
            return
        print("NOT_READY:")
        print(AUTH_HINT)
        sys.exit(3)

    if not a.svg:
        sys.exit("--svg <path> 必填（仅自检请用 --check）")

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
