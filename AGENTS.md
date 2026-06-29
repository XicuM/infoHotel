# InfoHotel — Agent Guide

## Commands

| Purpose | Command |
|---|---|
| Dependencies | `flutter pub get` |
| Analyze | `flutter analyze` |
| Test | `flutter test` (2 test files) |
| Run (dev) | `flutter run --dart-define=AEMET_API_KEY=<key>` |
| Build Linux | `flutter build linux --dart-define=AEMET_API_KEY=<key>` |

No codegen / build_runner. No Flutter gen-l10n.

## Key Architecture

- **State**: Provider (`ChangeNotifierProvider` in `main.dart`). Four services: `HotelService`, `LanguageService`, `WeatherService`, `ContentService`.
- **L10n**: Custom `Translations` class in `lib/l10n/translations.dart` (7 langs: en, es, ca, fr, de, it, nl). Not ARB-based. Add entries to the `_translations` map.
- **pdfx**: Local override at `packages/pdfx` (see `dependency_overrides` in `pubspec.yaml`). Edits to the PDF viewer go there.
- **Data loading** (`ContentService`): Looks for `infohotel_data/` next to the executable, falls back to app documents directory. JSON files: `markets.json`, `shows.json`, `excursions.json`. Defaults baked into code if files missing.
- **Hotels**: Two layouts toggled via `HotelService` — `Savines` (default) and `Arenal`.
- **Theme**: Dark mode forced (`ThemeMode.dark`). Maps have an invert color filter in dark mode (`AppColors.darkMapFilter`).
- **Orientation**: Landscape locked, immersive sticky UI (kiosk).

## Keyboard Shortcuts

| Key | Action |
|---|---|
| F11 | Toggle fullscreen kiosk |
| F2 | Toggle edit mode (manage excursions/markets) |
| F1 | Toggle help overlay |
| Alt+A | Switch to Arenal layout |
| Alt+S | Switch to Savines layout |

## AEMET API

Key supplied at compile time via `--dart-define=AEMET_API_KEY=...`. Read in `lib/config/env.dart` via `String.fromEnvironment`. Municipality code `07046` (Sant Antoni de Portmany).

## Content Edit Mode

Press F2 to toggle. Allows adding/removing/editing excursions and markets via UI. Data persisted to `infohotel_data/` JSON files.

## Testing

- Tests under `test/`: `widget_test.dart` and `language_service_test.dart`.
- Weather service tests require live AEMET API and are not yet present.

## Temporary Scripts & Scratch Files

Do NOT create temporary scratch scripts or other files (such as `.py` scripts) in the root directory or anywhere in the workspace. Any temporary/scratch files must be placed in the designated conversation artifacts directory (under `<appDataDir>/brain/<conversation-id>/scratch/`).
