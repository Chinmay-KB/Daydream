# Daydream

![Daydream Orbit Bubble](Design/LogoConcepts/orbit-bubble.svg)

Daydream is a small Mac menu bar app that puts floating bubbles on one screen while you work on another.

## Download

When a GitHub Release is available, download its ZIP or DMG from the [Releases page](../../releases). You do not need to clone or compile the project to use a release.

## Use

1. Open `Daydream.app` from the DMG or ZIP.
2. Click the bubble mark in the menu bar on the screen you want to Daydream.
3. Click the mark again, click the bubbles, or press Esc to turn it off.
4. Right-click the mark to quit.

## Build locally

```bash
./scripts/build-app.sh v0.1.0
open .build/Daydream-app/Daydream.app
```

For a local ad-hoc signature and DMG:

```bash
./scripts/sign-app.sh .build/Daydream-app/Daydream.app -
./scripts/create-dmg.sh .build/Daydream-app/Daydream.app .build/Daydream-v0.1.0.dmg
```

`./scripts/run.sh` builds version `0.1.0` and opens the app.

## Release

Push a strict tag such as `v0.1.0` to create a GitHub Release. The release workflow builds a universal app, packages a ZIP and DMG, and adds SHA-256 checksums. It notarizes the artifacts only when the complete signing and notarization secret set is available. See [release instructions](docs/RELEASING.md).

## Requirements

- macOS 14 or later to use Daydream.
- Xcode Command Line Tools with Swift 5.9 or later to build from source.

## Security and Gatekeeper

Signed and notarized release artifacts can pass normal Gatekeeper checks. A local or fallback ad-hoc build can still show a Gatekeeper warning. Ad-hoc signing does not bypass Gatekeeper.

See [branding concepts](docs/BRANDING.md) for the editable source marks and the selected Orbit Bubble design.
