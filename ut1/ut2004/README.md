# ut2004 — AutoBot

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
System/AutoBot.ini       default settings, copied to <UT2004>/System
scripts/build.sh         copy, register EditPackages, compile & exportcache
```

## Requirements

- An installed copy of UT2004 (patch 3369). The game is no longer sold; use your
  CD/DVD or an existing Steam/GOG install. See <https://www.oldunreal.com> for
  community patches and installers.
- `ucc` from the game's `System` folder (included with the game).

## Build and install

### From WSL or Linux (scripted)

```bash
scripts/build.sh /mnt/c/UT2004        # path to your UT2004 install
```

The script:
1. copies `AutoBot/` to `<UT2004>/AutoBot`,
2. installs `System/AutoBot.ini` if you don't have one yet,
3. adds `EditPackages=AutoBot` to `[Editor.EditorEngine]` in `UT2004.ini`
   (once; a backup is saved as `UT2004.ini.bak`),
4. deletes old `AutoBot.u` / `AutoBot.ucl`, compiles via `UCC.exe make` (or
   `ucc-bin` / `wine`), and runs `exportcache` to generate `AutoBot.ucl`.

### On Windows (manual)

1. Copy the `AutoBot` folder to `<UT2004>\AutoBot`.
2. Copy `System\AutoBot.ini` to `<UT2004>\System\AutoBot.ini`.
3. In `<UT2004>\System\UT2004.ini`, under `[Editor.EditorEngine]`, add after
   the last `EditPackages=` line:
   ```
   EditPackages=AutoBot
   ```
4. Delete `<UT2004>\System\AutoBot.u` and `AutoBot.ucl` if they exist, then run:
   ```cmd
   cd /d C:\UT2004\System
   UCC.exe make
   UCC.exe exportcache -v AutoBot.u
   ```

## Usage

1. Open **Instant Action → Mutators** and enable any combination of **AutoBot**,
   **AutoBot Brain**, and **AutoPlay**.
2. For **AutoPlay**, bind a toggle key in the in-game console (`~`):
   ```
   set Input F8 mutate AutoPlay
   ```
   Press `F8` while alive to hand control to `AutoBotController`; press `F8` again
   to resume manual control.

## Settings (`<UT2004>/System/AutoBot.ini`)

UT2004 INI files don't support comments at the end of a line, so put only the
value after `=`. These values override the defaults compiled into the package. If
the file is missing, the defaults from `defaultproperties` are used.

Section `[AutoBot.AutoBotMutator]`:

| Key             | Default | Range / meaning                                  |
|-----------------|---------|--------------------------------------------------|
| `BotSkill`      | 6.0     | 0..7                                             |
| `Aggression`    | 0.6     | CombatStyle (-1..1): >0 charges, <0 keeps distance |
| `StrafeAbility` | 0.8     | -1..1                                            |
| `AccuracyBonus` | 0.5     | -1..1                                            |
| `bHuntItems`    | True    | low-health item hunting / retreat bias           |
| `TuneInterval`  | 1.0     | seconds between bot re-tunes                     |

Section `[AutoBot.AutoBotController]`:

| Key              | Default | Meaning                                         |
|------------------|---------|-------------------------------------------------|
| `RetreatHealth`  | 40.0    | HP threshold below which `Retreat` is scored    |
| `WeightFight`    | 1.0     | utility weight for `Fight`                      |
| `WeightGrabItem` | 0.8     | utility weight for `GrabItem`                   |
| `WeightRoam`     | 0.5     | utility weight for `Roam`                       |
| `WeightRetreat`  | 1.5     | utility weight for `Retreat`                    |
| `ThinkInterval`  | 0.5     | seconds between brain evaluations (min `0.1`)   |
| `bDebugLog`      | False   | log state transitions to `UT2004.log`           |

## Installing UT2004 under WSL (optional)

The simplest setup is to play on Windows and only run `scripts/build.sh` from
WSL. If you want the game inside WSL, WSLg can show Wine windows:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine wine32:i386 winetricks
wine /path/to/UT2004/setup.exe
```
