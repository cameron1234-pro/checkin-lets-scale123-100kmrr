# Check In Native Parity Migration (In Progress)

## Goal
Remove Lovable runtime dependency and ship full Check In branded native app parity.

## Current state
- `ContentView.swift` currently uses a Lovable WebView shell.
- TestFlight upload pipeline is working.

## Workstream
1. Replace WebView shell with native branded auth + tabs.
2. Keep pairing deep-link flow (`checkin://start?...`) active.
3. Match key Lovable flows in native views:
   - Auth
   - Home
   - Check-Ins
   - SOS
   - Profile
4. Preserve monetization/pairing hooks.
5. Rebuild, verify screenshots, upload TestFlight.

## Progress log
- Started native reversion pass: restoring branded native screen architecture now.
