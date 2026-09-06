#!/usr/bin/env bash
# check-env.sh — 视觉素材生成 Skill 环境自检（macOS / Linux / Windows Git Bash）
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
miss() { echo -e "${RED}✗${NC} $*"; FAIL=1; }
FAIL=0

echo -e "${CYAN}视觉素材生成 Skill · 环境自检${NC}"
echo ""

# ── 基础工具 ─────────────────────────────────────────
for cmd in node npm python3 ffmpeg; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd $(command -v $cmd)"
    else
        case "$cmd" in
            node|npm) miss "$cmd 未安装 → https://nodejs.org 下载安装" ;;
            python3)  miss "$cmd 未安装 → https://www.python.org 下载安装" ;;
            ffmpeg)   miss "$cmd 未安装 → https://ffmpeg.org/download.html 下载安装" ;;
        esac
    fi
done
echo ""

# ── Python 库 ───────────────────────────────────────
check_py() {
    python3 -c "import $1" 2>/dev/null && ok "python: $1" || miss "python: $1 未安装 → pip3 install $2"
}
check_py fitz        "pymupdf"        # PDF 读取
check_py docx        "python-docx"    # Word 读取
check_py edge_tts    "edge-tts"       # 视频配音
check_py qrcode      "qrcode[pil]"    # 二维码
check_py numpy       "numpy"          # BGM 合成
check_py PIL         "pillow"         # 图片压缩
echo ""

# ── Chrome / Chromium ───────────────────────────────
CHROME_FOUND=""
detect_chrome() {
    if [[ -n "${CHROME_PATH:-}" && -x "${CHROME_PATH}" ]]; then
        CHROME_FOUND="$CHROME_PATH"; return
    fi
    local candidates=(
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        "/Applications/Chromium.app/Contents/MacOS/Chromium"
        "/usr/bin/google-chrome" "/usr/bin/chromium" "/usr/bin/chromium-browser"
        "/snap/bin/chromium"
        "/c/Program Files/Google/Chrome/Application/chrome.exe"
        "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    )
    for c in "${candidates[@]}"; do
        [[ -x "$c" ]] && CHROME_FOUND="$c" && return
    done
    for c in google-chrome chromium chromium-browser chrome; do
        command -v "$c" &>/dev/null && CHROME_FOUND="$(command -v $c)" && return
    done
}
detect_chrome
if [[ -n "$CHROME_FOUND" ]]; then
    ok "浏览器: $CHROME_FOUND"
else
    warn "未探测到 Chrome/Chromium → 安装后重跑，或设 CHROME_PATH 环境变量指定路径"
    warn "（仅做 PPT/PDF 时 Playwright 会自动下载浏览器，可忽略本项）"
fi
echo ""

# ── 汇总 ────────────────────────────────────────────
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}环境就绪，可以开工。${NC}"
else
    echo -e "${YELLOW}有缺失项，按上面提示安装后重跑。缺 PPT/PDF 相关依赖不影响先出 HTML 演示稿。${NC}"
    exit 1
fi
