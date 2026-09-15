# FinHopper

Game iOS berbasis SwiftUI dan SpriteKit. Bantu ikan melintasi taman dan jalan, menghindari kendaraan, dan mencapai pond sebelum napas habis.

## Gameplay

- Tap untuk maju; swipe untuk bergerak ke kiri, kanan, atas, atau bawah.
- D-pad tersedia melalui Settings dan untuk VoiceOver.
- Pohon dan batang kayu menghalangi jalan.
- Ikan terlindungi dari kendaraan selama langkah valid berlangsung. Saat diam atau mendarat, tabrakan berlaku kembali.
- Napas maksimal **10 detik**. Pond kecil menambah **5 detik**, pond besar menambah **10 detik**, tanpa melebihi batas.
- Setiap pond hanya dapat diserap sekali, lalu berubah menjadi pond surut.
- Pond besar lebih jarang: kandidat setiap empat lokasi pond, dengan jalur langsung dihalangi pohon. Jika akses samping tidak lolos validasi rute, lokasi tetap memakai pond kecil.
- Pond kecil dan besar tidak muncul pada baris yang sama.
- Kamera mulai mengikuti ikan pada baris keempat.

## FTUE

Tutorial interaktif hadir saat membuka app dan menyambung langsung ke gameplay dalam scene yang sama:

1. Movement melalui koridor pohon.
2. Menghindari rintangan dan menyeberangi jalan.
3. Mengenal napas dan mencapai pond pertama.

Retry setelah run biasa tidak mengulang FTUE. Pause FTUE memakai tampilan pause gameplay, tetapi tombol Retry disembunyikan. Ikon tutorial baru muncul setelah pemain memulai dari waiting.

## Menjalankan project

- macOS dengan Xcode yang mendukung Swift 6 dan default actor isolation `MainActor`.
- Minimum deployment target: **iOS 16.0**.
- Terakhir dibangun menggunakan **Xcode 26.6**.
- Tidak menggunakan dependensi paket eksternal.

1. Buka `PondHopper.xcodeproj`.
2. Pilih scheme **FinHopper** dan simulator iPhone.
3. Jalankan dengan **Run**.
4. Untuk iPhone fisik, sesuaikan Signing Team dan bundle identifier dengan akun pengembang sendiri.

Nama folder/project tetap `PondHopper`; nama produk dan scheme adalah `FinHopper`.

## Build dan pengujian

Build simulator:

```sh
xcodebuild build -project PondHopper.xcodeproj -scheme FinHopper -destination 'generic/platform=iOS Simulator'
```

Lihat simulator yang tersedia:

```sh
xcrun simctl list devices available
```

Ganti `SIMULATOR_UDID` dengan ID simulator:

```sh
xcodebuild test -project PondHopper.xcodeproj -scheme FinHopper -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' -parallel-testing-enabled NO
```

Tes mencakup movement, collision, napas, pond, generator peta, session, pause, FTUE, dan audio. Tes stres membatasi jumlah node; tes tersebut bukan pengukuran FPS pada perangkat fisik. Seluruh suite belum dinyatakan lolos pada revisi ini; beberapa tes presentasi/UI historis masih perlu diselaraskan dengan tampilan terbaru.

## Opsi debug

Tambahkan di **Scheme → Run → Arguments Passed On Launch**:

- `--finhopper-seed=42`: peta deterministik.
- `--finhopper-breath=60`: override kapasitas napas untuk pengujian.
- `--finhopper-show-dpad`: tampilkan D-pad.
- `--finhopper-reset-progress`: hapus progres lokal untuk pengujian.

Flag lama `--finhopper-skip-tutorial` tidak melewati FTUE.

## Struktur

- `PondHopper/App/`: session, pengaturan, persistence, dan audio/haptics.
- `PondHopper/Game/GameScene.swift`: scene SpriteKit, gerakan, collision, kamera, dan streaming peta.
- `PondHopper/Game/Core/`: aturan dasar gameplay.
- `PondHopper/Game/World/`: generator, validasi rute, pond, kendaraan, dan dekorasi.
- `PondHopper/UI/`: HUD, waiting, loading, FTUE, pause, dan game over.
- `PondHopper/Assets.xcassets/`: app icon dan ikon gesture.
- `PondHopper/Resources/`: sprite atlas, suara, dan lisensi aset.
- `PondHopperTests/`: unit dan integration tests.
- `PondHopperUITests/`: UI smoke tests.

## Performa

Run diawali peta kecil berisi hingga 48 baris. Peta lanjutan dibuat pada background task dan diterapkan tanpa mengganti posisi pemain. Rendering memakai jendela baris terbatas, kendaraan diperbarui di sekitar kamera, dan tekstur sprite dipakai ulang antar-run.

Profiling FPS dan frame time pada iPhone fisik masih diperlukan, khususnya untuk sesi panjang dan restart berulang.

## Aset dan lisensi

Lihat [ASSET_CREDITS.md](ASSET_CREDITS.md) untuk sumber suara, sprite, dan ikon. Lisensi Tabler dan Phosphor tersedia di `PondHopper/Resources/`.

Tidak ada lisensi umum yang diberikan untuk seluruh project. Lisensi aset pihak ketiga tetap mengikuti sumber masing-masing.
