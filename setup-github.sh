#!/bin/bash
# Atelier Winther — GitHub Pages setup script
# Run this on your Mac: bash setup-github.sh
# Then push the created folder to GitHub and enable Pages.

set -e

SITE_DIR="atelierwinther-site"
IMG_DIR="$SITE_DIR/img"
HTML_SRC="index.html"   # path to the index.html you downloaded from Claude

# ── 1. Check for index.html ──────────────────────────────────────────────────
if [ ! -f "$HTML_SRC" ]; then
  echo "ERROR: index.html not found. Put this script in the same folder as index.html and re-run."
  exit 1
fi

echo "→ Creating site folder…"
mkdir -p "$IMG_DIR"
cp "$HTML_SRC" "$SITE_DIR/index.html"

# ── 2. Extract image URLs ─────────────────────────────────────────────────────
grep -o 'https://atelierwinther\.com/wp-content/uploads/[^"]*' "$HTML_SRC" | sort -u > /tmp/aw_urls.txt
TOTAL=$(wc -l < /tmp/aw_urls.txt | tr -d ' ')
echo "→ Downloading $TOTAL images…"

COUNT=0
while IFS= read -r url; do
  # filename: strip query string, take basename
  fname=$(basename "${url%%\?*}")
  dest="$IMG_DIR/$fname"
  if [ ! -f "$dest" ]; then
    curl -sS -L --max-time 20 \
      -H "Referer: https://atelierwinther.com/" \
      -o "$dest" "$url" && COUNT=$((COUNT+1)) || echo "  WARN: failed $url"
  else
    COUNT=$((COUNT+1))
  fi
  printf "\r  %d / %d" "$COUNT" "$TOTAL"
done < /tmp/aw_urls.txt
echo ""

# ── 3. Rewrite HTML paths ─────────────────────────────────────────────────────
echo "→ Rewriting image paths in HTML…"
# Replace full URL (with optional ?w=xxx) with local img/filename
python3 - <<'PYEOF'
import re, os

with open("atelierwinther-site/index.html", "r") as f:
    html = f.read()

def replace_url(m):
    url = m.group(0)
    fname = os.path.basename(url.split("?")[0])
    return f"img/{fname}"

html = re.sub(
    r'https://atelierwinther\.com/wp-content/uploads/[^\s"]+',
    replace_url,
    html
)

with open("atelierwinther-site/index.html", "w") as f:
    f.write(html)

print("  Done.")
PYEOF

# ── 4. Git init ───────────────────────────────────────────────────────────────
echo "→ Initialising git repo…"
cd "$SITE_DIR"
git init -q
git add .
git commit -q -m "Initial commit — Atelier Winther portfolio"

echo ""
echo "✓ Done! Folder ready: $SITE_DIR/"
echo ""
echo "Next steps:"
echo "  1. Create a repo on github.com (e.g. 'atelierwinther.com'), then:"
echo "     cd $SITE_DIR"
echo "     git remote add origin https://github.com/YOUR_USERNAME/atelierwinther.com.git"
echo "     git push -u origin main"
echo "  2. On GitHub: Settings → Pages → Source: Deploy from branch → main / (root) → Save"
echo "  3. Your site will be live at https://YOUR_USERNAME.github.io/atelierwinther.com"
echo "  4. Optional: add custom domain 'atelierwinther.com' in Pages settings."
