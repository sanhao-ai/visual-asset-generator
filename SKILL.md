---
name: visual-asset-generator
title: 视觉素材生成 Skill
description: 视觉素材生成 Skill——把一份源文档（课程大纲/方案/会议纪要）批量产出全套风格统一的视觉物料：可交互动效演示 PPT（单文件 HTML）、横版/竖版 PDF、手机长图海报、约 60 秒口播动效宣传视频（含数字人占位）。当用户说"视觉素材生成""全套物料""一份文档出 PPT 加长图加视频""文档转视频""宣传物料"时触发。Turn one source document (course outline, proposal, meeting minutes) into a full marketing asset kit — interactive HTML slide deck, landscape/portrait PDFs, mobile long-image poster, and a ~60s narrated motion-graphics video. Trigger words: full asset kit, document to video, promo materials.
---

# 视觉素材生成流水线（一份文档 → 全套视觉物料）

把一份源文档变成一整套风格统一的营销/传播物料。核心产出：

| 产出 | 形态 | 用途 |
|---|---|---|
| 演示 PPT | 单文件 HTML（16:9 固定舞台） | 投屏放映/浏览器交互 |
| 横版 PDF | 16:9 每页截图合成 | 提案/打印/邮件 |
| 竖版 PDF | 9:16 重排版 | 手机翻阅 |
| 长图海报 | 1080 宽 PNG | 微信/朋友圈/社群转发 |
| 宣传视频 | ~60s MP4（口播+动效+数字人占位） | 短视频平台/扫码看片 |

## 铁律（每一步都适用）

1. **对外文案先过目再开工**：口播稿等进入不可逆制作（渲染/发布）前，必须给用户确认。
2. **改动永远落文件源头**：交付物从文件重新导出；提醒用户别在浏览器编辑模式临时改（若演示稿带 localStorage 编辑快照，会被旧快照覆盖新版）。
3. **敏感凭证不进对话**：API Key 走本地文件或环境变量，输出与交付文件中禁止回显。
4. **图片一律 base64 内嵌**进单文件 HTML，防止外发丢图。
5. **全套物料复用同一设计系统**：风格一旦选定，PPT/PDF/长图/视频/背景板全部沿用（见 [references/style-system.md](references/style-system.md)）。
6. **不得虚构用户未提供的数据、案例、引言**；源文档明显笔误可修正，但必须逐条向用户报告改了什么。

## 工作流

### Step 0 · 读源文档 + 三问定调

- docx 用 `python3 -c "import docx"` 提取段落+表格；PDF 用 PyMuPDF（`import fitz`）；Markdown/纪要类直接读文本。
- 向用户一次问齐三件事（决定所有排版取舍，不可跳过）：
  1. 用途：招生物料 / 客户提案 / 内部汇报 / 两者兼顾
  2. 篇幅：8 页内精简 / 10-14 页标准 / 15+ 页详细
  3. 密度：高密度可独立阅读 / 低密度演讲主导
- 若用户已有品牌风格档案（见 Step 1），直接沿用并只确认一次。

### Step 1 · 确定风格

- 优先使用用户已有的风格档案（`references/styles/` 下，或用户提供的品牌规范/参考截图）。
- 没有既定风格时，按 [references/style-system.md](references/style-system.md) 的框架，从用户品牌色/参考图中提取设计令牌，生成 **3 个单页封面预览（HTML）** 给用户对比选择——**禁止让用户用语言描述风格，直接给图选**。
- 用户确认后把风格规格存为 `references/styles/<风格名>.md`，全套物料与未来项目复用。

### Step 2 · 生成演示 PPT（HTML 演示稿）

自包含规范（导出脚本按此约定工作）：

- 单文件 HTML；固定舞台 1920×1080，按视口等比缩放（`transform: scale()` 或 `zoom`）。
- 每页一个 `<section class="slide">`；支持键盘/点击翻页。
- 入场动效用 IntersectionObserver 或 `.reveal` 类元素（导出 PDF 时会强制显示，见 scripts/export-pdf.sh）。
- Google Fonts 等 CDN 资源可用（导出时起本地 HTTP 服务加载）。
- 每页信息量按 Step 0 的密度设定；表格页注意 16:9 内不越界。
- 交付前验证：JS 逐页扫描元素越界（排除装饰性溢出元素）+ 浏览器截图抽查最密页。
- 本地预览起 `python3 -m http.server <port>`；改文件后浏览器吃缓存时 URL 加 `?v=N` 强刷。
- 迭代阶段用户每次一句话指令（"P1 加人像照""加一页全景表"），只改文件，小改动一次验证即交付，别多轮截图拖沓。

### Step 3 · 导出可读形态（PDF ×2 + 长图）

命令配方见 [references/export-recipes.md](references/export-recipes.md)：

- 横版 PDF：本仓库 `scripts/export-pdf.sh`（首次运行自动装 Playwright）
- 竖版 PDF：复制脚本改视口 1080×1920 + 把 HTML stage 重排为竖版（表格页拆成卡片式上下页）
- 长图海报：1080 宽 HTML → puppeteer `fullPage:true` 截图，1.5x 高清

### Step 4 · 宣传视频（口播 + 动效 + 数字人占位）

**先对稿，后开工**：

1. 按「Hook—定位—卖点—成果—结尾钩子」写口播稿；字数≈目标秒数×5.5（1.2 倍语速中文约 5.5 字/秒）；给用户逐句确认。
2. 出分镜表（时间点 × 口播点 × 动效）让用户过目。
3. 确认画幅（默认 16:9，数字人居左侧中间）、语速、数字人接入方式：
   - 有数字人服务（如 HeyGen 等）优先接入，凭证走本地配置；
   - 不可用时用形象照占位（左侧中间，呼吸光环）+ edge-tts 配音，预留替换位，后续换数字人不动构图。

渲染配方（TTS/时间轴/逐帧/混音/BGM）全部在 [references/video-pipeline.md](references/video-pipeline.md)。
BGM 硬性要求：**轻快愉悦**（ukulele/钟琴/拍手类），禁止低频 drone"嗡嗡声"。

### Step 5 · 收尾增值（按需）

- 在线发布：任选静态托管（GitHub Pages / Netlify / Vercel / 云厂商静态托管），固定域名重复发布链接不变，二维码永不过时。
- 二维码用 Python `qrcode` 库生成（ERROR_CORRECT_H + 圆点样式），base64 嵌入背景板/长图。
- 需要展台/提案背景板时：主标题+流水线示意（源文档→PPT→长图→视频）+二维码，风格沿用设计系统。
- 全部产物输出到统一的输出目录；命名「主题-用途-形态」。

## 环境依赖检查（开工前跑一次）

```bash
bash scripts/check-env.sh
```

缺什么按脚本提示安装：`pip3 install edge-tts qrcode pymupdf python-docx`；`npm install puppeteer-core`；ffmpeg 见官方下载。Chrome/Chromium 由脚本自动探测（支持 macOS / Linux / Windows Git Bash，可用 `CHROME_PATH` 环境变量指定）。

## 复盘沉淀

每次完整跑完：新风格/新坑/新配方补充进 `references/` 对应文件或风格档案；主动问用户是否把本次定制更新进本技能。
