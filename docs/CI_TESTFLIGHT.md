# Replicaz — GitHub Actions → TestFlight

Automated iOS TestFlight deploy, aligned with **ClipVal** (`yky32/clipvault-app`) / Triftly.

## Flow

```
push to main  →  Deploy workflow
  1. flutter pub get + pod install
  2. Import Apple Distribution .p12 (secret)
  3. Fetch/create App Store profile for com.replicaz.replicaz
  4. Bump pubspec build number, commit + push [skip ci]
  5. flutter build ipa (manual signing)
  6. upload_to_testflight (ASC API key)
```

Manual: **Actions → Deploy → Run workflow**

## Required GitHub secrets

Repo: **https://github.com/yky32/replicaz-app/settings/secrets/actions**

Copy the **same values** from ClipVal / Triftly (Apple team `3G34999H3A`):

| Secret | Purpose |
|--------|---------|
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | `.p8` private key body |
| `IOS_DISTRIBUTION_CERT_BASE64` | Base64 of Apple Distribution `.p12` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | Password for that `.p12` |
| `GH_PAT` | (Recommended) PAT with `repo` for build-number push |

Optional: `APP_STORE_CONNECT_API_KEY_IS_BASE64=true` if the p8 secret is base64-encoded.

## App Store Connect checklist

1. App ID: **`com.replicaz.replicaz`**
2. App record: **Replicaz** with that bundle (or first CI can try `create_app`)
3. Team: **3G34999H3A** (Xcode `DEVELOPMENT_TEAM` aligned)

## Local TestFlight

```bash
./ios/install_gems_and_pods.sh
./scripts/testflight.sh
# or
cd ios && bundle exec fastlane ios upload_testflight
```

## Product note

Replicaz messaging needs a **reachable backend** (not `127.0.0.1`) for TF demos.
Release `dart-define` / staging URLs are a separate follow-up.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Missing secrets | Copy from clipvault-app |
| App not found | Create Replicaz in ASC with `com.replicaz.replicaz` |
| 90186 / 90062 | Fastlane auto-bumps marketing version |
| Build number conflict | Re-run Deploy |
