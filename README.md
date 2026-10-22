# GymBuddy

A personal iPhone app (SwiftUI, iOS 17+) for building up from walking to running and for a 3-day gym plan aimed at a lean, visible-abs physique.

## What it does

- **Run/walk programme** – 9 weeks from 1 min run / 2 min walk to 30 min nonstop. GPS distance, route and pace, voice cues, background tracking with the screen locked.
- **Gym plan** – three rotating full-body sessions (A/B/C), each with direct ab work. Logs sets, runs a rest timer and suggests when to add weight.
- **Progress** – weight, waist and waist ÷ height charts, daily protein target, run history.
- **Weekly schedule** – Mon/Wed/Fri gym, Tue/Thu/Sat run, Sun rest.

## Build (needs a Mac with Xcode 15+)

```sh
brew install xcodegen
xcodegen generate
open GymBuddy.xcodeproj
```

In Xcode: select the GymBuddy target > Signing & Capabilities > choose your Team (a free Apple ID works), plug in your iPhone and press Run. GPS needs a real device; the simulator can only fake a location.

The `.xcodeproj` is generated from `project.yml` and not committed. CI (`.github/workflows/ci.yml`) builds and runs the unit tests on a macOS runner.
