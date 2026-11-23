# UT2004AutoBot

UnrealScript mutators and custom bot AI for Unreal Tournament 2004 (offline / standalone matches only).

## Mutators & Classes

| Mutator / Class | Group | Purpose |
| --- | --- | --- |
| **AutoBot** (`AutoBotMutator`) | `AutoBotTune` | Tunes stock bot skill, aggression, strafing, accuracy, jumpiness, projectile leading, and low-health retreat bias. |
| **AutoBot Brain** (`AutoBotSwapMutator`) | `AutoBotBrain` | Replaces stock bot controllers with `AutoBotController` (pre-spawn via `xPawn.default.ControllerClass` plus safe fallback swap). |
| **AutoPlay** (`AutoPlayMutator`) | `AutoPlay` | Toggles autopilot (`AutoBotController`) on your own character in offline matches while keeping your score, team, and appearance. |
| `AutoBotController` | — | Custom `xBot` subclass with utility-scored `Fight` / `Retreat` / `GrabItem` / `Roam` decisions driven via `Tick` accumulation. |
| `WeaponPrefs` | — | Per-range stock UT2004 weapon priority selector used by `AutoBotController`. |

All three mutators use distinct `GroupName` values so they can be enabled independently or together.

## Layout

```
AutoBot/Classes/
  AutoBotController.uc   utility-scored custom bot brain
  AutoBotMutator.uc      stock bot stat tuner mutator
  AutoBotSwapMutator.uc  injects AutoBotController for match bots
  AutoPlayMutator.uc     F8 autopilot mutator for your own pawn
  WeaponPrefs.uc         range-based weapon priority helper
System/AutoBot.ini       default configuration (copied to <UT2004>/System)
scripts/build.sh         copy, register EditPackages, compile & exportcache
```

## Build and Install

### From WSL or Linux (scripted)

```bash
scripts/build.sh /mnt/c/UnrealTournament2004
```

The script:
1. copies `AutoBot/` to `<UT2004>/AutoBot`,
2. installs `System/AutoBot.ini` if missing,
3. appends `EditPackages=AutoBot` under `[Editor.EditorEngine]` in `UT2004.ini` once (saving `UT2004.ini.bak`),
4. deletes old `AutoBot.u` / `AutoBot.ucl`, compiles via `UCC.exe make` (or `ucc-bin` / `wine`), and runs `exportcache` to generate `AutoBot.ucl`.

### Manual (Windows)

1. Copy `AutoBot/` into `<UT2004>\AutoBot`.
2. Copy `System\AutoBot.ini` into `<UT2004>\System\AutoBot.ini`.
3. In `<UT2004>\System\UT2004.ini`, under `[Editor.EditorEngine]`, add `EditPackages=AutoBot` after the last `EditPackages=` line.
4. Delete `<UT2004>\System\AutoBot.u` and `AutoBot.ucl` if present, then run:
   ```cmd
   cd /d C:\UnrealTournament2004\System
   UCC.exe make
   UCC.exe exportcache -v AutoBot.u
   ```

## Usage

1. Open **Instant Action → Mutators** and enable any combination of **AutoBot**, **AutoBot Brain**, and **AutoPlay**.
2. For **AutoPlay**, bind a toggle key in the in-game console (`~`):
   ```
   set Input F8 mutate AutoPlay
   ```
   Press `F8` while alive to hand control to `AutoBotController`; press `F8` again to resume manual control.

## Configuration (`<UT2004>/System/AutoBot.ini`)

UT2004 INI files do not support inline comments at the end of value lines.

- **`[AutoBot.AutoBotMutator]`**: `BotSkill` (`0..7`), `Aggression` (`-1..1`), `StrafeAbility` (`-1..1`), `AccuracyBonus` (`-1..1`), `bHuntItems` (`True`/`False`), `TuneInterval` (seconds).
- **`[AutoBot.AutoBotController]`**: `RetreatHealth`, `WeightFight`, `WeightGrabItem`, `WeightRoam`, `WeightRetreat`, `ThinkInterval`, `bDebugLog`.
