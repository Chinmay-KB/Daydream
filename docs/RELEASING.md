# Releasing Daydream

The release workflow runs when you push a tag with this exact form:

```text
vMAJOR.MINOR.PATCH
```

For example:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow rejects tags that do not have three numeric version parts.

## Required GitHub secrets for a signed and notarized release

Set all of these repository secrets before you push a release tag.

- `DEVELOPER_ID_APPLICATION` is the Developer ID Application signing identity.
- `DEVELOPER_ID_APPLICATION_P12_BASE64` is the base64-encoded Developer ID Application `.p12` file.
- `DEVELOPER_ID_APPLICATION_P12_PASSWORD` is the password for that `.p12` file.
- `APPLE_ID` is the Apple ID for notarization.
- `APPLE_TEAM_ID` is the Apple Developer team ID.
- `APPLE_APP_PASSWORD` is an app-specific password for notarization.

Do not put these values in the repository. The workflow fails when only part of this set is configured.

## Release flow

1. The workflow validates the tag.
2. It builds a universal `Daydream.app` for `arm64` and `x86_64`.
3. With all secrets set, it imports the certificate and Developer ID signs the app.
4. It creates a temporary ZIP, submits it for notarization, and staples the app.
5. It creates the final ZIP and DMG.
6. It Developer ID signs, notarizes, and staples the DMG.
7. It publishes the ZIP, DMG, and `SHA256SUMS.txt` to the GitHub Release.

With no release secrets, the workflow ad-hoc signs the app, creates the ZIP and DMG, and publishes them with a non-notarized warning. Ad-hoc signing does not bypass Gatekeeper.

## Local release checks

```bash
./scripts/build-app.sh v0.1.0
./scripts/sign-app.sh .build/Daydream-app/Daydream.app -
./scripts/create-dmg.sh .build/Daydream-app/Daydream.app .build/Daydream-v0.1.0.dmg
```

For notarization, submit a ZIP or DMG and name an app or DMG staple target:

```bash
APPLE_ID="..." APPLE_TEAM_ID="..." APPLE_APP_PASSWORD="..." \
  ./scripts/notarize.sh Daydream.zip .build/Daydream-app/Daydream.app
```

A reproducible build means that the documented steps can build the same source revision again. Signed and notarized artifacts are not byte-identical because their signatures and notarization data can differ.
