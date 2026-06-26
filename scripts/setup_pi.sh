#!/bin/bash
set -e

RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== InfoHotel Pi Kiosk Setup ===${NC}"
echo ""

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}ERROR: Do not run this script with sudo. Run it as your normal user.${NC}"
  echo -e "${RED}The script will ask for your password when sudo is needed.${NC}"
  exit 1
fi

# 1. Update system and install dependencies
echo -e "${BLUE}--> Installing dependencies (you may be prompted for your sudo password)...${NC}"
sudo apt-get update > /dev/null
sudo apt-get install -y curl unzip xz-utils zip python3 cage cog > /dev/null

# Install Gum for beautiful CLI prompts
if ! command -v gum &> /dev/null; then
    echo -e "${BLUE}--> Installing Gum for a beautiful CLI...${NC}"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update > /dev/null
    sudo apt-get install -y gum > /dev/null
fi

# Clear the screen and show a beautiful header now that gum is installed
clear
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    "InfoHotel Kiosk Setup" "Raspberry Pi Environment"

gum style --foreground 212 -- "--> Creating kiosk launch script (~/launch_kiosk.sh)..."
cd ~
cat << 'EOF' > launch_kiosk.sh
#!/bin/bash

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    echo "Please transfer the build using the build_for_pi.sh script on your PC."
    exit 1
fi

echo "Starting micro-webserver on port $PORT..."
python3 -m http.server $PORT --directory "$WEB_DIR" > /dev/null 2>&1 &
SERVER_PID=$!

trap "kill $SERVER_PID" EXIT

echo "Initializing Cage + Cog Kiosk Display..."

# Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-0
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1

exec cage -- cog --kiosk http://localhost:$PORT
EOF

chmod +x launch_kiosk.sh
gum style --foreground 72 "    ✓ Launch script created."

echo ""
gum style --foreground 212 -- "--> Configuring systemd service to start at boot..."
sudo tee /etc/systemd/system/infohotel.service > /dev/null << EOF
[Unit]
Description=InfoHotel Kiosk Service
After=systemd-user-sessions.service plymouth-quit-wait.service network.target
Conflicts=getty@tty1.service

[Service]
User=$USER
Group=$USER
PAMName=login
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
Environment=HOME=$HOME
WorkingDirectory=$HOME
ExecStart=$HOME/launch_kiosk.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable infohotel.service > /dev/null 2>&1
gum style --foreground 72 "    ✓ Service registered and enabled."

echo ""
gum style \
    --foreground 72 --border double --border-foreground 72 \
    --align center --margin "1 2" --padding "1 2" \
    "Setup Complete!" \
    "Your Pi is now ready to receive the app."

gum style --foreground 212 "Next steps:"
gum style --foreground 15 "1. On your MAIN COMPUTER, run: ./scripts/build_for_pi.sh"
gum style --foreground 15 "2. Paste the provided command into this Raspberry Pi Connect terminal."
gum style --foreground 15 "3. The kiosk will automatically launch!"
echo ""
