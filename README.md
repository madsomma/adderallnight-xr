# 💊 AdderAllNight XR

**Extended-release wakefulness for your Mac.**

AdderAllNight XR is a small menu bar app that keeps your Mac and its display awake. It is a menu bar wrapper for `caffeinate`, the tool that's built-in on the terminal. Pick a dose and your Mac stays up for that long. Pick Extended Release and it stays up until you say stop.

There is no Dock icon and no window. Only a pill in your menu bar.

> ⚠️ **Disclaimer:** AdderAllNight XR is not a medical product and has no affiliation with any pharmaceutical company. It does nothing for *you*. It only keeps your *Mac* awake. **Side effects include completed builds, dry eyes and shipped code.** Consult your sleep schedule before use. Do not operate heavy machinery or `rm -rf` while in XR mode.

## Install

You need macOS 13 (Ventura) or later.

### Download

1. Download `AdderAllNight-XR.zip` from the [latest release](../../releases/latest).
2. Unzip it and drag `AdderAllNight XR.app` into your Applications folder.
3. Open it.

The app is not notarized by Apple, so macOS blocks it the first time you open it. To allow it, run this once in Terminal:

```bash
xattr -dr com.apple.quarantine "/Applications/AdderAllNight XR.app"
```

You can also open System Settings, go to Privacy & Security and click **Open Anyway** next to the app's name.

### Build from source

You need the Swift 5.9 toolchain (Xcode or the Command Line Tools). Clone this repository, then run:

```bash
cd adderallnight-xr
./scripts/release.sh --no-zip
open "dist/AdderAllNight XR.app"
```

Run `./scripts/release.sh` without `--no-zip` to also get `dist/AdderAllNight-XR.zip` and its SHA-256 hash.

### Start at login

Open System Settings, go to General → Login Items and add `AdderAllNight XR`.

## Usage

Click the pill in the menu bar.

| Menu item | What it does |
|---|---|
| Status | Shows `Sleeping / Idle` or the dose that is running, such as `Active (90mg · 89m left)` or `Active (XR - Indefinite)` |
| Dosage | Pick a timed dose or Extended Release |
| Flush system (deactivate) | Stops the dose and lets your Mac sleep again |
| Quit AdderAllNight XR | Stops the dose and closes the app |

Picking a new dose replaces the one that is running. Timed doses end on their own. If something goes wrong a `⚠️` line appears at the top of the menu.

### Dosage

| Dose | Duration | Runs |
|---|---|---|
| 15mg | 15 minutes | `caffeinate -di -t 900` |
| 30mg | 30 minutes | `caffeinate -di -t 1800` |
| 60mg | 1 hour | `caffeinate -di -t 3600` |
| 90mg | 90 minutes | `caffeinate -di -t 5400` |
| 120mg | 2 hours | `caffeinate -di -t 7200` |
| Extended Release (XR) | Until you stop it | `caffeinate -di` |

`-d` keeps the display awake and `-i` keeps the system from idle sleep.

### What the icon means

| Icon | Meaning |
|---|---|
| Outline capsule with beads | Idle. Your Mac can sleep. |
| Solid capsule with a ⚡ spark | Extended Release. Awake until you stop it. |
| Capsule with one full half and one empty half, next to a number | Timed dose. The capsule empties as time runs out and the number is the minutes left. 1h 29m shows as `89m`. |

A timed dose that has just started is solid with no spark. That is how you tell it apart from XR.

## How it works

Each dose starts `/usr/bin/caffeinate` as a child process, along with `-w <app pid>` so it exits if the app is force-quit. Only one runs at a time. Flush and Quit stop it right away. It makes no network requests and collects nothing.

## Legal

AdderAllNight XR is an open-source software utility and a parody. It is **not affiliated with, endorsed by or associated with any pharmaceutical manufacturer, drug brand or trademark**. Any resemblance to real medications is satire. The "pill" is a handful of vector shapes and the "dosage" is a number of seconds. This is not medical advice. Please sleep eventually.

## License

MIT. Take it, fork it, ship it. See [LICENSE](LICENSE).
