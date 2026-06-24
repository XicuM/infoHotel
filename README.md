# InfoHotel Kiosk Application

A hotel information kiosk application for the Ses Savines Arenal tourist complex, built with Flutter.

## Features
- Immersive Kiosk Mode support
- Multi-language support (English, Spanish, German, French, Italian, Dutch)
- Real-time weather integration via AEMET OpenData API
- Information directory for services, excursions, markets, and webpages
- Portable data loading strategy

## Requirements
- Flutter SDK `^3.10.1`
- An AEMET OpenData API Key

## Getting Started

1. **Install Dependencies**
   Run the following command to download project dependencies:
   ```bash
   flutter pub get
   ```

2. **Configuration**
   The application requires an AEMET OpenData API Key for real-time weather information. 
   You must provide the API key at compile time using the `--dart-define` flag.

   *Development Run:*
   ```bash
   flutter run --dart-define=AEMET_API_KEY=your_aemet_api_key_here
   ```

   *Production Build (e.g., Linux Desktop):*
   ```bash
   flutter build linux --dart-define=AEMET_API_KEY=your_aemet_api_key_here
   ```

3. **Kiosk Interactions**
   - **F11**: Toggle Fullscreen Kiosk Mode.
   - **F2**: Toggle Content Edit Mode (allows managing excursions and market data).
   - **F1**: Toggle Help Overlay.
   - **Alt + A**: Switch view to 'Arenal' hotel layout.
   - **Alt + S**: Switch view to 'Savines' hotel layout.

## Project Structure
- `lib/config`: Theming, environment variables, and constants.
- `lib/services`: State management, business logic, and API calls.
- `lib/views`: UI layout screens and modular widgets.
- `assets/`: Contains application images, PDF resources, and local default JSON data.

## Deployment Notes
When deploying the compiled application, the app looks for a directory named `infohotel_data` placed next to the executable. This folder is used to read and update mutable content (like excursions and markets) on the fly without needing to recompile the app. If it is not found, the app defaults to the system's Document directory.
