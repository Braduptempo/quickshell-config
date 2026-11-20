#!/usr/bin/env python3
"""Generate data/emoji.json for the launcher's emoji picker.

Uses the Unicode database that ships with Python, so no download is needed.
Run from the repo root: python3 scripts/dev/gen-emoji.py
Each entry is [emoji, name]; names are lower case Unicode names.
"""
import json
import unicodedata

# Blocks that hold pictographic emoji (flags and skin tone modifiers are left out)
RANGES = [
    (0x1F300, 0x1F5FF),  # symbols and pictographs
    (0x1F600, 0x1F64F),  # emoticons
    (0x1F680, 0x1F6FF),  # transport and map
    (0x1F900, 0x1F9FF),  # supplemental symbols and pictographs
    (0x1FA70, 0x1FAFF),  # symbols and pictographs extended-A
    (0x2600, 0x26FF),    # miscellaneous symbols
    (0x2700, 0x27BF),    # dingbats
]
SKIP = range(0x1F3FB, 0x1F400)  # skin tone modifiers

out = []
for start, end in RANGES:
    for cp in range(start, end + 1):
        if cp in SKIP:
            continue
        ch = chr(cp)
        try:
            name = unicodedata.name(ch).lower()
        except ValueError:
            continue
        out.append([ch, name])

with open("data/emoji.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
print(f"{len(out)} emoji written to data/emoji.json")
