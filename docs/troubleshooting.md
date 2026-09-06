# 常见问题排查 / Troubleshooting

## 环境与安装

**Q: `check-env.sh` 提示找不到 Chrome？**
设置环境变量再重跑：`export CHROME_PATH="/你的/Chrome/路径"`。只做 PPT/PDF 时可忽略——Playwright 首跑会自动下载浏览器，Chrome 探测只影响长图/视频渲染（puppeteer-core 路线）。

**Q: Windows 能用吗？**
可以，推荐在 Git Bash 或 WSL 里运行（脚本为 bash）。WSL 下探测不到 Windows 侧 Chrome 时，设 `CHROME_PATH` 指向 `/mnt/c/Program Files/Google/Chrome/Application/chrome.exe`。

**Q: `pip3 install edge-tts` 装不上？**
确认 python3 和 pip3 可用；国内网络可用镜像：`pip3 install edge-tts -i https://pypi.tuna.tsinghua.edu.cn/simple`。

## PDF 导出

**Q: export-pdf.sh 报 "No .slide elements found"？**
演示稿每页必须用 `<section class="slide">` 或 `<div class="slide">` 包裹。

**Q: 首次导出卡很久？**
首次运行会在临时目录安装 Playwright + 下载 Chromium（约 1 分钟，视网络），之后就快了。

**Q: 导出的 PDF 字体不对/空白？**
导出走本地 HTTP 服务加载 Google Fonts——确认网络可达；离线环境把字体文件本地化并用 `@font-face` 引入。

**Q: PDF 超过 10MB？**
加 `--compact`（1280×720 渲染，体积降 50-70%），或先压缩内嵌图片（见 references/export-recipes.md 的 base64 一节）。

## 视频渲染

**Q: 渲染出的视频某些元素一直不出现？**
CSS 里写了 `opacity:0` 的元素不能用 `gsap.from()`，必须用 `gsap.fromTo()`——详见 references/video-pipeline.md 的"致命陷阱"。

**Q: 抽帧检查发现画面和预期时间点对不上？**
`ffmpeg -ss` 抽帧每个时间点必须单独一条命令，多输入合并会全取第一个输入流。

**Q: BGM 听起来嗡嗡的？**
那是低频 drone，本管线明确禁止。按 video-pipeline.md 第 6 节的轻快配方（ukulele/钟琴/拍手）重新合成。

## 风格与产物

**Q: 想换自己的品牌风格？**
按 references/style-system.md 定义风格档案存到 `references/styles/<你的风格名>.md`，下次生成会自动沿用。

**Q: 浏览器里改过的内容导出后又变回去了？**
改动要落在 HTML 文件源头再导出；浏览器编辑态的 localStorage 快照不持久（键名通常为 `deck-edits-*`，清除后以文件为准）。

---

更多问题欢迎提 [Issue](../../issues)。
