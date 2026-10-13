"""
Atelier Winther — fix-images.py
Run in the same folder as index.html:
    python fix-images.py

Works on Windows, Mac, and Linux.
Requires Python 3.6+ (no extra packages needed).
"""

import os, re, urllib.request, urllib.parse

HTML_FILE = "index.html"
IMG_DIR   = "img"

# ── 1. Read HTML ──────────────────────────────────────────────────────────────
if not os.path.exists(HTML_FILE):
    print(f"ERROR: {HTML_FILE} not found. Run this script in the same folder as index.html.")
    input("Press Enter to exit.")
    raise SystemExit(1)

with open(HTML_FILE, "r", encoding="utf-8") as f:
    html = f.read()

# ── 2. Find all image URLs ────────────────────────────────────────────────────
pattern = r"https://atelierwinther\.com/wp-content/uploads/[^\s\"']+"
urls    = sorted(set(re.findall(pattern, html)))
print(f"Found {len(urls)} images to download.\n")

os.makedirs(IMG_DIR, exist_ok=True)

# ── 3. Download images ────────────────────────────────────────────────────────
headers = {
    "User-Agent": "Mozilla/5.0",
    "Referer":    "https://atelierwinther.com/"
}

failed = []
for i, url in enumerate(urls, 1):
    # filename = basename without query string
    fname = os.path.basename(url.split("?")[0])
    dest  = os.path.join(IMG_DIR, fname)

    if os.path.exists(dest):
        print(f"[{i:2}/{len(urls)}] skip  {fname}")
        continue

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = resp.read()
        with open(dest, "wb") as out:
            out.write(data)
        print(f"[{i:2}/{len(urls)}] OK    {fname}")
    except Exception as e:
        print(f"[{i:2}/{len(urls)}] FAIL  {fname}  ({e})")
        failed.append(url)

print()

# ── 4. Rewrite HTML paths ─────────────────────────────────────────────────────
def replace_url(m):
    url   = m.group(0)
    fname = os.path.basename(url.split("?")[0])
    return f"img/{fname}"

html_new = re.sub(pattern, replace_url, html)

with open(HTML_FILE, "w", encoding="utf-8") as f:
    f.write(html_new)

print(f"✓ index.html rewritten — images now point to img/")
if failed:
    print(f"\n{len(failed)} images failed to download:")
    for u in failed:
        print(f"  {u}")

print("\nNext: commit the img/ folder to your GitHub repo and push.")
input("\nPress Enter to exit.")
