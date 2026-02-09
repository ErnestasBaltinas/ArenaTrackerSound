# ArenaTrinketSounds

**ArenaTrinketSounds** is a World of Warcraft addon that plays a short sound whenever an enemy player uses their PvP trinket in arenas. It supports **regular arenas**, **skirmishes**, and **solo shuffle**.

---

## Features

🔊 **Trinket Alerts**

- Plays a **different sound depending on the enemy role**:
  - **Healer** – "Healer Trinketed" sound
  - **DPS** – "DPS Trinketed" sound
- Works in **all PvP arena instances**: regular arena, skirmish, and solo shuffle.
- Designed with **modern Blizzard API**, fully compatible with **Midnight**.

🧠 **Reliable detection**

- Tracks enemy trinket usage using official Blizzard arena APIs.
- Avoids multiple alerts for the same trinket use.
- Automatically starts tracking when you enter an arena and stops when you leave.

🎵 **Customizable**

- You can replace the `.ogg` sound files in the `sounds/` folder with your own custom sounds if you want to personalize the alerts.

---

## Notes

- Works only in arenas; battlegrounds are not supported.
- Uses **Blizzard’s modern APIs**, so it is compatible with current WoW builds (Midnight).
- Designed to be lightweight and focused on trinket usage notifications.
