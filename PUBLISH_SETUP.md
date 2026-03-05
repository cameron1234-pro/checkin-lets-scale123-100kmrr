# App Store Connect publish setup (Check In)

## What is already wired
- Fastlane lanes created in `fastlane/Fastfile`
- Metadata scaffold in `fastlane/metadata/en-US/*`
- App identifier set to `com.checkin.mobile`

## One-time requirements
1. App Store Connect API key (`.p8`)
   - App Store Connect → Users and Access → Keys → Generate API Key
   - Role: App Manager (or Admin)
2. Key values in `fastlane/.env`:
   - `ASC_KEY_ID`
   - `ASC_ISSUER_ID`
   - `ASC_KEY_PATH`
3. Xcode iOS platform installed (required for archive/screenshots):
   ```bash
   xcodebuild -downloadPlatform iOS
   ```

## Local setup
```bash
cd "/Users/camerondorseyproservices/.openclaw/workspace/check in"
cp fastlane/.env.example fastlane/.env
# fill ASC_* values
```

## Validate App Store Connect connection
```bash
fastlane ios asc_check
```

## Upload metadata (no screenshots, no binary)
```bash
fastlane ios metadata_only
```

## Upload screenshots only
Place screenshots under:
- `fastlane/screenshots/en-US/`

Then run:
```bash
fastlane ios screenshots_only
```

## Build + upload TestFlight binary
```bash
fastlane ios upload_testflight
```

## Prepare release metadata for current version
```bash
fastlane ios prep_release
```

## Final manual submit
Open App Store Connect → your app → version page → complete any missing review fields → **Submit for Review**.

## Notes
- `fastlane ios upload_testflight` replaces the old `testflight` lane name.
- If Fastlane returns a first-version `No data` error, create/open the version in App Store Connect once, save, then rerun `prep_release`.
- If `bundle exec fastlane` fails due local Bundler mismatch, run `fastlane ...` directly (Homebrew fastlane) as a fallback.
