# 视觉素材生成 Skill / Visual Asset Generator Skill

**一份源文档 → 全套视觉物料。** 把课程大纲、产品方案、会议纪要变成一整套风格统一的传播物料：

**One source document → a full marketing asset kit.** Turn a course outline, proposal, or meeting minutes into a consistent set of visual assets:

| 产出 Asset | 形态 Format | 用途 Use |
|---|---|---|
| 演示 PPT | 单文件 HTML（16:9，可交互动效） | 投屏放映 / 浏览器交互 |
| 横版 PDF | 16:9 | 提案 / 打印 / 邮件 |
| 竖版 PDF | 9:16 重排版 | 手机翻阅 |
| 长图海报 | 1080 宽 PNG | 微信 / 社群转发 |
| 宣传视频 | ~60s MP4（口播 + 动效 + 数字人占位） | 短视频平台 / 扫码看片 |

> 🎬 效果展示（待补充）：建议在此放一段 15-20 秒的成品 GIF——源文档 → 五种产物的切换演示。这是别人决定要不要用的一半因素。

---

## 它是怎么工作的 / How it works

这是一个 **Agent Skill**（遵循 SKILL.md 约定，适配 QwenWork、Claude Code 等支持 Agent Skills 的工具）。安装后对 Agent 说：

```
把这份文档做成全套视觉物料：演示 PPT、横竖版 PDF、手机长图海报、60 秒宣传视频。
源文档：examples/sample-course-outline.md
用途：招生
```

Agent 会按 SKILL.md 的工作流执行：

```
Step 0  读源文档 + 三问定调（用途/篇幅/密度）
Step 1  确定风格（出 3 个封面预览给用户选，不凭空猜）
Step 2  生成单文件 HTML 演示稿（16:9 固定舞台）
Step 3  导出横版/竖版 PDF + 1080 宽长图
Step 4  宣传视频：口播稿先确认 → TTS 配音 + GSAP 动效逐帧渲染 + BGM 合成
Step 5  按需：二维码、发布链接、展台背景板
```

三条铁律：**对外文案先给用户过目再制作**；**不虚构用户没提供的数据和案例**；**全套物料共用同一套设计令牌**。

## 安装 / Install

**前置要求**：Node.js ≥ 18、Python 3.9+、ffmpeg、Chrome/Chromium（视频/长图渲染用）。装好后跑自检：

```bash
bash scripts/check-env.sh
```

### QwenWork 用户

```bash
git clone https://github.com/sanhao-ai/visual-asset-generator.git ~/.qwenworkcn/skills/visual-asset-generator
```

重启 QwenWork 后说"视觉素材生成"即可触发。

### Claude Code 用户

```bash
git clone https://github.com/sanhao-ai/visual-asset-generator.git ~/.claude/skills/visual-asset-generator
```

其他兼容 SKILL.md 规范的 Agent（Cursor 等）同理：clone 到各自的 skills 目录。

### 通用

也可以不经 Agent 直接用仓库里的脚本：`scripts/export-pdf.sh`（HTML 演示稿 → PDF，自包含，首跑自动装 Playwright）和 `scripts/check-env.sh`（环境自检）。

## 自定义风格 / Custom styles

本 skill **不内置任何品牌风格**。首次使用时 Agent 会给你 3 个封面预览供选择，确认后风格档案存入 `references/styles/`，之后所有项目自动沿用。已有品牌规范/VI 手册？直接提供给 Agent，或按 [references/style-system.md](references/style-system.md) 的格式自己写一份。

## 仓库结构 / Repository layout

```
├── SKILL.md                    # 技能定义（工作流 + 铁律）
├── references/
│   ├── style-system.md         # 风格定义/提取/复用框架
│   ├── export-recipes.md       # PDF/长图/二维码/base64 配方（跨平台）
│   └── video-pipeline.md       # 视频渲染管线（TTS/动效/混音/BGM）
├── scripts/
│   ├── check-env.sh            # 环境自检
│   └── export-pdf.sh           # HTML → PDF（自包含）
├── examples/
│   └── sample-course-outline.md  # 示例源文档
└── docs/
    └── troubleshooting.md      # 常见问题排查
```

## 已知限制 / Known limitations

- 视频渲染为逐帧截图合成（约 4 帧/秒），60 秒成片约需 5 分钟，建议放后台跑
- Windows 用户建议在 Git Bash 或 WSL 下运行
- 数字人位为占位设计（形象照 + 呼吸光环 + AI 配音），接 HeyGen 等服务可替换；API 凭证走本地配置，不经过对话

## License

[MIT](LICENSE)。`scripts/export-pdf.sh` 改编自社区 frontend-slides 技能的导出脚本。

## 反馈 / Feedback

遇到问题先看 [docs/troubleshooting.md](docs/troubleshooting.md)，解决不了欢迎提 Issue。欢迎 PR 贡献新的风格档案和平台配方。
