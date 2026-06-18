# 飞书授权说明（扣子平台授权，一键即用）

这个技能把白板写进**你自己的飞书租户**。鉴权走扣子的**平台授权**——扣子官方已集成飞书 OAuth，
你只需在扣子里点一下授权：

1. 安装/使用技能时，扣子引导你授权飞书（跳转飞书同意页，确认即可）；
2. 运行时扣子按命名约定 `COZE_{CREDENTIAL_NAME 大写}_{COZE_PROJECT_ID}` 把你的 `user_access_token`
   注入环境变量（本技能即 `COZE_FEISHU_BOARD_$COZE_PROJECT_ID`）；
3. 技能即以**你本人身份**直连飞书 OpenAPI，把白板写进你自己的云文档。

**你不需要建飞书应用、不需要填任何密钥、也不需要跑设备码**。技能代码不碰 OAuth，token 不落盘、不进 git。

## skill_credentials 声明（开发者在 Skill Builder 里调用）

```python
skill_credentials(
    credential_name="feishu_board",   # 注入变量名 = COZE_FEISHU_BOARD_{COZE_PROJECT_ID}
    auth_type=3,                       # 3 = OAuth
    # 平台授权：不传 custom_oauth_url，扣子用其内置飞书集成（跨租户可用）
    allowed_domain="open.feishu.cn",   # 两发接口同域
    credential_purpose="飞书白板：建文档 + 导出预览图",
)
```

注入的环境变量名按 `COZE_{credential_name 大写}_{COZE_PROJECT_ID}` 拼成（脚本里 `CREDENTIAL_NAME` 常量
须与此 `credential_name` 保持一致）。**赋值方式选「消费者授权」**——每个用户用自己的飞书身份授权，
白板写进各自的云空间，互相隔离。

## 需要的 scope（同意页应包含）

| 用途 | scope |
|---|---|
| 建云文档 | `docx:document:create` |
| 内嵌 SVG 解析成白板节点 | `board:whiteboard:node:create` |
| 导出白板预览图 | `board:whiteboard:node:read` |

> 已对真实飞书 API 验证：这三个 scope 足够建文档 + 导白板，不需要 drive 等其它权限。

## 用到的 OpenAPI（写入层 `scripts/feishu_write.py`）

- `POST /open-apis/docs_ai/v1/documents` — body `{content:"<title>…</title><whiteboard type=\"svg\">…</whiteboard>", format:"xml"}`，
  服务端把内嵌 SVG 解析成可编辑白板节点，返回文档链接 + 白板 block token。
- `GET /open-apis/board/v1/whiteboards/<token>/download_as_image` — 导出 ~2560×2560 预览图（仅供核对实时白板）。

均以 `Authorization: Bearer <注入的 user_access_token>` 调用。**第三方请求必须用
`from coze_workload_identity import requests`**——只有经这个代理发出、且域名在 `allowed_domain` 内，
扣子才把占位符 token 换成真值并校验域名。用 `urllib`/原生 `requests` 会拿着占位符直接出网、鉴权失败。

> `skill_credentials(...)` 不写进 skill 文件，而是在扣子**项目侧**注册（生成/配置凭证时由平台登记）。
> skill 运行时只负责按上面的约定**读注入的环境变量**。

## 注意事项

- 授权对**你本人**有效，写入的文档归你所有，落在你自己的云空间。
- 国际版 Lark 对应域名为 `open.larksuite.com`（如需支持，另在 `allowed_domain` 与脚本 `BASE` 增配）。
- 诊断：`scripts/probe_board_api.py` 可单独验证这两发接口与当前 token 的 scope（开发自测用，不随包分发）。
