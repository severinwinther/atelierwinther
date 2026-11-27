#!/usr/bin/env python3
import json, os, sys

PROSJEKTER_DIR = "prosjekter"
OUTPUT_FILE    = "prosjekter.json"
IMAGE_EXTS     = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif"}

def scan():
    if not os.path.isdir(PROSJEKTER_DIR):
        return []
    result = []
    folders = sorted(
        (f for f in os.listdir(PROSJEKTER_DIR)
         if os.path.isdir(os.path.join(PROSJEKTER_DIR, f))),
        reverse=True
    )
    for folder in folders:
        path      = os.path.join(PROSJEKTER_DIR, folder)
        info_path = os.path.join(path, "info.json")
        if not os.path.exists(info_path):
            continue
        with open(info_path, encoding="utf-8") as f:
            try:
                info = json.load(f)
            except json.JSONDecodeError:
                continue
        files  = sorted(os.listdir(path))
        cover  = None
        bilder = []
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext not in IMAGE_EXTS:
                continue
            rel = f"{PROSJEKTER_DIR}/{folder}/{fn}"
            if fn.lower().startswith("cover"):
                cover = rel
            else:
                bilder.append(rel)
        if cover:
            bilder.insert(0, cover)
        entry = {"id": folder, "cover": cover or (bilder[0] if bilder else None), "bilder": bilder, **info}
        result.append(entry)
    return result

def main():
    data = scan()
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    main()
