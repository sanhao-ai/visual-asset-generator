# 视频渲染管线（口播 + 动效 + 数字人占位）

依赖：ffmpeg、node + puppeteer-core、python3 + edge-tts + numpy、系统 Chrome/Chromium（探测方式见 export-recipes.md）。

## 1. 口播音轨（先过目再合成）

```bash
python3 -m edge_tts --voice zh-CN-XiaoxiaoNeural --rate=+20% \
  --text "口播文本" --write-media narration/s1.mp3
```
- 女声 `zh-CN-XiaoxiaoNeural`，男声 `zh-CN-YunjianNeural`；其他语言换对应 voice。
- `--rate=+20%` ≈ 1.2 倍语速；**必须用 `=` 语法**，否则负值被当 CLI flag。
- 字数估算：秒数 × 5.5 字（1.2 倍速中文）。
- 每场景一个 mp3，`ffprobe -show_entries format=duration` 测时长。
- 有数字人服务（HeyGen 等）优先接入：凭证走本地配置文件/环境变量，不进对话、不进交付物；不可用时本管线兜底：形象照圆形占位（左侧中间，呼吸光环）+ edge-tts 配音，后续替换数字人不动构图。

## 2. 场景时间轴公式

```
场景时长 = 入场动画(~0.8s) + 口播时长 + 阅读缓冲(~1.2s)
口播起点 = 场景起点 + 0.8s
```
把每场景 (start, dur, narration_offset) 列成表再动手写动画。

## 3. 动效主舞台（GSAP 可 seek 时间轴）

单 HTML（1920×1080 固定舞台），**所有动画挂在一条 paused timeline 上并暴露 `window.__tl`**：

```javascript
const tl = gsap.timeline({ paused: true }); window.__tl = tl;
// 打字机：逐字符 span + tl.set 序列
function typeText(sel, text, start, per=0.05){ /* 每字符 opacity 0→1 */ }
// 鼠标：tl.to('#cursor',{x,y,duration,ease:'power2.inOut'})；点击=ripple fromTo + 指针 scale yoyo
// 场景切换：tl.to(id,{autoAlpha:1}) / 出场后 set visibility:hidden
```

**致命陷阱**：
- CSS 写了 `opacity:0` 的元素禁用 `gsap.from({opacity:0})`（0→0 永不显示），必须 `fromTo`。
- 禁用 CSS @keyframes（按真实时间跑，逐帧 seek 会乱），呼吸/旋转等循环效果用 timeline 的 `repeat`。
- 末尾 `tl.to({},{duration:1}, DUR)` 锁定总时长。

## 4. 逐帧渲染

```javascript
const puppeteer = require('puppeteer-core');
const b = await puppeteer.launch({
  executablePath: chrome,  // CHROME_PATH 探测，见 export-recipes.md
  headless: 'new', args: ['--no-sandbox','--force-device-scale-factor=1','--hide-scrollbars'] });
const p = await b.newPage(); await p.setViewport({ width: 1920, height: 1080 });
await p.goto('file:///.../index.html', { waitUntil: 'networkidle0' });
await p.evaluate(() => document.fonts.ready);
await p.waitForFunction('window.__tl && window.__tl.duration() > 60');
for (let i = 0; i < 30 * DUR; i++) {
  await p.evaluate(t => { window.__tl.pause(); window.__tl.time(t); }, i / 30);
  await p.screenshot({ path: `frames/f${String(i).padStart(5,'0')}.png` });
}
```
- 先抽 5-9 个关键时间点做冒烟测试目检版式，再跑全量（约 4 帧/秒，60s 片约 5 分钟，放后台跑）。
- `node -e` 里 `__dirname` 不可用，用绝对路径；写独立 .js 文件则无此问题。

## 5. 混音（口播 + BGM）

```bash
ffmpeg -y -i s1.mp3 -i s2.mp3 ... -i bgm.wav -filter_complex \
 "[0]adelay=800|800[a0];[1]adelay=12800|12800[a1];...[a0][a1]...amix=inputs=N:duration=longest:normalize=0,volume=1.6,alimiter=limit=0.95[vo];[vo][bg]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.97[aout]" \
 -map "[aout]" -ar 44100 -ac 2 -t <DUR> audio_final.wav
```
adelay 毫秒 = 场景口播起点。

## 6. BGM（numpy 合成，轻快风兜底）

**要求：轻快愉悦（ukulele/钟琴/拍手），禁止低频 drone 嗡鸣。** 配方：
- 112 BPM，C–G–Am–F 进行；每小节 8 分音符拨弦（sin+2/3 次谐波，`exp(-t*9)` 快衰减包络）
- 钟琴旋律每 2 小节一段 motif（正弦+失谐泛音，`exp(-t*4.5)`）
- 八分沙锤（高通噪声短 burst，音量 ≤0.05）+ 2/4 拍 clap
- 根音 bass 一小节一个；总峰值归一化到 0.30，淡入 1.5s 淡出 2.5s
- 有音乐生成服务时优先真人乐队质感，失败/不可重试时回落本配方。

## 7. 出片

```bash
ffmpeg -y -framerate 30 -i frames/f%05d.png -c:v libx264 -pix_fmt yuv420p -crf 19 -movflags +faststart video-only.mp4
ffmpeg -y -i video-only.mp4 -i audio_final.wav -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart final.mp4
```

质检：每时间点单独一条 `ffmpeg -ss <t> -i final.mp4 -frames:v 1 x.png` 抽帧目检（多输入合并命令会全取第一个输入流）。

## 8. 发布闭环

视频页（标题+video+标签）→ 静态托管发布（GitHub Pages / Netlify / Vercel 等）→ 固定链接可重复发布 → Python qrcode 生成二维码 → base64 嵌入长图海报/背景板。
