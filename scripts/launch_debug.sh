#!/usr/bin/env bash

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed."
    echo "Please install it first (e.g., sudo apt install gum / brew install gum)"
    echo "Instructions: https://github.com/charmbracelet/gum#installation"
    exit 1
fi

clear

# Title
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    "InfoHotel Debug Launcher"

DART_DEFINES=""

# Helper function to read from .env
get_env() {
    if [[ -f ".env" ]]; then
        grep -m 1 "$1" .env | cut -d '=' -f 2- | tr -d '"' | tr -d "'"
    fi
}

# 1. AEMET API
if gum confirm "Enable Weather API (AEMET)?"; then
    if [[ -f ".env" ]]; then
        AEMET_KEY=$(get_env "AEMET_API_KEY")
        if [[ -n "$AEMET_KEY" ]]; then
            gum style --foreground 46 " ✓ AEMET API Key loaded."
            DART_DEFINES="$DART_DEFINES --dart-define=AEMET_API_KEY=$AEMET_KEY"
        else
            gum style --foreground 220 " ⚠ AEMET_API_KEY not found in .env"
        fi
    else
        gum style --foreground 220 " ⚠ .env file not found."
    fi
else
    gum style --foreground 240 " ✗ Skipped AEMET API."
fi

echo ""



# 3. Bus API
if gum confirm "Enable Bus API (Ibiza GTFS)?"; then
    if [[ -f ".env" ]]; then
        BUS_KEY=$(get_env "BUS_API_KEY")
        
        if [[ -n "$BUS_KEY" && "$BUS_KEY" != "your_bus_api_key_here" ]]; then
            gum style --foreground 46 " ✓ Bus API Key loaded."
            DART_DEFINES="$DART_DEFINES --dart-define=BUS_API_KEY=$BUS_KEY"
        elif [[ "$BUS_KEY" == "your_bus_api_key_here" ]]; then
            gum style --foreground 220 " ⚠ Bus API Key is still the placeholder value in .env"
        else
            gum style --foreground 220 " ⚠ Bus API Key not found in .env"
        fi
    else
        gum style --foreground 220 " ⚠ .env file not found."
    fi
else
    gum style --foreground 240 " ✗ Skipped Bus API."
fi

echo ""

# 4. Device Selection
gum style --foreground 99 "➜ Select the target device for debugging:"
TARGET=$(gum choose "web-server" "linux" "chrome")
gum style --foreground 46 " ✓ Selected: $TARGET"
echo ""

# 5. Start Development Proxy
gum style --foreground 99 "➜ Starting proxy server..."

# Kill any existing process on port 8080
kill -9 $(lsof -t -i:8080) 2>/dev/null || true

export PYTHONPATH="$PWD"
python3 -m backend.server 8080 &
PROXY_PID=$!

gum style --foreground 46 " ✓ Proxy Server running in background (PID: $PROXY_PID)"

DART_DEFINES="$DART_DEFINES --dart-define=PROXY_URL=http://localhost:8080"

# Ensure the proxy server is killed when the script exits
cleanup() {
    echo ""
    gum style --foreground 220 "Shutting down proxy server (PID: $PROXY_PID)..."
    kill $PROXY_PID 2>/dev/null
    exit 0
}
trap cleanup EXIT SIGINT SIGTERM

echo ""

# 6. Start Flutter App
gum style --foreground 99 "➜ Launching Flutter App..."
gum style --foreground 240 "Running: flutter run -d $TARGET $DART_DEFINES"
echo ""

flutter run -d $TARGET $DART_DEFINES
