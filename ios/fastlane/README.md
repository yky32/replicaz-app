# Replicaz Fastlane

Patterned after **ClipVal** (`clipvault-app`) / Triftly — Flutter IPA → TestFlight.

## Lanes

| Lane | Purpose |
|------|---------|
| `ios build_debug` | Debug, no codesign |
| `ios build_release` | Release, no codesign |
| `ios build_ipa` | IPA (`export_method: app-store` for TF) |
| `ios setup_appstore_signing` | Distribution cert + profile |
| `ios upload_testflight` | Bump build + IPA + pilot |
| `ios create_app` | Register ASC app if missing |
| `ios clean` | flutter clean + wipe Pods |

## Local

```bash
./ios/install_gems_and_pods.sh
cd ios && bundle exec fastlane ios upload_testflight
# or
./scripts/testflight.sh
```

## Identifiers

| | |
|--|--|
| Bundle | `com.replicaz` |
| Team | `3G34999H3A` (same as ClipVal TF certs) |
| App name | Replicaz |

No Widget/Share extensions — simpler than ClipVal.

## CI

See `docs/CI_TESTFLIGHT.md` and `.github/workflows/deploy.yml`.
