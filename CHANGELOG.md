# Changelog

## [1.0.0] – 2026-11-14

First coursework release.

### Added
- SQLite storage with `sqflite`: a `health_records` table and a `user_goals` table created in `onCreate` (schema version 1), with 14 days of sample data on first launch.
- Full CRUD for health records, with inline validation and an undo after delete.
- Search by date: today, last 7 days, a picked date or a date range, sorted newest or oldest first.
- Dashboard showing today's totals, goal rings, a daily score, one-tap water logging and a 7-day chart.
- Settings to change daily goals, reload the sample data or delete all records.
- Provider `ChangeNotifier` view-models (feature-based MVVM).
- Material 3 interface with colour-coded metrics (steps green, calories red, water blue).
- 51 unit and widget tests that run the real SQL on an in-memory SQLite database (`sqflite_common_ffi`).
- Launcher icons for Android (adaptive and monochrome) and iOS, and release signing through a git-ignored `key.properties`.
