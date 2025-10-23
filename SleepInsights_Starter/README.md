# Sleep Insights Dashboard — Student Starter (Class 4)

## Build this today
- **Dashboard**: 7-day summary card (avg duration, avg midpoint, social jetlag, regularity, best/worst).
- **Charts**: Duration bars + midpoint overlay (Swift Charts or custom).
- **Consistency**: Rolling midpoint std dev and regularity %.
- **Recommendations**: 2–4 adaptive tips.
- **Privacy/Export**: Local-only policy, Export weekly CSV, Reset data.

## What we provided
- `SleepVM.swift` with summary/metrics helpers + demo loader + CSV export.
- `Models.swift` for types.
- `DemoData.swift` + `sleep_demo.json` (3 weeks of synthetic nights).
- View scaffolds with TODOs.

## Tips
- Newest nights come first. Reverse if your chart expects ascending.
- Use ContentUnavailableView for friendly empty states.
- Add VoiceOver labels to key values and bars/points.

## Milestone for submission
Screenshot or short screen recording showing:
- Dashboard card values
- Chart with duration + midpoint
- Consistency metrics visible
- At least one recommendation
- Export button present
