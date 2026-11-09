#!/usr/bin/env python3
"""Talvio Pixel Relics — full set generator (LOCAL ONLY).

Derives 7,777 unique 16-bit pixel-art NFTs from 4 AI masters
(owl / raven / deer / fox) in ~/workspace/talvio/full/masters/.

Every token differs by a deterministic combination of:
  * Animal master (4, ~1,944 each)
  * Tier (exact counts below) — shown as a coloured frame
  * Palette — hue / saturation / brightness shift of the master
  * Background — 1 of 8 dark night shades (background pixels replaced)
  * Accessory — 1 of 10 pixel badges drawn top-right
  * Horizontal flip
  * Starfield — 18 pixel stars, positions seeded by the token id,
    drawn only on background cells (this alone makes every hash unique)

Deterministic: same token id always gives the same image.
No live base URL is used; metadata image field is relative "images/N.png".

Usage:  python3 generate.py   (run from this directory or anywhere)
"""
import json
import random
import hashlib
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
MASTERS_DIR = BASE / "masters"
IMG_DIR = BASE / "images"
META_DIR = BASE / "meta"

TOTAL = 7777
GRID = 64          # pixel-art grid the master is reduced to
OUT = 512          # output size
CELL = OUT // GRID  # 8 px per pixel-art cell

MASTERS = {
    "Owl": MASTERS_DIR / "owl.webp",
    "Raven": MASTERS_DIR / "raven.webp",
    "Deer": MASTERS_DIR / "deer.webp",
    "Fox": MASTERS_DIR / "fox.webp",
}

# Animal counts: roughly equal, sum 7,777
ANIMAL_COUNTS = {"Owl": 1945, "Raven": 1944, "Deer": 1944, "Fox": 1944}

# Tier counts: exact, sum 7,777
TIER_COUNTS = {
    "Common": 3889,
    "Uncommon": 1944,
    "Rare": 1166,
    "Epic": 544,
    "Legendary": 194,
    "Mythic": 40,
}
assert sum(TIER_COUNTS.values()) == TOTAL
assert sum(ANIMAL_COUNTS.values()) == TOTAL

# Tier frame colours (None = no frame)
TIER_FRAME = {
    "Common": None,
    "Uncommon": (45, 212, 167),    # mint
    "Rare": (56, 189, 248),        # blue
    "Epic": (168, 85, 247),        # purple
    "Legendary": (245, 197, 66),   # gold
    "Mythic": (245, 197, 66),      # gold + red dot
}

# (name, hue_degrees, saturation_factor, brightness_factor)
PALETTES = [
    ("Original", 0, 1.00, 1.00),
    ("Aurora", -20, 1.10, 1.00),
    ("Frost", 25, 0.90, 1.05),
    ("Ember", 45, 1.10, 0.95),
    ("Forest", -35, 1.00, 0.95),
    ("Sunset", 55, 1.15, 1.00),
    ("Ocean", 15, 1.00, 1.05),
    ("Violet", 35, 1.05, 1.00),
    ("Lime", -10, 1.15, 1.05),
    ("Rose", 60, 1.00, 0.95),
    ("Gold", -45, 0.90, 1.08),
    ("Shadow", -25, 0.85, 0.90),
]

# (name, hex)
BACKGROUNDS = [
    ("Deep Navy", (11, 16, 38)),
    ("Midnight", (18, 18, 58)),
    ("Navy Teal", (10, 37, 48)),
    ("Purple Night", (30, 16, 51)),
    ("Forest Night", (10, 36, 26)),
    ("Slate Night", (20, 28, 43)),
    ("Indigo Night", (23, 20, 61)),
    ("Obsidian", (5, 7, 15)),
]

STAR_COLOURS = [(255, 255, 255), (168, 255, 240), (255, 215, 94), (125, 211, 252)]

# Pixel-badge patterns, 7 rows x 7 cols, drawn top-right at grid (52, 3).
# 'X' = main colour, 'o' = secondary colour, '.' = empty.
ACCESSORIES = {
    "None": None,
    "Gold Star": ([
        "...X...",
        "...X...",
        ".XXXXX.",
        "XXXXXXX",
        ".XXXXX.",
        "..X.X..",
        ".X...X.",
    ], (255, 215, 94), (255, 240, 180)),
    "Silver Star": ([
        "...X...",
        "...X...",
        ".XXXXX.",
        "XXXXXXX",
        ".XXXXX.",
        "..X.X..",
        ".X...X.",
    ], (226, 232, 240), (255, 255, 255)),
    "Moon": ([
        "..XXX..",
        ".XXXX..",
        "XXXX...",
        "XXXX...",
        "XXXX...",
        ".XXXX..",
        "..XXX..",
    ], (254, 240, 138), (255, 255, 255)),
    "Crown Gem": ([
        "X...X..",
        "XX.XX..",
        "XXXXX..",
        "XXXXX..",
        ".XXX...",
        "..X....",
        ".......",
    ], (245, 197, 66), (239, 68, 68)),
    "Leaf": ([
        "...XX..",
        "..XXXX.",
        ".XXXXX.",
        ".XXXX..",
        "..XX...",
        ".X.....",
        ".......",
    ], (74, 222, 128), (34, 197, 94)),
    "Snowflake": ([
        "...X...",
        "..XXX..",
        "XXXXXXX",
        "..XXX..",
        "XXXXXXX",
        "..XXX..",
        "...X...",
    ], (186, 230, 253), (255, 255, 255)),
    "Sparkle": ([
        "...X...",
        "...X...",
        "..XXX..",
        "XXXXXXX",
        "..XXX..",
        "...X...",
        "...X...",
    ], (255, 255, 255), (168, 255, 240)),
    "Berry": ([
        ".......",
        ".X.X...",
        "XXX....",
        ".X.X...",
        "..X....",
        ".......",
        ".......",
    ], (248, 113, 113), (239, 68, 68)),
    "Feather": ([
        "....XX.",
        "...XXXX",
        "..XXXX.",
        ".XXXX..",
        "XXX....",
        "X......",
        ".......",
    ], (45, 212, 191), (153, 246, 228)),
    "Pixel Heart": ([
        ".XX.XX.",
        "XXXXXXX",
        "XXXXXXX",
        ".XXXXX.",
        "..XXX..",
        "...X...",
        ".......",
    ], (244, 114, 182), (255, 255, 255)),
}
ACCESSORY_NAMES = list(ACCESSORIES.keys())


def load_master_grid(path: Path):
    """Master -> 64x64 RGB array + background mask (True = background)."""
    im = Image.open(path).convert("RGB").resize((GRID, GRID), Image.NEAREST)
    arr = np.asarray(im).astype(np.int16)
    bg_ref = arr[0, 0].astype(np.int16)
    dist = np.abs(arr - bg_ref).sum(axis=2)
    mask = dist < 40  # background pixels (solid dark navy, slight variation)
    return arr.astype(np.uint8), mask


def shift_hue_sat_bright(arr_rgb: np.ndarray, hue_deg: float,
                         sat_f: float, bright_f: float) -> np.ndarray:
    """Vectorised HSV shift via PIL (fast, C implementation)."""
    hsv = np.asarray(Image.fromarray(arr_rgb, "RGB").convert("HSV")).astype(np.int16)
    h = (hsv[:, :, 0] + int(round(hue_deg / 360.0 * 255))) % 256
    s = np.clip(hsv[:, :, 1] * sat_f, 0, 255)
    v = np.clip(hsv[:, :, 2] * bright_f, 0, 255)
    out = np.stack([h, s, v], axis=2).astype(np.uint8)
    return np.asarray(Image.fromarray(out, "HSV").convert("RGB"))


def draw_accessory(draw: ImageDraw.ImageDraw, name: str):
    spec = ACCESSORIES[name]
    if spec is None:
        return
    pattern, main_c, sec_c = spec
    ox, oy = 52, 3
    for gy, row in enumerate(pattern):
        for gx, ch in enumerate(row):
            if ch == ".":
                continue
            colour = main_c if ch == "X" else sec_c
            x0, y0 = (ox + gx) * CELL, (oy + gy) * CELL
            draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=colour)


def build_token(token_id: int, animal: str, tier: str,
                master_arr: np.ndarray, master_mask: np.ndarray) -> Image.Image:
    rng = random.Random(900000 + token_id)
    pal_name, hue_deg, sat_f, bright_f = PALETTES[rng.randrange(len(PALETTES))]
    bg_name, bg_rgb = BACKGROUNDS[rng.randrange(len(BACKGROUNDS))]
    acc_name = ACCESSORY_NAMES[rng.randrange(len(ACCESSORY_NAMES))]
    flip = rng.random() < 0.5

    # 1. Hue / saturation / brightness shift of the animal pixels only.
    shifted = shift_hue_sat_bright(master_arr, hue_deg, sat_f, bright_f)
    comp = np.where(master_mask[:, :, None],
                    np.array(bg_rgb, dtype=np.uint8), shifted)
    mask = master_mask.copy()
    if flip:
        comp = np.fliplr(comp)
        mask = np.fliplr(mask)

    img = Image.fromarray(comp, "RGB").resize((OUT, OUT), Image.NEAREST)
    draw = ImageDraw.Draw(img)

    # 2. Starfield: 18 pixel stars on background cells only, seeded by token id.
    bg_cells = [(x, y) for y in range(GRID) for x in range(GRID) if mask[y, x]]
    stars = rng.sample(bg_cells, min(18, len(bg_cells)))
    for (sx, sy) in stars:
        colour = STAR_COLOURS[rng.randrange(len(STAR_COLOURS))]
        x0, y0 = sx * CELL, sy * CELL
        draw.rectangle([x0, y0, x0 + CELL - 1, y0 + CELL - 1], fill=colour)

    # 3. Pixel accessory badge, top-right.
    draw_accessory(draw, acc_name)

    # 4. Tier frame.
    frame = TIER_FRAME[tier]
    if frame is not None:
        w = CELL  # 8 px
        draw.rectangle([0, 0, OUT - 1, OUT - 1], outline=frame, width=w)
        if tier == "Mythic":
            # red REC dot, top-right inside the frame
            draw.rectangle([OUT - 40, 8, OUT - 9, 39], fill=(239, 68, 68))

    return img, pal_name, bg_name, acc_name


def main():
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    META_DIR.mkdir(parents=True, exist_ok=True)

    masters = {name: load_master_grid(path) for name, path in MASTERS.items()}

    # Exact-count, shuffled assignment (fixed seeds -> reproducible).
    animals = []
    for name, count in ANIMAL_COUNTS.items():
        animals += [name] * count
    random.Random(7777).shuffle(animals)

    tiers = []
    for name, count in TIER_COUNTS.items():
        tiers += [name] * count
    random.Random(4242).shuffle(tiers)

    assert len(animals) == TOTAL and len(tiers) == TOTAL

    for n in range(1, TOTAL + 1):
        animal = animals[n - 1]
        tier = tiers[n - 1]
        arr, mask = masters[animal]
        img, pal_name, bg_name, acc_name = build_token(n, animal, tier, arr, mask)
        img.save(IMG_DIR / f"{n}.png", optimize=True)

        meta = {
            "name": f"Talvio Pixel Relic #{n}",
            "description": (
                f"Talvio Pixel Relic #{n} — a unique 16-bit pixel {animal.lower()} "
                f"from the Talvio Pixel Relics collection on BNB Chain."
            ),
            "image": f"images/{n}.png",
            "attributes": [
                {"trait_type": "Animal", "value": animal},
                {"trait_type": "Tier", "value": tier},
                {"trait_type": "Background", "value": bg_name},
                {"trait_type": "Palette", "value": pal_name},
                {"trait_type": "Accessory", "value": acc_name},
            ],
        }
        (META_DIR / f"{n}.json").write_text(json.dumps(meta, indent=2) + "\n")

        if n % 1000 == 0:
            print(f"  ... {n}/{TOTAL} done", flush=True)

    print(f"DONE: {TOTAL} images + {TOTAL} metadata files")


if __name__ == "__main__":
    main()
