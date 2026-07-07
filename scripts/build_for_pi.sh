#!/bin/bash
set -e

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "Please install gum to use this script nicely! (https://github.com/charmbracelet/gum)"
    echo "Fallback to basic script..."
    exit 1
fi

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 60 --margin "1 2" --padding "1 2" \
	"InfoHotel Web Build" "for Raspberry Pi Kiosk"

# Helper function to read from .env
get_env() {
    if [[ -f ".env" ]]; then
        grep -m 1 "$1" .env | cut -d '=' -f 2- | tr -d '"' | tr -d "'"
    fi
}

# 1. Gather API Keys
API_KEY=""
FLIGHT_KEY=""
BUS_KEY=""

if [ -f ".env" ]; then
    gum style --foreground 72 "Found .env file. Loading API keys..."
    API_KEY=$(get_env "AEMET_API_KEY")
    FLIGHT_KEY=$(get_env "FLIGHT_API_KEY")
    if [ -z "$FLIGHT_KEY" ]; then
        FLIGHT_KEY=$(get_env "FIGHT_API_KEY") # Typo fallback
    fi
    BUS_KEY=$(get_env "BUS_API_KEY")
fi

# Fallbacks to user input if keys are missing
while [ -z "$API_KEY" ]; do
    API_KEY=$(gum input --placeholder "Enter your AEMET API Key (or type 'skip' to skip)" --header "AEMET Weather API Key:")
done
if [ "$API_KEY" = "skip" ]; then
    API_KEY=""
fi

while [ -z "$FLIGHT_KEY" ]; do
    FLIGHT_KEY=$(gum input --placeholder "Enter your RapidAPI Key (or type 'skip' to skip)" --header "RapidAPI Flight Key:")
done
if [ "$FLIGHT_KEY" = "skip" ]; then
    FLIGHT_KEY=""
fi

while [ -z "$BUS_KEY" ]; do
    BUS_KEY=$(gum input --placeholder "Enter your Bus API Key (or type 'skip' to skip)" --header "Bus API Key:")
done
if [ "$BUS_KEY" = "skip" ] || [ "$BUS_KEY" = "your_bus_api_key_here" ]; then
    BUS_KEY=""
fi

BUILD_ARGS="--release"
if [ -n "$API_KEY" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=AEMET_API_KEY=\"$API_KEY\""
fi
if [ -n "$FLIGHT_KEY" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=FLIGHT_API_KEY=\"$FLIGHT_KEY\""
fi
if [ -n "$BUS_KEY" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=BUS_API_KEY=\"$BUS_KEY\""
fi

# 2. Build the Web App
gum style --foreground 212 -- "--> Starting Flutter web build (this will take a minute)..."
if ! eval flutter build web $BUILD_ARGS; then
    gum style --foreground 196 "Error: Flutter web build failed! Check the logs above."
    exit 1
fi
gum style --foreground 72 "Build successful!"

# 3. Package the Output
OUTPUT_ARCHIVE="infoHotel_web_kiosk.tar.gz"
rm -f "$OUTPUT_ARCHIVE"

gum spin --spinner dot --title "Packaging web and backend folders..." -- bash -c "tar -czf $OUTPUT_ARCHIVE build/web/ backend/ hotel_assets/"

# 4. Host locally via secure tunnel
echo "Starting local HTTP server on port 8080..."
python3 -m http.server 8080 > /dev/null 2>&1 &
SERVER_PID=$!

echo "Starting secure tunnel via localhost.run..."
rm -f .tunnel.log
ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 nokey@localhost.run > .tunnel.log 2>&1 &
TUNNEL_PID=$!

# Ensure we clean up background processes when the script exits (e.g. user presses Ctrl+C)
trap "kill $SERVER_PID $TUNNEL_PID 2>/dev/null; rm -f .tunnel.log" EXIT

# Wait for the tunnel URL to appear in the log
gum spin --spinner dot --title "Waiting for tunnel URL..." -- bash -c 'while ! grep -q "tunneled with tls termination" .tunnel.log; do sleep 1; done'

TUNNEL_URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.lhr\.life' .tunnel.log | head -n 1)

echo ""
gum style \
    --foreground 212 --border-foreground 212 --border normal \
    --margin "1 0" --padding "1 2" \
    "Done! Secure tunnel established."

echo "Copy and paste this exact snippet into your Raspberry Pi Connect terminal:"
echo ""
gum style --foreground 15 --background 0 --padding "1 2" "wget $TUNNEL_URL/$OUTPUT_ARCHIVE -O $OUTPUT_ARCHIVE
mkdir -p ~/infoHotel
tar -xzf $OUTPUT_ARCHIVE -C ~/infoHotel
sudo systemctl restart infohotel.service"

echo ""
gum style --foreground 196 "The server is running in the background."
gum style --foreground 72 "Press Ctrl+C to close the server once the download finishes."
echo ""

# Wait infinitely until the user presses Ctrl+C
wait $TUNNEL_PID

echo ""
gum style --foreground 72 "This will replace the web files and automatically restart Cage and Cog!"
echo ""
