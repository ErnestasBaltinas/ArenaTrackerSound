# ArenaTrinketSounds

**ArenaTrinketSounds** is a World of Warcraft addon that plays a short sound whenever an enemy player uses their PvP trinket in arenas. It supports **regular arenas**, **skirmishes**, and **solo shuffle**.

---

## Features

🔊 **Trinket Alerts**

- Plays a sound when an enemy uses their PvP trinket.
- Sound type can be configured by:
  - **Default** – One sound plays for every trinket, regardless of class or role.
  - **Role** – Healer Trinketed, DPS Trinketed, Tank Trinketed.
  - **Class** – Warrior Trinketed, Priest Trinketed, DK Trinketed, etc.
  - **Spec** – Arms Trinketed, Resto Druid Trinketed, Unholy Trinketed, etc.
- Works in **all PvP arena instances**: regular arena, skirmish, and solo shuffle.

🎚️ **Sound Channel Selection**

- You can choose which audio channel the alert uses:
  - **Master**
  - **Music**
  - **SFX (Sound Effects)**
  - **Ambience**
  - **Dialog**

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
