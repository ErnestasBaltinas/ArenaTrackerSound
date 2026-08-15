## Arena Trinket Sound release 2.6.0

### Changes

- Fixed errors caused by Blizzard API changes in patch 12.1 — class and role detection no longer use APIs that return secret values for arena opponents

## Arena Trinket Sound release 2.5.0

### Changes

- Updated interface version for compatibility with the latest game build

## Arena Trinket Sound release 2.4.1

### Changes

- Updated interface version for compatibility with the latest game build

## Arena Trinket Sound release 2.4.0

### Changes

- Fixed sounds sometimes being cut off mid-play due to a double sound playback bug in the fallback logic
- Sound channel now falls back to Master if no channel is configured

## Arena Trinket Sound release 2.3.0

### Changes

- Updated trinket detection to work with recent Blizzard API changes

## Arena Trinket Sound release 2.2.0

### Changes

- Added **Default** sound mode — one sound plays for every trinket, no matter the enemy's class or role

## Arena Trinket Sound release 2.1.0

### Changes

- Fixed trinket tracking issues (caused by recent Blizzard API changes)

## Arena Trinket Sound release 2.0

### Changes

- Added configurable **sound type modes**:
  - Role-based alerts (Healer / DPS)
  - Class-based alerts (Warrior, Priest, DK, etc.)
  - Spec-based alerts (Arms, Resto Druid, Unholy, etc.)
- Added **sound channel selection**:
  - Master
  - Music
  - SFX (Sound Effects)
  - Ambience
  - Dialog
