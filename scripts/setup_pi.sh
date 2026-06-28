#!/bin/bash
set -e
REBOOT_REQUIRED=false
KIO_RES=""

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

# 1. Authenticate sudo upfront
echo -e "${BLUE}--> Validating sudo credentials (you may be prompted for your password)...${NC}"
sudo -v

# 2. Install Gum first for beautiful UI
if ! command -v gum &> /dev/null; then
    echo -e "${BLUE}--> Installing Gum for progress spinners and prompts...${NC}"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update > /dev/null
    sudo apt-get install -y gum > /dev/null
fi

# Clear screen and show header early
clear
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    "InfoHotel Kiosk Setup" "Raspberry Pi Environment"

# 3. Update system and install kiosk dependencies using Gum spinner
gum spin --spinner dot --title "Updating package lists..." -- sudo apt-get update -y
gum spin --spinner dot --title "Installing dependencies (curl, unzip, xz-utils, zip, python3, cage, cog, wlr-randr)..." -- sudo apt-get install -y curl unzip xz-utils zip python3 cage cog wlr-randr

echo -e "${BLUE}--> Configuring hardware permissions for $USER...${NC}"
sudo usermod -a -G video,render,tty,input $USER

echo ""
# Configure Screen Resolution
if gum confirm "Do you want to configure a custom screen resolution for the kiosk?"; then
    # 1. Locate cmdline.txt
    if [ -f "/boot/firmware/cmdline.txt" ]; then
        CMDLINE="/boot/firmware/cmdline.txt"
    elif [ -f "/boot/cmdline.txt" ]; then
        CMDLINE="/boot/cmdline.txt"
    else
        gum style --foreground 196 "Error: cmdline.txt not found!"
        exit 1
    fi

    # 2. Detect active connector
    CONNECTOR=""
    for f in /sys/class/drm/*/status; do
        if [ "$(cat "$f")" = "connected" ]; then
            con=$(basename "$(dirname "$f")")
            CONNECTOR="${con#*-}"
            break
        fi
    done

    if [ -z "$CONNECTOR" ]; then
        gum style --foreground 196 "Error: No active display connector detected!"
    else
        gum style --foreground 212 "Detected active display connector: $CONNECTOR"
        KIO_RES=$(gum input --placeholder "Enter resolution (e.g., 1280x720, 800x480)" --value "1280x720" --header "Kiosk Resolution:")
        
        if [[ "$KIO_RES" =~ ^[0-9]+x[0-9]+$ ]]; then
            # Read, clean up existing video configs to avoid duplicates, and prepend the new one
            CONTENT=$(cat "$CMDLINE")
            CLEANED_CONTENT=$(echo "$CONTENT" | sed -E 's/\bvideo=[^ ]+ //g' | sed -E 's/\bvideo=[^ ]+$//g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            NEW_LINE="video=${CONNECTOR}:${KIO_RES}@60D ${CLEANED_CONTENT}"

            # Write back to file safely
            echo -n "$NEW_LINE" | sudo tee "$CMDLINE" > /dev/null
            gum style --foreground 72 "    ✓ Resolution configured to ${KIO_RES} on ${CONNECTOR} in ${CMDLINE}."
            REBOOT_REQUIRED=true
        else
            KIO_RES=""
            gum style --foreground 196 "Invalid resolution format. Skipping configuration."
        fi
    fi
fi

gum style --foreground 212 -- "--> Configuring systemd service to start at boot..."
sudo tee /etc/systemd/system/infohotel.service > /dev/null << EOF
[Unit]
Description=InfoHotel Kiosk Service
After=systemd-user-sessions.service plymouth-quit-wait.service network.target systemd-logind.service
Wants=systemd-logind.service
Conflicts=getty@tty1.service

[Service]
User=$USER
Group=$USER
SupplementaryGroups=video render tty input
PAMName=login
TTYPath=/dev/tty1
StandardInput=tty-fail
StandardOutput=journal
StandardError=journal
Environment=HOME=$HOME
Environment=KIO_RES=$KIO_RES
WorkingDirectory=$HOME/infoHotel
ExecStart=$HOME/infoHotel/scripts/launch_kiosk.sh
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
gum style --foreground 72 "Tip: You can manually test changing the resolution by running:"
gum style --foreground 15 "export XDG_RUNTIME_DIR=/run/user/1000 && export WAYLAND_DISPLAY=wayland-0 && wlr-randr --output HDMI-A-1 --mode 1280x720"
echo ""

if [ "$REBOOT_REQUIRED" = true ]; then
    if gum confirm "A reboot is required to apply the resolution changes. Reboot now?"; then
        echo "Rebooting..."
        sudo reboot
    fi
fi
