# ArenaTrinketSound

A World of Warcraft addon that plays a sound whenever an enemy uses their PvP trinket in arenas (regular, skirmish, solo shuffle). Sound can be configured by default (one sound for all), role, class, or spec.

- **Interface**: 120000 (retail / Midnight)
- **SavedVariables**: `ArenaTrinketSoundDB`
- **CurseForge ID**: 1458507
- **Slash commands**: `/ats`, `/arenatrinketsound`

---

## File Structure

| File | Purpose |
|---|---|
| `ArenaTrinketSoundDBUtils.lua` | SavedVariables init, `getOptionValue` / `setOptionValue` helpers |
| `ArenaTrinketSoundSystem.lua` | Sound maps, `playTrinketSound`, `playPreviewSound`, channel checks |
| `ArenaTrinketSoundOptions.lua` | Settings UI panel, slash command registration |
| `ArenaTrinketSound.lua` | Main logic — event handling, trinket detection, sound dispatch |
| `sounds/default/` | `trinket_default.ogg` — played when sound type is `Default` or as fallback |
| `sounds/roles/` | `tank.ogg`, `healer.ogg`, `dps.ogg` |
| `sounds/classes/` | One `.ogg` per class (e.g. `druid.ogg`, `deathknight.ogg`) |
| `sounds/specs/` | One `.ogg` per spec (e.g. `restoration_druid.ogg`) |

Load order is defined in `ArenaTrinketSound.toc` and matters — DBUtils and SoundSystem must load before the main file.

---

## Architecture

The addon uses a shared namespace via the second vararg (`local _, addon = ...`). Modules attach themselves to it:

```lua
addon.DBUtils = {}
addon.SoundSystem = {}
```

No global pollution except `OpenArenaTrinketSoundOptionsPanel` (required by `AddonCompartmentFunc`) and the slash command entries.

---

## Dev Notes
See `NOTES.md` for findings and discoveries about WoW API behaviour.

---

## Key APIs & Gotchas

### Trinket detection
Trinket usage is detected via `C_PvP.GetArenaCrowdControlInfo(unit)`, which returns a secret value for `startMs` when the trinket is on cooldown. Detection relies on `issecretvalue(startMs)` — if it's not a secret value, the trinket is not on CD.

### Trinket cooldowns are hardcoded
Blizzard returns a secret value for `durationMs` too, so cooldown durations are hardcoded:
- **Healer**: 90 seconds
- **DPS / Tank**: 120 seconds

Do not try to read duration from the API — it will not work.

### Spec identity format
When sound type is `specs`, the identity key is built as `"SpecName_ClassName"` (e.g. `"Restoration_Druid"`), then uppercased to match `SPECS_SOUND_MAP` keys (e.g. `RESTORATION_DRUID`).

### Events
| Event | Purpose |
|---|---|
| `ARENA_COOLDOWNS_UPDATE` | Fired when trinket CD state changes; triggers `OnArenaTrinketUpdate` |
| `ARENA_PREP_OPPONENT_SPECIALIZATIONS` | Wipes `trinketUsedAt` at start of prep phase |
| `PVP_MATCH_STATE_CHANGED` | Wipes state on `StartUp`; seeds state on `Engaged` |
| `PLAYER_ENTERING_WORLD` | Seeds state on reconnect/reload mid-arena |

---

## Development Workflow

### Deploy to WoW
Run `deploy.bat` in the repo root. It watches for any keypress, then uses `robocopy` to sync the addon to:

```
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ArenaTrinketSound
```

It excludes `.git` and `deploy.bat` itself. Keep `deploy.bat` running in the background while iterating — press any key after each change to push.

To reload the addon in-game without restarting WoW:
```
/reload
```

### Release to CurseForge
Push a version tag to GitHub:
```
git tag v3.0.1
git push origin v3.0.1
```

CurseForge's webhook picks up the tag and publishes the addon automatically. `CLAUDE.md` is excluded from the package via `.pkgmeta`.

Update `## Version` in `ArenaTrinketSound.toc` before tagging.

---

## Adding a New Sound

1. Add the `.ogg` file to the correct `sounds/` subfolder.
2. Add its key/filename entry to the appropriate map in `ArenaTrinketSoundSystem.lua` (`ROLES_SOUND_MAP`, `CLASS_SOUND_MAP`, or `SPECS_SOUND_MAP`).

The sound system falls back to `sounds/default/trinket_default.ogg` if a file is missing or the mapping fails.
