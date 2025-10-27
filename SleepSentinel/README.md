# SleepSentinel

A privacy-first sleep companion. Reads HealthKit sleep analysis, fuses optional on-device motion to fill gaps, and computes nightly and weekly consistency metrics.

## What it does

- Requests read access for `sleepAnalysis` with a simple explainer before the system sheet.
- Uses `HKObserverQuery` to learn about new data and `HKAnchoredObjectQuery` to fetch only deltas.
- Keeps a local cache in Documents as JSON, including the persisted query anchor.
- Computes per-night totals (in-bed, asleep), midpoint, and an efficiency proxy (asleep / in-bed).
- Computes weekly consistency: midpoint standard deviation, social jetlag, and a regularity index.
- Optional motion fusion suggests onset and wake around user targets. Marked as inferred.
- Offers a CSV export and a reset. No network features.

## Privacy

Data stays on device. Export is user-initiated. You can reset the cache at any time.

## Test plan

- No Watch data: zero state with optional inferred candidates.
- With Watch data: observer fires and anchored fetch returns only new samples.
- Time zone change: aggregates recompute on `NSCalendarDayChanged`.
- Permissions denied: onboarding remains with a retry path.

## Notes

Charts use SwiftUI drawing for wide iOS support. VoiceOver reads text labels for summary values and timeline rows.
