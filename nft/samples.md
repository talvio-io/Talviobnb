# Talvio Pixel Relics — Full Set (7,777)

Status: **LOCAL ONLY** — not uploaded, not pushed to GitHub, no contract
deployed, no live base URL. Generated 2026-11-09.
Generator: `generate.py` (deterministic — same token id always gives the
same image). Masters: `masters/owl.webp`, `raven.webp`, `deer.webp`,
`fox.webp` (16-bit pixel-art sprites, AI-generated, dark navy background,
no text/watermark).

## Layout

- `images/1.png` … `images/7777.png` — 512×512 PNG, 69 MB total
- `meta/1.json` … `meta/7777.json` — 31 MB total
- Metadata name: `Talvio Pixel Relic #N`
- Metadata `image` field: relative `images/N.png` only (hosting/baseURI TBD)

## How each token is different

Every token is derived from one of the 4 masters and varies in all of
these at once — never just the same 4 images repeated:

- **Animal** (master): Owl / Raven / Deer / Fox
- **Palette** (12): hue/saturation/brightness shift of the master —
  Original, Aurora, Frost, Ember, Forest, Sunset, Ocean, Violet, Lime,
  Rose, Gold, Shadow
- **Background** (8 dark night shades): Deep Navy, Midnight, Navy Teal,
  Purple Night, Forest Night, Slate Night, Indigo Night, Obsidian
  (background pixels of the master are replaced, not just tinted)
- **Accessory** (11 pixel badges, top-right): None, Gold Star,
  Silver Star, Moon, Crown Gem, Leaf, Snowflake, Sparkle, Berry,
  Feather, Pixel Heart
- **Flip**: horizontal flip, ~50% of tokens
- **Starfield**: 18 pixel stars, positions seeded by the token id,
  drawn only on background cells
- **Tier frame**: Common none, Uncommon mint, Rare blue, Epic purple,
  Legendary gold, Mythic gold + red dot (top-right)

## Exact counts (verified)

- Animals: Owl 1,945 / Raven 1,944 / Deer 1,944 / Fox 1,944
- Tiers: Common 3,889 / Uncommon 1,944 / Rare 1,166 / Epic 544 /
  Legendary 194 / Mythic 40 — sum 7,777

## Verification (full pass, 2026-11-09)

- Images: 7,777, ids exactly 1–7,777, all 512×512
- Metadata: 7,777, ids exactly 1–7,777, all JSONs parse, names and
  relative `images/N.png` fields correct
- Duplicate sha256 image hashes: **0** (7,777 unique hashes)
- Total size: 100 MB (images 69 MB + meta 31 MB)

## Sample tokens (visually checked)

- **#1** — Owl, Rare (blue frame), Palette Gold, Background Forest Night,
  Accessory Pixel Heart
- **#100** — Fox, Common (no frame), Palette Gold, Background Deep Navy,
  Accessory Moon
- **#1000** — Owl, Common, Palette Shadow, Background Slate Night,
  Accessory Leaf
- **#1090** — Deer, Mythic (gold frame + red dot), Palette Aurora,
  Background Deep Navy, Accessory Leaf
- **#7777** — Fox, Epic (purple frame), Palette Shadow, Background
  Deep Navy, Accessory Pixel Heart

## Next steps (not done — need user decision)

- Hosting / baseURI decision (where `images/N.png` will live)
- NFT contract + deploy page
- Upload (20,000+ files total is heavy for GitHub — needs explicit
  approval and a chunked plan, like the earlier projects)
