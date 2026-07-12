# InfoHotel — Agent Guide

## Development & Build
- **No codegen**: (No `build_runner`, no `gen-l10n`).
- **Target**: Raspberry Pi 3B+ kiosk (Wayland, `cage`/`cog` browser).
- **Commands**:
  - Dev: `flutter run --dart-define=AEMET_API_KEY=<k1> --dart-define=FLIGHT_API_KEY=<k2> --dart-define=BUS_API_KEY=<k3>`
  - Prod (Web): `flutter build web --dart-define=AEMET_API_KEY=<k1> --dart-define=FLIGHT_API_KEY=<k2> --dart-define=BUS_API_KEY=<k3>`
- **Testing**: `flutter test`. Live API tests correctly skip if keys are missing.

## Architecture & Data
- **State**: `Provider` (Services for Hotels, Language, Weather, Content, Markets, Excursions, Shows, Buses, etc.).
- **L10n**: Custom dictionary map in `lib/l10n/translations.dart` (en, es, ca, fr, de, it, nl).
- **Data (`StorageRepository`)**: Services load `markets.json`, `shows.json`, `excursions.json`, etc. from `infohotel_data/` dir (next to executable or app documents) or fall back to baked-in defaults.
- **Hotels**: Loaded from `hotels.json`. Multiple layouts supported via hotel switching.
- **Theme**: Forced `ThemeMode.dark`. Map images get inverted via `AppColors.darkMapFilter`. Landscape orientation locked.

## APIs
- **Weather (AEMET)**: Municipality `07046` (Sant Antoni de Portmany). Requires `AEMET_API_KEY`.
- **Flights (RapidAPI Aerodatabox)**: Requires `FLIGHT_API_KEY`.
- **Buses (Transportes NAP)**: GTFS data for hotel bus stops. Requires `BUS_API_KEY`.

## Keyboard Shortcuts
- **F11**: Fullscreen kiosk toggle.
- **F1**: Help overlay toggle.
- **F2**: Edit Mode toggle (UI to manage excursions/markets, saves to JSON).
- **Alt+T**: Cycle hotel layouts.

## Performance (Low Power Mode)
`AppConfig.lowPowerMode` defaults to `true` to ensure Raspberry Pi performance by:
- Replacing `BackdropFilter` GPU blurs with solid colors (`WebSafeBackdropFilter`).
- Disabling heavy `BoxShadow` blurs on cards, buttons, and app bars.
- Constraining `AppImage` decoding footprints via `cacheWidth`/`cacheHeight`.

## Agent Rules
- **pdfx overrides**: Edits to the PDF viewer go directly to `packages/pdfx` (local override).
- **Scratch Files**: Place temporary files ONLY in `<appDataDir>/brain/<conversation-id>/scratch/`. Never pollute the workspace root.
- **Version Control**: Update the application version in `pubspec.yaml` upon completing a task. Evaluate the change scope using Semantic Versioning (Major.Minor.Patch) and always increment the build number (+X).
- **Git Operations**: Automatically commit your changes with a descriptive message and push them to the remote repository after completing a task.
- **Privacy & Security**: Never leak real hotel information, API keys, or sensitive data in logs, commits, or responses.
