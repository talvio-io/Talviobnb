# Talvio — Paket Lengkap (BNB Chain)

Paket lengkap Talvio: website, NFT 7.777, dan kontrak BNB. Semua file lokal — **belum di-upload, belum live, belum di-deploy**.

## Fakta kunci

- **Network:** BNB Chain (chain ID 56), gas BNB
- **NFT:** Talvio Pixel Relic, 7.777 token, pixel art 16-bit (Owl, Raven, Deer, Fox)
- **Mint:** 777 pertama gratis untuk pemegang Binance Agent ID (1 per Agent ID), sisanya **0.0015 BNB** per Relic, maks **5 per wallet**
- **Token $TALV:** supply 7,77 triliun, 82% ke LP — **kontrak token $TALV dibuat sendiri oleh pemilik proyek, bukan bagian dari paket ini**
- **Kontrak NFT: BELUM DI-DEPLOY.** Mint masih tertutup (`mintOpen` = false) sampai kontrak di-deploy dan dibuka.
- **Metadata BELUM DI-HOST.** `baseURI` di halaman deploy masih kosong. Hosting 7.777 gambar + metadata harus disiapkan dulu sebelum `setBaseURI`.

## Isi paket

| File / folder | Isi |
|---|---|
| `index.html` | Website Talvio (Inggris, BNB Chain) — buka file ini di browser untuk melihat sitenya |
| `deploy-bnb.html` | Halaman deploy kontrak NFT (OKX-first, BNB Chain 56) |
| `withdraw-bnb.html` | Halaman withdraw khusus owner kontrak |
| `contract/TalvioBNB.sol` | Source kontrak NFT ERC-721 "Talvio Pixel Relic" (TALV) |
| `contract/TalvioBNB.json` | Hasil compile (ABI + bytecode) |
| `contract/compile-bnb.js` | Script compile kontrak |
| `nft/images/` | 7.777 gambar NFT (1.png – 7777.png, 512×512) |
| `nft/meta/` | 7.777 metadata JSON (1.json – 7777.json) |
| `nft/masters/` | 4 master pixel art (Owl, Raven, Deer, Fox) |
| `nft/samples.md` | Ringkasan sistem trait NFT |
| `nft/generate.py` | Generator yang membuat 7.777 NFT dari 4 master |

## Cara pakai

1. **Lihat website:** buka `index.html` di browser.
2. **Deploy kontrak:** buka `deploy-bnb.html`, hubungkan wallet (OKX dideteksi dulu), ikuti langkah Connect → Deploy → Check → Set baseURI → Open Mint.
3. **Sebelum mint dibuka:** host dulu folder `nft/images/` + `nft/meta/` di tempat yang bisa diakses publik, lalu isi `baseURI` di halaman deploy dengan URL hosting tersebut (contoh: `https://domain-kamu/nft/meta/`).
4. **Withdraw fee:** buka `withdraw-bnb.html` dengan wallet owner kontrak.

## Catatan

- Paket Elysium (Kinetiq 99901) sudah **dihapus** atas permintaan pemilik — Talvio pakai BNB saja.
- File-file di paket ini adalah salinan dari sumber lokal; file asli NFT tetap ada di `~/workspace/talvio/full/` dan kontrak BNB di `~/workspace/talvio-bnb/`.
