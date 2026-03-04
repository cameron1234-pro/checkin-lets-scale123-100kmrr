# App Store Connect publish setup (Check In)

## What is already wired
- Fastlane lanes created in `fastlane/Fastfile`
- Metadata scaffold created in `fastlane/metadata/en-US/*`
- App identifier set to `com.promatchusa.app.check-in`

## One-time requirements from you
1. App Store Connect API key (`.p8`)
   - App Store Connect → Users and Access → Keys → Generate API Key
   - Role: App Manager (or Admin)
2. Key values:
   - `ASC_KEY_ID`
   - `ASC_ISSUER_ID`
   - path to `.p8` file (`ASC_KEY_PATH`)
3. Xcode full app install + selection:
   - `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Local setup commands
```bash
cd "/Users/camerondorseyproservices/.openclaw/workspace/check in"
bundle install
cp fastlane/.env.example fastlane/.env
# edit fastlane/.env and fill the key vars
```

## Validate App Store Connect connection
```bash
bundle exec fastlane ios asc_check
```

## Push metadata to App Store Connect (no submit yet)
```bash
bundle exec fastlane ios prep_release
```

## Build + upload to TestFlight
```bash
bundle exec fastlane ios testflight
```

## Final step (manual)
Open App Store Connect and press **Submit for Review**.

## Notes
- You can update app text in `fastlane/metadata/en-US/` anytime.
- Screenshots should be placed under `fastlane/screenshots/` (optional, but recommended).
