# Dev Notes & Findings

## C_PvP.GetArenaCrowdControlInfo — startMs secret value behaviour (2026-03-20)

After a Midnight-era patch, `startMs` becomes a secret value permanently after the first trinket use — it does not reset when the cooldown expires. Prior to this patch it would return to a non-secret value once the CD ended.

This means `issecretvalue(startMs)` can only reliably detect the **first use** of a trinket. It cannot distinguish "trinket currently on cooldown" from "trinket was used at some point this match". The hardcoded CD timers (90s healer / 120s DPS+tank) remain the only dedup mechanism.

**This API is no longer used.** Replaced by `CcRemoverFrame` frame hooks (see below).

## CcRemoverFrame hook approach (2026-03-20) ✓ confirmed working

`CompactArenaFrameMember{i}.CcRemoverFrame.Cooldown` is Blizzard's own trinket cooldown frame. Two hooks are used:

- `hooksecurefunc(cooldown, "SetCooldown", ...)` — fires when trinket is used. `start` and `duration` are both secret values. Detection is simply: hook fired + no existing record in `trinketUsedAt`.
- `cooldown:HookScript("OnCooldownDone", ...)` — fires when trinket comes off cooldown. Used to clear `trinketUsedAt[unit]` so the next use is detected.

Dedup is handled by `trinketUsedAt` — set on use, cleared on `OnCooldownDone`. No time comparisons or hardcoded CD durations needed.
