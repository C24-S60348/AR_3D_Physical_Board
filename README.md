# i.-GB — Interactive Game Board

**Melaka-themed AR Educational Board Game built with Flutter**

---

## Overview

**i.-GB** (Interactive Game Board) is a Flutter application that combines **Augmented Reality (AR)** with an educational board game inspired by the rich heritage of **Melaka, Malaysia** — a UNESCO World Heritage City since 2008.

The game is structured like **Snake and Ladder** (with 30 squares) but features **Monopoly-style landmark squares** with AR-triggered question cards, similar to how a physical board game would work when scanned with a mobile camera.

---

## App Structure

```
i.-GB App
│
├── 🏠 Splash Screen    — Animated intro with i.-GB branding
├── 🏠 Home Screen      — Enter name, choose topic, navigate to demo or game
├── 📱 AR Demo Screen   — Showcase Flutter AR capabilities (place 3D objects)
├── 🎲 Game Board       — 30-square Melaka-themed Snake & Ladder board
└── ❓ Question Card    — Typed-answer question with AR flip animation
```

---

## Features

### AR Capabilities (Flutter AR Demo)
- **Plane Detection** — Detects horizontal and vertical real-world surfaces
- **3D Object Placement** — Place GLB/GLTF models (Duck, Box, Sphere) in AR space
- **Multiple Objects** — Place as many objects as you want on detected surfaces
- **Object Removal** — Remove all placed objects with one tap
- **Model Cycling** — Switch between 3 different 3D models
- **ARCore (Android)** — Powered by Google ARCore
- **ARKit (iOS)** — Powered by Apple ARKit

### i.-GB Game
- **Name Input** — Track each player by name
- **Topic Selection** — 4 topics: Sejarah Melaka, Seni Bina, Budaya, Pelancongan
- **30-Square Board** — Melaka landmark squares with zigzag layout
- **Dice Roll** — Animated dice with numbers 1–6
- **Snake & Ladder** — Special squares that move you up or down
- **Question Cards** — Flip-animated typed-answer questions
- **Flexible Grading** — Ignores case and accepts equivalent fractions/decimals
- **Score Tracking** — +10 per correct answer, accuracy calculation
- **End Game Summary** — Results dialog with score and accuracy
- **Offline Mode** — All questions stored locally (no internet needed for game)

### Gameboard (HTML)
- Open `assets/board/melaka_board.html` in any browser to see the full game board
- Melaka red & gold color theme
- All 30 squares with landmark names and emojis
- Snake, ladder, and question squares clearly marked
- Hover any square for highlight effect

---

## Melaka Landmarks on the Board

| Square | Landmark | Type |
|--------|----------|------|
| 1  | Padang Pahlawan | START 🚩 |
| 2  | Stadthuys (Dutch Red Building) | Normal |
| 3  | Christ Church Melaka | Normal |
| 4  | Pekan Lama | QUESTION ❓ — Sejarah |
| 5  | Jalan Jonker | SNAKE 🐍 → Square 1 |
| 6  | Muzium Baba Nyonya | Normal |
| 7  | Sungai Melaka (River Cruise) | Normal |
| 8  | Jambatan Lama | QUESTION ❓ — Budaya |
| 9  | Kota A-Famosa | Normal |
| 10 | Bukit St. Paul | Normal |
| 11 | Tangga Warisan | LADDER 🪜 → Square 20 |
| 12 | Tapak Warisan UNESCO | QUESTION ❓ — Seni Bina |
| 13 | Menara Taming Sari | Normal |
| 14 | Melaka Eye (Giant Wheel) | Normal |
| 15 | Cheng Hoon Teng Temple | Normal |
| 16 | Lorong Budaya | QUESTION ❓ — Pelancongan |
| 17 | Masjid Kampung Kling | Normal |
| 18 | Ular Besar! | SNAKE 🐍 → Square 7 |
| 19 | Masjid Selat Melaka (Floating) | Normal |
| 20 | Proclamation of Independence Memorial | Normal |
| 21 | Dataran Kemerdekaan | QUESTION ❓ — Sejarah |
| 22 | Istana Lama Melaka | SNAKE 🐍 → Square 14 |
| 23 | Taman Bunga | Normal |
| 24 | Pusat Budaya | QUESTION ❓ — Budaya |
| 25 | Tangga Emas | LADDER 🪜 → Square 29 |
| 26 | Zoo Melaka | Normal |
| 27 | Kawasan Warisan | QUESTION ❓ — Seni Bina |
| 28 | Pantai Klebang | Normal |
| 29 | Muzium Negeri Melaka | Normal |
| 30 | Taman Negara Melaka | FINISH 🏆 |

---

## Question Topics

### 📜 Sejarah Melaka
History of Melaka: founding by Parameswara, Portuguese/Dutch/British conquests, UNESCO status.

### 🏛️ Seni Bina
Architecture: Stadthuys (meaning, color), A-Famosa (materials), St. Paul's Church, Menara Taming Sari.

### 🎎 Budaya
Culture: Baba Nyonya community, Nasi Ayam Bola, Jonker Street, Beca berhias, Chitty community.

### 🗺️ Pelancongan
Tourism: Sungai Melaka cruise, Melaka Eye, Masjid Selat, UNESCO recognition, Pantai Klebang.

---

## Setup & Build

### Prerequisites
- Flutter 3.x (tested on Flutter 3.41.9 / Dart 3.11.5)
- Android Studio / Xcode
- **Physical Android device** with ARCore support (API 24+)
- **Physical iOS device** with ARKit support (iOS 11+)
- AR does NOT work on emulators/simulators

### Commands

```bash
# Get dependencies
flutter pub get

# Run on connected device (debug)
flutter run

# Build Android APK (debug)
flutter build apk --debug

# Build Android APK (release)
flutter build apk --release

# Build iOS (requires Mac + Xcode)
flutter build ios
```

### Flask API and Lecturer Admin

The `server/` directory contains the Flask API, SQLite database, image uploads,
learner answer tracking, and lecturer question-management page. Its controller
is the `ar3d` Blueprint.

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export FLASK_SECRET_KEY="replace-me"
export AR3D_ADMIN_PASSWORD="replace-me"
export AR3D_ADMIN_API_KEY="replace-me"
flask --app app run --host 0.0.0.0 --port 5000
```

Open `http://127.0.0.1:5000/admin/ar3d` for the lecturer page. See
`server/README.md` for the API request formats and Flutter connection command.
The Flutter home screen also provides **Lecturer Admin** for managing typed
questions and viewing learner responses directly inside the app.

### Android Requirements
- Minimum SDK: **API 24** (Android 7.0) — ARCore requirement
- Camera permission declared in `AndroidManifest.xml`
- ARCore metadata: `com.google.ar.core = required`
- Internet permission for loading remote GLB models in AR demo

### iOS Requirements
- Minimum iOS: **11.0**
- Add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Camera diperlukan untuk fungsi AR i.-GB</string>
  ```

---

## Project Structure

```
my_ar_app/
├── lib/
│   ├── main.dart                      # App entry, routes
│   ├── screens/
│   │   ├── splash_screen.dart         # Animated splash with i.-GB branding
│   │   ├── home_screen.dart           # Name input + topic selection
│   │   ├── ar_demo_screen.dart        # Flutter AR capabilities showcase
│   │   ├── game_board_screen.dart     # 30-square Melaka game board + dice
│   │   └── question_screen.dart       # Animated flip question card
│   ├── data/
│   │   └── questions_data.dart        # Offline question bank (4 topics, 6 Q each)
│   └── models/
│       └── game_model.dart            # GameSquare, gameBoard, PlayerResult
├── assets/
│   └── board/
│       └── melaka_board.html          # Interactive HTML gameboard (open in browser)
├── android/
│   └── app/
│       ├── build.gradle.kts           # minSdk=24 for ARCore
│       └── src/main/AndroidManifest.xml # Camera + AR permissions + app name
└── pubspec.yaml                       # Dependencies: ar_flutter_plugin, permission_handler
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| AR (Android) | Google ARCore via `ar_flutter_plugin` v0.7.3 |
| AR (iOS) | Apple ARKit via `ar_flutter_plugin` v0.7.3 |
| 3D Models | GLB format loaded via URL |
| State Management | Flutter StatefulWidget |
| Local Data | Dart constants (offline) |
| Planned API | REST API for online leaderboard |

---

## Planned Features (Future)

- [ ] **Image Tracking** — Scan physical board square markers to trigger AR questions
- [ ] **Online Leaderboard API** — POST results to backend, GET top scores
- [ ] **Multiplayer** — Multiple players take turns on the same device
- [ ] **More Topics** — Makanan Melaka, Perikanan, Flora & Fauna
- [ ] **Sound Effects** — Dice roll, correct/wrong sounds, background music
- [ ] **AR Question Cards** — Question appears as a floating 3D card in AR space
- [ ] **Custom AR Markers** — Printable markers for each board square
- [ ] **Teacher Dashboard** — Track class performance via API
- [ ] **Malay & English** — Full bilingual support

---

## How to Play

1. Open the app → enter your name → choose a topic
2. Tap **MAIN i.-GB** to start the game
3. Tap the **dice** to roll (1–6)
4. Your piece moves on the board automatically
5. **Blue ❓ squares** — a question card flips open, answer to get **+10 points**
6. **Red 🐍 squares** — snake! You slide back to a lower square
7. **Green 🪜 squares** — ladder! You climb up to a higher square
8. First to reach **Square 30** wins!

---

## Gameboard HTML

Open `assets/board/melaka_board.html` in any browser:
- Drag the file into Chrome/Safari/Firefox — no server needed
- All 30 squares rendered with landmark info
- Color-coded: blue=question, red=snake, green=ladder, gold=finish
- Hover any square to highlight it

---

## Credits

- **AR Engine**: [ar_flutter_plugin](https://pub.dev/packages/ar_flutter_plugin) by Julian Steenbaker
- **3D Sample Models**: Khronos Group glTF Sample Model Repository
- **Theme**: Melaka, Malaysia — UNESCO World Heritage City 2008
- **Framework**: Flutter by Google

---

*i.-GB — Belajar sejarah Melaka melalui permainan* 🏰🎲📱
# AR_3D_Physical_Board
