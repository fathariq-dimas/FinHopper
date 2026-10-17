# Fin Hopper

Fin Hopper is an iOS game focused on creating *time tension*, where players control a fish crossing roads between puddles while racing against a limited survival timer on land. Hop around obstacles, avoid passing vehicles, and reach the next pond before running out of breath.

## 🧠 Background

Fin Hopper explores how a simple survival rule can shape every decision in a game: a fish cannot stay on land for long. Waiting for a safe opening in traffic costs precious time, while rushing ahead can lead to a collision.

Ponds offer a chance to recover, creating a rhythm of urgency and relief. Players must keep balancing movement, timing, and route choices to survive and travel farther.

## ✨ Features / Key Features

### 🐟 Tap and Swipe Movement

Tap to hop forward or swipe to move in four directions. Navigate around trees and logs while finding a path to the next pond. An optional D-pad is available through Settings and for VoiceOver.

### ⏳ Limited Survival Timer

The fish has a maximum of **10 seconds of breath**. Time runs down on land, turning each crossing into a race to reach water.

### 💧 Pond Recovery

Small ponds restore **5 seconds** of breath, while large ponds restore **10 seconds**, up to the maximum capacity. Each pond can only be used once before it drains, encouraging players to keep moving.

### 🚗 Traffic and Increasing Difficulty

Cross moving traffic and progress through a generated world. As the score increases, vehicles become faster, traffic becomes more frequent, and ponds become farther apart.

### 🎓 Interactive Tutorial

Learn movement, obstacle avoidance, road crossing, and breath recovery through an interactive tutorial that transitions directly into gameplay in the same scene.

### 🔊 Gameplay Feedback

Sound effects, haptics, and visual breath warnings reinforce movement, recovery, collisions, and critical moments.

## 🎯 Game Design Focus

### Time Tension

The core experience comes from two competing pressures: waiting for a safe route and reaching the next pond before the survival timer expires. The timer gives even a short crossing a sense of urgency.

### Risk and Reward

Large ponds provide more recovery but are less common and require a detour around a blocked direct approach. Players must weigh the extra recovery against the time and movement needed to reach them.

### Readable Visual Feedback

Fish animations, pond states, and breath indicators help communicate the current situation. A drained pond makes its one-time recovery rule visible, while critical breath feedback signals when the player needs to act quickly.

## 🎮 Gameplay

1. Tap or swipe to move the fish through the garden and across roads.
2. Avoid trees, logs, and vehicles while watching the breath meter.
3. Reach a fresh pond to recover breath before the timer runs out.
4. Keep advancing to increase your score and beat your best distance.

The fish is protected from vehicles during a valid hop; collisions apply again when it lands or stays still. The score follows the farthest row reached, so revisiting earlier rows does not add points.

## 🛠 Tech Stack

- **Swift 6** — game rules and application logic.
- **SwiftUI** — menus, settings, overlays, and the game HUD.
- **SpriteKit** — game scene, sprites, animations, and world rendering.
- **AVFoundation** — game audio.
- **UIKit** — haptic feedback.
- **UserDefaults** — local progress and settings.
- **Swift Testing / XCTest** — unit, integration, and UI tests.

Minimum deployment target: **iOS 16.0**. No external package dependencies.

## 📷 Screenshots

<!-- Add gameplay, tutorial, and game-over screenshots here when available. -->

## 🎨 Development & Contribution

Designed the game systems, visual assets, and developed **Fin Hopper**, with a focus on creating *time tension* through the limited survival timer, road crossings, and pond recovery loop.

The work covers gameplay rules, visual presentation, and iOS implementation. Third-party asset sources and licenses are documented in [ASSET_CREDITS.md](ASSET_CREDITS.md).

## 🧑‍💻 Developer Guide

<details>
<summary>Project setup, testing, debug options, and implementation notes</summary>

### Catatan gameplay dan tutorial

- Pond besar menjadi kandidat setiap empat lokasi pond. Jika akses samping tidak lolos validasi rute, lokasi tetap memakai pond kecil.
- Pond kecil dan besar tidak muncul pada baris yang sama.
- Kamera mulai mengikuti ikan pada baris keempat.
- Tutorial dimulai dengan movement melalui koridor pohon, dilanjutkan rintangan dan jalan, lalu napas dan pond pertama.
- Retry setelah run biasa tidak mengulang FTUE. Pause FTUE memakai tampilan pause gameplay, tetapi tombol Retry disembunyikan. Ikon tutorial baru muncul setelah pemain memulai dari waiting.

### Menjalankan project

- macOS dengan Xcode yang mendukung Swift 6 dan default actor isolation `MainActor`.
- Minimum deployment target: **iOS 16.0**.
- Terakhir dibangun menggunakan **Xcode 26.6**.
- Tidak menggunakan dependensi paket eksternal.

1. Buka `PondHopper.xcodeproj`.
2. Pilih scheme **FinHopper** dan simulator iPhone.
3. Jalankan dengan **Run**.
4. Untuk iPhone fisik, sesuaikan Signing Team dan bundle identifier dengan akun pengembang sendiri.

Nama folder/project tetap `PondHopper`; nama produk dan scheme adalah `FinHopper`.

### Build dan pengujian

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

### Opsi debug

Tambahkan di **Scheme → Run → Arguments Passed On Launch**:

- `--finhopper-seed=42`: peta deterministik.
- `--finhopper-breath=60`: override kapasitas napas untuk pengujian.
- `--finhopper-show-dpad`: tampilkan D-pad.
- `--finhopper-reset-progress`: hapus progres lokal untuk pengujian.

Flag lama `--finhopper-skip-tutorial` tidak melewati FTUE.

### Struktur

- `PondHopper/App/`: session, pengaturan, persistence, dan audio/haptics.
- `PondHopper/Game/GameScene.swift`: scene SpriteKit, gerakan, collision, kamera, dan streaming peta.
- `PondHopper/Game/Core/`: aturan dasar gameplay.
- `PondHopper/Game/World/`: generator, validasi rute, pond, kendaraan, dan dekorasi.
- `PondHopper/UI/`: HUD, waiting, loading, FTUE, pause, dan game over.
- `PondHopper/Assets.xcassets/`: app icon dan ikon gesture.
- `PondHopper/Resources/`: sprite atlas, suara, dan lisensi aset.
- `PondHopperTests/`: unit dan integration tests.
- `PondHopperUITests/`: UI smoke tests.

### Performa

Run diawali peta kecil berisi hingga 48 baris. Peta lanjutan dibuat pada background task dan diterapkan tanpa mengganti posisi pemain. Rendering memakai jendela baris terbatas, kendaraan diperbarui di sekitar kamera, dan tekstur sprite dipakai ulang antar-run.

Profiling FPS dan frame time pada iPhone fisik masih diperlukan, khususnya untuk sesi panjang dan restart berulang.

</details>

## 📄 Asset Credits & Licensing

See [ASSET_CREDITS.md](ASSET_CREDITS.md) for sound, sprite, and icon sources. Tabler and Phosphor licenses are included in `PondHopper/Resources/`.

No overall project license is granted. Third-party assets remain subject to their respective licenses.
