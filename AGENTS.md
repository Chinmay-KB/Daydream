# AGENTS.md

Guidance for AI coding tools and new contributors working on Daydream.

## What Daydream is

Daydream is a macOS menu bar app that renders a full-screen overlay of floating, colliding bubbles (a Vista-style ambient "daydream") on any display the user chooses. Each display is toggled independently by clicking the menu bar icon on that display. Clicking the overlay or pressing Esc dismisses it on that screen. Right-clicking the menu bar icon shows a Quit menu.

There is no UI framework beyond AppKit, no third-party dependencies, no persistence, and no settings. The app runs as an accessory (`.accessory` activation policy), so it never appears in the Dock.

## Requirements

- macOS 14+ to run.
- Swift 5.9+ (Xcode Command Line Tools) to build. This is a SwiftPM executable target; there is no `.xcodeproj`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `Sources/Daydream/AppDelegate.swift` | Entry point (`@main`); wires the status bar controller to the overlay controller. |
| `Sources/Daydream/StatusBarController.swift` | Menu bar item, left-click toggles the overlay on the clicked display, right-click shows Quit. |
| `Sources/Daydream/AmbientOverlayController.swift` | Owns one overlay window per active display (keyed by `CGDirectDisplayID`), the Esc key monitor, and screen-change handling. |
| `Sources/Daydream/AmbientContentView.swift` | Drives a `CADisplayLink` loop, maps simulation state onto one `CALayer` per bubble. |
| `Sources/Daydream/BubblesSimulation.swift` | Pure-ish physics: spawn from a random corner, drift with curved paths, wall bounces, pairwise collisions. No AppKit imports. |
| `Sources/Daydream/BubbleSpriteCache.swift` | Caches bubble sprite images by hue so layers reuse contents. |
| `Sources/Daydream/DaydreamIcon.swift` | Draws the status bar icon (active/inactive variants). |
| `Sources/Daydream/NSScreen+DisplayID.swift` | Safe extraction of `CGDirectDisplayID` from `NSScreen`. |
| `scripts/` | Build, sign, notarize, DMG, and icon-rendering scripts. `run.sh` is the quickest dev loop. |
| `.github/workflows/release.yml` | Tag-triggered release: universal build, optional Developer ID signing + notarization, ZIP/DMG + checksums. |
| `docs/RELEASING.md` | Release process and required secrets. |
| `docs/BRANDING.md`, `Design/LogoConcepts/` | Logo concepts (SVG sources); "Orbit Bubble" is the selected mark. |
| `Info.plist` | App bundle plist template; version fields are stamped by `build-app.sh`. |

## Build, run, and verify

```bash
# Fast dev loop: builds v0.1.0 (or a passed tag) and opens the app
./scripts/run.sh

# Full app bundle build (universal arm64 + x86_64)
./scripts/build-app.sh v0.1.0
open .build/Daydream-app/Daydream.app

# Plain compile check (single arch, no bundle)
swift build
```

There is no test target yet. At minimum, run `swift build` before considering a change done. For behavior changes, build the app and manually verify: toggling per display, click-to-dismiss, Esc-to-dismiss, and (if you can) connecting/disconnecting a display while active.

## Architecture notes and invariants

- **Per-display sessions.** `AmbientOverlayController` keeps a `[CGDirectDisplayID: Session]` map. Every display's overlay is independent; never assume a single overlay. Session teardown must remove the layer animation, close the window, and — when the last session ends — remove the Esc monitor and the screen-parameter observer.
- **Screens can disappear.** `NSScreen.displayID` can be nil and displays can be unplugged mid-session. `handleScreenChange` reconciles the session map against the live screen list; keep that path safe.
- **Overlay window configuration matters.** The window is borderless, transparent, at `.screenSaver` level, joins all Spaces, and accepts mouse events so a click can dismiss it. Changing `collectionBehavior` or `level` has visible side effects (full-screen apps, Mission Control).
- **Simulation is separate from rendering.** `BubblesSimulation` only depends on CoreGraphics types; `AmbientContentView` translates its state into layers. Keep it that way — new visual behaviors should go in the simulation, and new drawing concerns in the view/sprite cache.
- **Performance.** Rendering uses cached sprite images on `CALayer`s with implicit animations disabled inside a `CATransaction`. Avoid per-frame image creation or per-frame layer add/remove.
- **Menu bar clicks need a real event.** `statusItemClicked` guards on `NSApp.currentEvent`; this was a deliberate fix (see commit history) — don't remove it.

## Conventions

- Swift, AppKit-first, no external dependencies unless there is a strong reason.
- Keep imports at the top of the file; no inline imports.
- In `switch` statements over enums or discriminated unions, keep them exhaustive so new cases fail to compile until handled.
- Shell scripts use `set -euo pipefail` and defensively validate paths before `rm -rf`. Follow that pattern in any new script.
- Version tags are strict `vMAJOR.MINOR.PATCH`; the build and release scripts reject anything else.
- Documentation lives in `README.md` (user-facing) and `docs/` (contributor/release-facing). Update both when behavior or the release process changes.

## Release

Pushing a `vX.Y.Z` tag triggers `.github/workflows/release.yml`. It builds a universal binary, signs and notarizes when the full secret set is present (see `docs/RELEASING.md`), otherwise falls back to ad-hoc signing with a warning. Never commit signing material.
