# i.-GB Presentation Guide
## Phase 1 & 2 — Prototype, Storyboard & What to Present

---

# BAHAGIAN 1: PROTOTYPE

> **Cara buat:** Copy semua ni ke Google Slides.
> Setiap `[ SCREENSHOT HERE ]` = masukkan screenshot kau.
> 1 screen = 1 slide (atau 2 slides kalau nak explain lebih).

---

## SLIDE 1 — Cover / Title

```
Title:   i.-GB
         Interactive Game Board with AR (Melaka Theme)

Subtitle: Phase 1 & 2 Prototype
          AR 3D Physical Board Application

Logo:    [ SCREENSHOT — logo_igb.png ]
```

---

## SLIDE 2 — Project Overview

```
App Name:     i.-GB (Interactive Game Board)
Platform:     Android (Flutter)
Technology:   ARCore, QR Marker, Flutter, SQLite

Objective:
  Pelajar / pelancong scan papan permainan fizikal
  menggunakan telefon → soalan AR muncul dalam app
  → jawab soalan → score dikira → naik papan

Target User:  Pelajar sekolah, pelancong Melaka
```

---

## SLIDE 3 — Tech Stack

```
┌─────────────────────────────────────────┐
│  FRONTEND        │  Flutter (Dart)       │
│  AR Engine       │  ARCore (Android)     │
│  Scanner         │  ar_flutter_plugin    │
│  Backend (plan)  │  Flask API            │
│  Database (plan) │  SQLite               │
│  Target device   │  Android API 24+      │
└─────────────────────────────────────────┘

[ SCREENSHOT — pubspec.yaml atau tech stack diagram ]
```

---

## SLIDE 4 — App Flow (Overview)

```
[Splash] → [Loading] → [Home / Menu]
                            ↓
                      [Tutorial] ← (first time user)
                            ↓
                       [Scanner]  ← scan papan fizikal
                            ↓
                    [Soalan muncul] ← AR overlay
                            ↓
                      [Jawab MCQ]
                            ↓
                    [Game Board] ← snake & ladder
                            ↓
                    [Score / Tamat]
```

---

## SLIDE 5 — Screen 1: Splash Screen

```
Screen Name:   Splash Screen
Route:         / (app entry point)
Purpose:       Intro app, tunjuk logo i.-GB

[ SCREENSHOT — splash screen dengan logo ]

Notes:
- Logo i.-GB dengan animasi bounce
- Star burst effect bila tap logo
- Auto navigate ke Home selepas beberapa saat
```

---

## SLIDE 6 — Screen 2: Loading Screen

```
Screen Name:   Loading Screen
Route:         /loading
Purpose:       Transition screen, loading animation

[ SCREENSHOT — loading screen ]

Notes:
- Animasi coin-flip pada logo
- Bintang terbang keluar dari logo
- Sound effect (blinkingstar.mp3)
- Tunjuk progress loading
```

---

## SLIDE 7 — Screen 3: Home Screen

```
Screen Name:   Home Screen / Main Menu
Route:         /home
Purpose:       Pilih topik, masuk nama pemain

[ SCREENSHOT — home screen dengan 5 topic cards ]

Features:
- Input nama pemain
- 5 topic cards:
    📚 Sejarah Melaka
    📚 Budaya
    📚 Pelancongan
    📚 Matematik
    📚 Seni Bina
- Button: Tutorial | Nota | About
```

---

## SLIDE 8 — Home Screen: 5 Topic Cards (close-up)

```
[ SCREENSHOT — close-up 5 topic cards ]
[ SCREENSHOT — topic_sejarah_melaka.png card ]
[ SCREENSHOT — topic_budaya.png card ]

Topics available:
  1. Sejarah Melaka    — sejarah tempatan
  2. Budaya            — warisan budaya
  3. Pelancongan       — tempat menarik
  4. Matematik         — soalan kiraan
  5. Seni Bina         — bangunan bersejarah
```

---

## SLIDE 9 — Screen 4: Tutorial Screen

```
Screen Name:   Tutorial Screen
Route:         /tutorial
Purpose:       Panduan guna app untuk pengguna baru

[ SCREENSHOT — tutorial screen step 1 ]

4 steps dalam tutorial:
  Step 1:  Imbas Papan Permainan
  Step 2:  Kad Tempat Muncul
  Step 3:  Jawab Soalan
  Step 4:  Kumpul Ganjaran

[ SCREENSHOT — tutorial step 4 / completion ]
```

---

## SLIDE 10 — Screen 5: Scanner Screen (AR Camera)

```
Screen Name:   Scanner / AR Screen
Route:         /scanner
Purpose:       Scan marker pada papan fizikal → trigger soalan

[ SCREENSHOT — scanner screen dengan camera viewfinder ]

Features:
- Kamera aktif dengan viewfinder overlay (bracket corners)
- Detect QR / AR marker pada papan
- Score badge di atas
- Flip place card muncul bila marker dikesan

[ SCREENSHOT — scanner screen dengan place card muncul ]
```

---

## SLIDE 11 — Scanner: AR Question Overlay

```
[ SCREENSHOT — soalan overlay muncul selepas scan ]

Bila marker dikesan:
- Nama landmark muncul (contoh: "A Famosa")
- Topik ditunjukkan (contoh: "Sejarah Melaka")
- Soalan MCQ dipaparkan (4 pilihan: A, B, C, D)
- Button: Pilih jawapan / Imbas Seterusnya

[ SCREENSHOT — MCQ options A B C D ]
```

---

## SLIDE 12 — Screen 6: Question Screen

```
Screen Name:   Question Screen
Route:         (modal dalam scanner)
Purpose:       Tunjuk soalan + pilihan jawapan + skor

[ SCREENSHOT — question screen ]

Features:
- Soalan lengkap dengan emoji topik
- 4 pilihan jawapan (MCQ)
- Highlight jawapan betul/salah
- Score tracker
- Next question trigger
```

---

## SLIDE 13 — Screen 7: Game Board Screen

```
Screen Name:   Game Board (Snake & Ladder)
Route:         /game
Purpose:       Board game sebagai reward sistem

[ SCREENSHOT — game board snake & ladder ]

Features:
- Papan snake & ladder zigzag klasik
- Nama pemain ditunjukkan: "i.-GB — [Nama]"
- Player token bergerak mengikut skor
- Popup bila game tamat: 🏆 Permainan Tamat!
- Button: Kembali ke Menu | Main Semula

[ SCREENSHOT — game over popup ]
```

---

## SLIDE 14 — Screen 8: Nota Screen

```
Screen Name:   Nota Screen
Route:         /nota
Purpose:       Rujukan / nota untuk pelajar

[ SCREENSHOT — nota screen ]
```

---

## SLIDE 15 — Screen 9: About Screen

```
Screen Name:   About Screen
Route:         /about
Purpose:       Info projek dan ahli kumpulan

[ SCREENSHOT — about screen dengan nama team members ]

Tunjukkan:
- Nama app: i.-GB
- Deskripsi projek
- Senarai ahli kumpulan
```

---

## SLIDE 16 — Physical Board (Papan Fizikal)

```
[ SCREENSHOT / FOTO — papan fizikal projek kau ]
[ SCREENSHOT / FOTO — QR markers pada papan ]

Ini adalah "physical" dalam AR 3D Physical Board:
- Papan permainan berbentuk fizikal (cetak/buat)
- Ada QR code / marker di setiap petak
- User scan marker → soalan muncul dalam app
```

---
---

# BAHAGIAN 2: STORYBOARD

> **Storyboard** = cerita macam mana user guna app dari mula sampai habis.
> Buat dalam Google Slides: setiap kotak = 1 slide, letak screenshot + anak panah.

---

## STORYBOARD — User Journey (8 Steps)

---

### Step 1 — User Download & Buka App

```
┌─────────────────────────────────┐
│                                 │
│   [ SCREENSHOT — splash screen ]│
│                                 │
│  Ahmad (pelajar darjah 5)       │
│  buka app i.-GB untuk           │
│  pertama kali.                  │
│                                 │
│  ➡ Logo muncul dengan animasi  │
└─────────────────────────────────┘

ACTION: Buka app → Splash screen muncul
```

---

### Step 2 — Loading Screen

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — loading screen ] │
│                                 │
│  App loading dengan animasi     │
│  coin-flip dan bintang.         │
│                                 │
│  ➡ Auto navigate ke Home       │
└─────────────────────────────────┘

ACTION: Loading aset selesai → masuk Home
```

---

### Step 3 — Home Screen & Masuk Nama

```
┌─────────────────────────────────┐
│                                 │
│  [ SCREENSHOT — home screen ]   │
│                                 │
│  Ahmad masukkan namanya:        │
│  "Ahmad"                        │
│                                 │
│  Dia pilih topik:               │
│  📚 Sejarah Melaka              │
│                                 │
│  ➡ Tap "Mula" / topic card     │
└─────────────────────────────────┘

ACTION: Input nama → pilih topik → proceed
```

---

### Step 4 — Tutorial (First Time)

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — tutorial step 1 ]│
│                                 │
│  Pertama kali main, Ahmad       │
│  tengok tutorial 4 langkah.     │
│                                 │
│  1. Imbas Papan                 │
│  2. Kad Muncul                  │
│  3. Jawab Soalan                │
│  4. Kumpul Ganjaran             │
│                                 │
│  ➡ Selesai tutorial → Scanner  │
└─────────────────────────────────┘

ACTION: Baca tutorial → faham cara main
```

---

### Step 5 — Scan Papan Fizikal

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — scanner screen ] │
│                                 │
│  Ahmad halakan kamera ke        │
│  papan permainan fizikal.       │
│                                 │
│  [ FOTO — papan fizikal ]       │
│                                 │
│  Scanner mengesan QR marker     │
│  pada petak "A Famosa".         │
│                                 │
│  ➡ Kad tempat flip muncul      │
└─────────────────────────────────┘

ACTION: Kamera aktif → scan marker → detected
```

---

### Step 6 — Soalan AR Muncul

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — question overlay]│
│                                 │
│  Soalan muncul sebagai          │
│  AR overlay di skrin:           │
│                                 │
│  "Bilakah Kota A Famosa         │
│   dibina?"                      │
│                                 │
│  A. 1511  B. 1400               │
│  C. 1600  D. 1350               │
│                                 │
│  ➡ Ahmad pilih jawapan         │
└─────────────────────────────────┘

ACTION: Marker detected → soalan AR overlay muncul
```

---

### Step 7 — Jawab Soalan & Score

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — answer selected ]│
│                                 │
│  Ahmad pilih: A. 1511 ✅        │
│                                 │
│  Jawapan betul → highlight hijau│
│  Score: +10 mata                │
│                                 │
│  ➡ Imbas marker seterusnya     │
└─────────────────────────────────┘

ACTION: Pilih jawapan → betul/salah → score update
```

---

### Step 8 — Game Board & Tamat

```
┌─────────────────────────────────┐
│                                 │
│ [ SCREENSHOT — game board ]     │
│                                 │
│  Score terkumpul → Ahmad        │
│  gerak token di papan           │
│  snake & ladder.                │
│                                 │
│ [ SCREENSHOT — game over popup ]│
│                                 │
│  🏆 Permainan Tamat!            │
│  Ahmad dapat score tinggi!      │
│                                 │
│  ➡ Main semula / Kembali menu  │
└─────────────────────────────────┘

ACTION: Score → move token → game board → tamat
```

---
---

# BAHAGIAN 3: APA NAK PRESENT

> **Masa yang dicadangkan: 10–15 minit**
> Guna APK (dari GitHub Actions) untuk demo sebenar!

---

## STRUKTUR PRESENTATION

### 🔵 Bahagian 1 — Intro (2 minit)
```
1. Perkenalkan projek: "i.-GB — Interactive Game Board with AR"
2. Problem statement:
   "Cara belajar sejarah & budaya Melaka selama ini
    membosankan — buku teks, hafalan semata-mata."
3. Solution:
   "Kami buat app AR yang jadikan belajar macam main game."
```

### 🟡 Bahagian 2 — Phase 1 (3 minit)
```
1. Tunjuk Phase 1 screenshots (awal development)
   - UI awal / wireframe pertama
   - Setup ARCore basic
   - Struktur folder & tech stack

   [ SCREENSHOT PHASE 1 LAMA KAU ]

2. Apa yang berjaya dalam Phase 1:
   - App boleh jalan
   - Camera boleh aktif
   - Basic AR setup
```

### 🟢 Bahagian 3 — Phase 2 (5 minit)
```
1. Tunjuk semua screens (dari prototype slide tadi)
2. Highlight improvements dari Phase 1 ke Phase 2:
   ✅ Splash screen + loading animation
   ✅ 5 topic cards (Sejarah, Budaya, dll)
   ✅ AR Scanner dengan viewfinder
   ✅ MCQ overlay soalan
   ✅ Snake & Ladder game board
   ✅ Tutorial screen
   ✅ Nota & About screen

3. DEMO APP LIVE atau video recording:
   - Buka app
   - Masuk nama
   - Scan marker
   - Jawab soalan
   - Tunjuk score
```

### 🔴 Bahagian 4 — Cabaran & Penyelesaian (2 minit)
```
Jujur je — panel suka kalau ada honest reflection:

Cabaran:
  - ARCore compatibility (min API 24)
  - ar_flutter_plugin ada bug → kena patch sendiri
  - permission_handler outdated → kena patch

Penyelesaian:
  - Buat local patch untuk kedua-dua package
  - Test pada multiple devices
```

### ⚪ Bahagian 5 — What's Next / Phase 3 (1 minit)
```
Future plans (kalau ada):
  - Backend Flask API untuk leaderboard online
  - SQLite untuk simpan score history
  - More topics & questions
  - iOS support
```

---

## TIPS UNTUK DEMO

```
✅ Install APK dari GitHub Actions SEBELUM present
   (download dari Actions tab → app-release-apk)

✅ Test demo sekali dua sebelum present

✅ Kalau takut demo live fail → record video dulu
   (screen recorder Android → tekan present video)

✅ Bawa papan fizikal / print QR marker untuk scan live

✅ Backup: ada screenshots semua screen dalam slides
```

---

## SLIDE ORDER UNTUK GOOGLE SLIDES

```
Slide  1  — Cover (i.-GB, nama group, tarikh)
Slide  2  — Problem Statement
Slide  3  — Solution / Objective
Slide  4  — Tech Stack
Slide  5  — App Flow Diagram
Slide  6  — Phase 1: Screenshots & apa dah buat
Slide  7  — Phase 2: Screens overview (grid semua screens)
Slide  8  — Splash Screen
Slide  9  — Loading Screen
Slide 10  — Home Screen + Topic Cards
Slide 11  — Tutorial Screen
Slide 12  — Scanner / AR Camera
Slide 13  — Soalan AR Overlay
Slide 14  — Game Board
Slide 15  — Physical Board (papan fizikal)
Slide 16  — Storyboard (user journey)
Slide 17  — Cabaran & Penyelesaian
Slide 18  — What's Next
Slide 19  — Demo (live / video)
Slide 20  — Thank You + Q&A
```

---

*i.-GB — Interactive Game Board with AR (Melaka Theme)*
