# 🐧 Huddle Up: Antarctic Penguin Puzzle

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod-blue)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)](https://flutter.dev)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](#-license)

**Huddle Up** is an Antarctic puzzle adventure inspired by Sokoban and Handshake mechanics. Guide separated kawaii penguins across treacherous ice floes, navigate winding corridors, merge them into cohesive clumps, and reach the sanctuary of the cozy 1-tile igloo using the optimal, shortest route!

---

## ❄️ Game Overview & Mechanics

In the harsh Antarctic wilderness, penguins can't survive alone. When adjacent penguins touch, they **huddle together into a clump**, combining their powers and moving as a single united team!

### 🎯 Key Rules
1. **Full-Bleed Arena**: Clean top-down view where the ice board extends edge-to-edge with no wasted border walls.
2. **Cozy 1-Tile Igloo**: Guide all penguins to enter the igloo. Once a penguin reaches the igloo, it enters and safely settles inside.
3. **Limited Move Budget (Shortest Route)**: Each penguin displays its remaining move count right on its belly. Take the optimal path—if a penguin runs out of moves (`0` in red), it gets stuck!
4. **Huddle Merging**: When penguins touch, they form a clump. Clump members move simultaneously and combine directional restrictions.
5. **Hazards**: Steer clear of open ice holes and freezing water. Watch your step on cracked ice—it shatters into a bottomless hole after you pass!

---

## 🐧 Penguin Species & Abilities

| Penguin | Trait | Power / Restriction |
| :--- | :--- | :--- |
| **Blue (Classic)** | ✦ 4-Way Navigator | Can walk in all 4 cardinal directions (Up, Down, Left, Right). |
| **Green (Lanky)** | ⇅ Vertical Strider | Walks **only Up and Down** unless clumped with a horizontal mover. |
| **Orange (Round)** | ⇄ Horizontal Dasher | Walks **only Left and Right** unless clumped with a vertical mover. |
| **Red (Speedy)** | ⏩ Ice Slider | Slides uncontrollably until hitting a wall, obstacle, or teammate. |
| **Yellow (Jumper)** | ↷ Crevasse Hopper | Hops 2 tiles over water and small holes. |
| **Purple (Mystic)** | 🔀 Swapper | Swaps places with adjacent blocks or teammates. |
| **Grey (Chonky)** | 🚜 Bulldozer | Heavyweight pusher that can shove chains of up to 3 ice blocks. |

---

## 🧩 Procedural Level Generation & BFS Solver

Every level is procedurally carved and **100% verified solvable**:
- **BFS Solver**: Validates each generated board, exploring state graphs to prove solvability and find the optimal shortest route.
- **Archetype Variations**:
  - *Two-Wing Dividers*: Central barrier walls with doorway passages.
  - *Horseshoe U-Shapes*: Corridors wrapping around central glacial pillars.
  - *S-Curves & Windings*: Alternating zig-zag passages.
  - *Pillar Courtyards*: Loops and crossroad mazes.
- **Dynamic Move Calibration**: The exact moves required by each penguin in the shortest BFS path are assigned as that penguin's starting move budget.

---

## 🎮 Features & Aesthetics

- **Rich Kawaii Visuals**: Vector-rendered chubby penguins with expressive twinkle eyes, blush cheeks, fluttering flippers, and ground drop shadows.
- **Circular Pedestal Deck**: 3D pop-out character tokens on the bottom deck with info buttons, safe checkmarks, and breathing glow animations.
- **Instant SFX Engine**: Low-latency preloaded audio architecture using SoundPool buffers for lag-free tap and slide audio.
- **Loss Aversion Emergency Rescue**: 5-second countdown rescue dialog on defeat offering second chances via rewarded ads or move rewinds.
- **VIP Mode**: Premium ad-free players receive 3 starting lives, while free players have 1 life.
- **Undo / Rewind**: Unlimited move undo steps powered by a snapshot history state machine.

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── clumps.dart            # Clump formation and joint movement rules
│   ├── game_state.dart        # Immutable GameState, Position, and Penguin models
│   ├── level_data.dart        # Level definition models and campaign levels
│   ├── penguin_types.dart     # Penguin color, abilities, and display definitions
│   ├── rules.dart             # Movement validation, ice hazards, and win checks
│   └── tile_types.dart        # Board tile definitions (floor, wall, water, hole, igloo)
├── gen/
│   ├── generator.dart         # Procedural level generator & BFS shortest-path solver
│   └── level_provider.dart    # Asynchronous background level generation
├── services/
│   ├── ad_service.dart        # AdMob banners, interstitials, and rewarded rescue ads
│   ├── audio_service.dart     # Low-latency preloaded soundpool audio manager
│   └── game_storage.dart      # SharedPreferences persistent progress & streak storage
├── ui/
│   ├── game_notifier.dart     # Riverpod GameNotifier state machine & timer
│   ├── screens/
│   │   ├── game_screen.dart   # Main gameplay screen, pause dialog & rescue overlay
│   │   └── home_screen.dart   # Level select, coin balances, and wardrobe shop
│   └── widgets/
│       ├── arena_view.dart    # Interactive zoom/pan board and tile rendering
│       ├── card_row.dart      # Circular pedestal tokens with 3D pop-out heads
│       ├── celebration_overlay.dart # 3-star victory fanfare & confetti shower
│       ├── joystick_pad.dart  # 4-way tactile D-pad controls with haptic feedback
│       ├── kawaii_penguin.dart# Procedural vector kawaii penguin with belly counter
│       ├── penguin_info_dialog.dart # First-encounter tutorial & ability popups
│       └── top_bar.dart       # Header with level info, par target, pause & undo
└── main.dart                  # App bootstrap, Riverpod scope, and portrait lock
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- Android Studio / VS Code with Flutter extension
- Android SDK (`API 24+` recommended)

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/gtxPrime/huddle-up.git
   cd huddle-up
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run unit tests**:
   ```bash
   flutter test
   ```

4. **Launch on an emulator or connected device**:
   ```bash
   flutter run
   ```

---

## 📄 License

Copyright © 2026 gtxPrime. All Rights Reserved.  
Proprietary and closed source. Unauthorized copying, modification, or distribution of this software and associated materials is strictly prohibited.
