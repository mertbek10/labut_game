# 🎳Labut Daily Game

A lightweight, daily, single-attempt puzzle for the YurtPal app.
Each day generates a deterministic but random-looking arrangement of colored pins (“labuts”).
Players swap two pins to match the hidden target. Progress updates live. The board is solvable by swaps only, and today’s puzzle can be played once per device.

### 💻 Tech Stack

Flutter (stable channel)

State management: Cubit (flutter_bloc)

Local persistence: SharedPreferences

No backend required (can be added later for server-authoritative daily/leaderboards)

### 📸 Screenshots
![](lib/docs/screenshotgame.png)

![](lib/docs/screenshotsolved.png)
