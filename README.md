# Daydream

A tiny macOS menu bar app that puts a screensaver-like overlay on your **MacBook built-in display only** — so you can keep working on an external monitor.

## What it does

- Lives in the menu bar (no Dock icon)
- **Turn On Daydream** covers the laptop screen
- External displays stay untouched
- Click the overlay, press Esc, or use the menu to turn it off

## Requirements

- macOS 13+
- Xcode / Swift toolchain

## Run

```bash
./scripts/run.sh
```

This builds a release binary, packages `Daydream.app`, and opens it.

Or build only:

```bash
swift build -c release
```

## Status

Proof of concept. Overlay is a simple black panel with a clock — richer visuals (e.g. bubbles) can come later.
