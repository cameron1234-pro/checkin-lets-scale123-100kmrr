fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios asc_check

```sh
[bundle exec] fastlane ios asc_check
```

Validate App Store Connect auth + app access

### ios metadata_only

```sh
[bundle exec] fastlane ios metadata_only
```

Upload metadata only (no binary, no screenshots)

### ios screenshots_only

```sh
[bundle exec] fastlane ios screenshots_only
```

Upload screenshots only (no binary, no metadata)

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Build + upload to TestFlight

### ios prep_release

```sh
[bundle exec] fastlane ios prep_release
```

Prepare App Store version metadata (manual Submit in App Store Connect)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
