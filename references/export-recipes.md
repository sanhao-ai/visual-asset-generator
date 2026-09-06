# 导出配方（PDF / 长图 / 二维码 / base64）

所有路径以本 skill 仓库根目录为基准（下文用 `$SKILL_DIR` 表示）。各 Agent 环境获取仓库根目录的方式不同，执行时先解析出绝对路径再拼命令。

## 横版 PDF（16:9）

```bash
bash "$SKILL_DIR/scripts/export-pdf.sh" <deck.html> [out.pdf] [--compact]
```

- 幻灯片必须用 `class="slide"`；首跑自动装 Playwright（约 1 分钟）。
- PDF >10MB 时加 `--compact`（1280×720 渲染，体积降 50-70%）。

## 竖版 PDF（9:16）

1. 源 deck HTML **复制一份重排**为竖版：stage 改 1080×1920，缩放公式 `Math.min(innerWidth/1080, innerHeight/1920)`；宽表格拆成上下两页卡片式清单；内容页改纵向堆叠。
2. 复制导出脚本改默认视口：

```bash
sed 's/VIEWPORT_W=1920/VIEWPORT_W=1080/; s/VIEWPORT_H=1080/VIEWPORT_H=1920/' \
  "$SKILL_DIR/scripts/export-pdf.sh" > /tmp/export-pdf-portrait.sh
bash /tmp/export-pdf-portrait.sh <deck-portrait.html> <out-竖版.pdf>
```

## Chrome/Chromium 探测（跨平台）

puppeteer-core 不带浏览器，需要系统 Chrome。优先级：

1. 环境变量 `CHROME_PATH`
2. macOS：`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
3. Linux：`google-chrome` / `chromium` / `chromium-browser`（`which` 探测）
4. Windows（Git Bash / WSL）：`/c/Program Files/Google/Chrome/Application/chrome.exe`

```javascript
const { existsSync } = require('fs');
const candidates = [
  process.env.CHROME_PATH,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
].filter(Boolean);
const chrome = candidates.find(p => existsSync(p)) || 'google-chrome'; // 最后交给 PATH
```

## 长图海报（1080 宽 PNG）

HTML 按 1080 宽做纵向自然流式排版（不用固定 stage），puppeteer 整页截图：

```javascript
const puppeteer = require('puppeteer-core');
const b = await puppeteer.launch({
  executablePath: chrome,  // 见上节探测
  headless: 'new', args: ['--no-sandbox', '--force-device-scale-factor=1'] });
const p = await b.newPage();
await p.setViewport({ width: 1080, height: 1600, deviceScaleFactor: 1.5 }); // 1.5x 高清
await p.goto('file:///.../poster.html', { waitUntil: 'networkidle0' });
await p.evaluate(() => document.fonts.ready);
await new Promise(r => setTimeout(r, 800)); // 等字体渲染稳定
await p.screenshot({ path: '长图.png', fullPage: true });
await b.close();
```

## 图片 base64 内嵌（防外发丢图）

```python
import base64
b64 = base64.b64encode(open('photo.jpg','rb').read()).decode()
s = open(html_path, encoding='utf-8').read()
s = s.replace('src="photo.jpg"', f'src="data:image/jpeg;base64,{b64}"')
open(html_path, 'w', encoding='utf-8').write(s)
```

大图先压缩：`img.thumbnail((900,1200), Image.LANCZOS)` + JPEG quality=88（人像照约 115KB，全套内嵌后单文件仍轻量）。

## 二维码

```python
import qrcode
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.moduledrawers.pil import RoundedModuleDrawer
qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_H, box_size=12, border=2)
qr.add_data(url); qr.make(fit=True)
img = qr.make_image(image_factory=StyledPilImage, module_drawer=RoundedModuleDrawer(),
                    fill_color='#1a1a1a', back_color='#ffffff')
img.save('qr.png')  # fill_color 建议取风格令牌的 --ink
```

在线发布用任意静态托管（GitHub Pages / Netlify / Vercel 等）：固定自定义域名后重复发布链接不变，二维码不用换。

## 验证注意

- 本地 HTML 验证：`python3 -m http.server <port>` 起服务（部分浏览器自动化工具 navigate 不支持 file://）。
- 改文件后浏览器吃缓存 → URL 加 `?v=N`。
- 成片抽帧验证：`ffmpeg -ss <t> -i in.mp4 -frames:v 1 out.png` **每个时间点单独一条命令**（多输入共用时默认全取第一个输入流，会抽错帧）。
