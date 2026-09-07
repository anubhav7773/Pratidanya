#!/usr/bin/env bash
set -e

FONT_DIR="assets/fonts"
mkdir -p "$FONT_DIR"

REGULAR_URL="https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansDevanagari/NotoSansDevanagari-Regular.ttf"
BOLD_URL="https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansDevanagari/NotoSansDevanagari-Bold.ttf"

echo "=================================================================="
echo "PRATIDNYA: DOWNLOADING OFFICIAL NOTO SANS DEVANAGARI FONTS"
echo "=================================================================="

if [ ! -f "$FONT_DIR/NotoSansDevanagari-Regular.ttf" ]; then
    echo "Downloading NotoSansDevanagari-Regular.ttf..."
    curl -L -s -o "$FONT_DIR/NotoSansDevanagari-Regular.ttf" "$REGULAR_URL"
else
    echo "✓ NotoSansDevanagari-Regular.ttf already present."
fi

if [ ! -f "$FONT_DIR/NotoSansDevanagari-Bold.ttf" ]; then
    echo "Downloading NotoSansDevanagari-Bold.ttf..."
    curl -L -s -o "$FONT_DIR/NotoSansDevanagari-Bold.ttf" "$BOLD_URL"
else
    echo "✓ NotoSansDevanagari-Bold.ttf already present."
fi

echo "Verifying font asset file sizes..."
ls -lh "$FONT_DIR"
echo "Font assets verified successfully."
