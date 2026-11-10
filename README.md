# Talvio — Paket Lengkap (BNB Chain)

Paket lengkap Talvio: website, NFT 7.777, dan kontrak BNB. Semua file sudah di-upload ke repo GitHub `talvio-io/Talviobnb` — **kontrak belum di-deploy, mint belum live**.

## Fakta kunci

- **Network:** BNB Chain (chain ID 56), gas BNB
- **NFT:** Talvio Pixel Relic, 7.777 token, pixel art 16-bit (Owl, Raven, Deer, Fox)
- **Mint:** dua jalur yang **jalan bersamaan sejak mint dibuka** — `mintFree()` untuk 777 klaim gratis pertama bagi pemegang Binance Agent ID (1 per wallet; kuota gratis dihitung dari klaim gratis saja, tidak termakan mint berbayar) dan `mintPaid(qty)` **0.0015 BNB** per Relic untuk semua wallet sejak awal, **tanpa menunggu fase gratis habis**. Maks **5 per wallet** (gabungan).
- **Reward $TALV langsung di transaksi mint:** mint gratis **48.888.800 TALV**, mint berbayar **488.888.000 TALV** per Relic — dikirim ke wallet minter di transaksi yang sama, dari saldo $TALV milik kontrak NFT (diisi pemilik lewat langkah Link + Fund di halaman deploy, bisa bertahap; total kebutuhan sold-out 3.460.202.597.600 TALV). Kalau saldo kontrak kurang saat mint, mint tetap berhasil dan sisanya tercatat di `talvOwed`, bisa ditarik pemilik wallet lewat `claimOwed()` setelah kontrak di-top-up.
- **Token $TALV:** supply tetap 7,77 triliun (7.770.000.000.000), 18 desimal, seluruh supply di-mint ke wallet pemilik saat deploy — kontraknya **termasuk di paket ini** (`contract/TalvioToken.sol`), di-deploy dari halaman deploy yang sama (langkah 04). Pembagian sesuai tokenomics: 82% LP · 10% top inviters · 8% treasury (dieksekusi pemilik dari wallet-nya).
- **Kontrak NFT: BELUM DI-DEPLOY.** Mint masih tertutup (`mintOpen` = false) sampai kontrak di-deploy dan dibuka.
- **Metadata SUDAH DI-HOST** di repo ini (`nft/meta/` + `nft/images/`), dan field `image` di semua metadata sudah berupa URL absolut. `baseURI` untuk `setBaseURI`: `https://raw.githubusercontent.com/talvio-io/Talviobnb/main/nft/meta/` (sudah terisi otomatis di halaman deploy, langkah 3).

## Isi paket

| File / folder | Isi |
|---|---|
| `index.html` | Website Talvio (Inggris, BNB Chain) — buka file ini di browser untuk melihat sitenya |
| `deploy-bnb.html` | Halaman deploy kontrak NFT (OKX-first, BNB Chain 56) |
| `withdraw-bnb.html` | Halaman withdraw khusus owner kontrak |
| `contract/TalvioBNB.sol` | Source kontrak NFT ERC-721 "Talvio Pixel Relic" (TALV) |
| `contract/TalvioBNB.json` | Hasil compile (ABI + bytecode) |
| `contract/compile-bnb.js` | Script compile kontrak |
| `contract/TalvioToken.sol` | Source kontrak token ERC-20 "$TALV" (Talvio, supply tetap 7,77 triliun) |
| `contract/TalvioToken.json` | Hasil compile token (ABI + bytecode) |
| `contract/compile-token.js` | Script compile token |
| `nft/images/` | 7.777 gambar NFT (1.png – 7777.png, 512×512) |
| `nft/meta/` | 7.777 metadata JSON (1.json – 7777.json) |
| `nft/masters/` | 4 master pixel art (Owl, Raven, Deer, Fox) |
| `nft/samples.md` | Ringkasan sistem trait NFT |
| `nft/generate.py` | Generator yang membuat 7.777 NFT dari 4 master |

## Cara pakai

1. **Lihat website:** buka `index.html` di browser.
2. **Deploy kontrak:** buka `deploy-bnb.html`, hubungkan wallet (OKX dideteksi dulu), ikuti langkah Connect → Deploy NFT → Set baseURI → Deploy Token → Link + Fund $TALV → Open Mint → State/Summary.
3. **Sebelum mint dibuka:** jalankan langkah Set baseURI di halaman deploy — URL metadata repo sudah terisi otomatis (`https://raw.githubusercontent.com/talvio-io/Talviobnb/main/nft/meta/`).
4. **Withdraw fee:** buka `withdraw-bnb.html` dengan wallet owner kontrak.

## Catatan

- Paket Elysium (Kinetiq 99901) sudah **dihapus** atas permintaan pemilik — Talvio pakai BNB saja.
- File-file di repo ini adalah salinan kerja yang dipakai untuk deploy.
