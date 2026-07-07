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

gum spin --spinner dot --title "Packaging web and backend folders..." -- bash -c "tar -czf $OUTPUT_ARCHIVE build/web/ backend/"

# 4. Upload to a temporary hosting service
echo "Uploading to transfer.sh for easy transfer..."
if curl -s --upload-file "$OUTPUT_ARCHIVE" "https://transfer.sh/$OUTPUT_ARCHIVE" > .transfer_url; then
    DOWNLOAD_URL=$(cat .transfer_url)
    rm -f .transfer_url

    echo ""
    gum style \
        --foreground 212 --border-foreground 212 --border normal \
        --margin "1 0" --padding "1 2" \
        "Done! The release is packaged and uploaded."

    echo "Copy and paste this exact snippet into your Raspberry Pi Connect terminal:"
    echo ""
    gum style --foreground 15 --background 0 --padding "1 2" "wget $DOWNLOAD_URL -O $OUTPUT_ARCHIVE
mkdir -p ~/infoHotel
tar -xzf $OUTPUT_ARCHIVE -C ~/infoHotel
sudo systemctl restart infohotel.service"

else
    rm -f .transfer_url
    echo ""
    gum style \
        --foreground 196 --border-foreground 196 --border normal \
        --margin "1 0" --padding "1 2" \
        "Upload failed! (transfer.sh might be down)"

    echo "No problem! We'll use your local network instead."
    echo "1. On this computer, start a local server by running:  python3 -m http.server 8080"
    echo "2. Find this computer's local IP address (e.g. 192.168.1.X)."
    echo "3. Copy and paste this exact snippet into your Raspberry Pi Connect terminal:"
    echo ""
    gum style --foreground 15 --background 0 --padding "1 2" "wget http://YOUR_PC_IP:8080/$OUTPUT_ARCHIVE -O $OUTPUT_ARCHIVE
mkdir -p ~/infoHotel
tar -xzf $OUTPUT_ARCHIVE -C ~/infoHotel
sudo systemctl restart infohotel.service"
fi

echo ""
gum style --foreground 72 "This will replace the web files and automatically restart Cage and Cog!"
echo ""
