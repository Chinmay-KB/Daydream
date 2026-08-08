# Daydream

A tiny macOS menu bar app that puts a screensaver-like overlay on **one display at a time** — click the icon on a display's menu bar to Daydream that screen.

## What it does

- Lives in the menu bar (no Dock icon)
- **Click the icon on a display** to cover that display (below the menu bar, so the icon stays usable)
- Click the same display's icon again to turn it off
- Click a different display's icon to move Daydream there
- Click the overlay or press Esc to dismiss
- Right-click the icon for Quit

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
