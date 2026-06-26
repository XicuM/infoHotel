#!/bin/bash

echo "=== infoHotel Setup ==="

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo "ERROR: Do not run this script with sudo. Run it as your normal user."
  echo "The script will ask for your password when sudo is needed."
  exit 1
fi

# 1. Update system and install dependencies for Web and Wayland Kiosk
echo "--> Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip python3 cage cog

# 2. Install the newest Stable Flutter
if ! command -v flutter &> /dev/null; then
    echo "--> Installing Flutter..."
    cd ~
    git clone https://github.com/flutter/flutter.git -b stable
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    export PATH="$PATH:$HOME/flutter/bin"
    flutter precache
else
    echo "--> Flutter is already installed."
fi

# 3. Handle GitHub SSH Keys
echo "--> Checking GitHub SSH setup..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "No SSH key found. Generating one now..."
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

echo ""
echo "=========================================================="
echo "ACTION REQUIRED: Add this SSH key to your GitHub account!"
echo "=========================================================="
echo ""
cat ~/.ssh/id_ed25519.pub
echo ""
echo "1. Copy the SSH key above (starting with ssh-ed25519)."
echo "2. Go to: https://github.com/settings/keys"
echo "3. Click 'New SSH key', paste it in, and save."
echo "=========================================================="
read -p "Press [Enter] ONLY after you have added the key to GitHub..."

# Trust GitHub's host key automatically so it doesn't prompt the user
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null

# 4. Clone the infoHotel repository
echo "--> Downloading infoHotel..."
if [ ! -d "infoHotel" ]; then
    git clone --recurse-submodules git@github.com:XicuM/infoHotel.git
else
    echo "--> infoHotel already exists, pulling latest..."
    cd infoHotel
    git pull
    git submodule update --init --recursive
fi

# 5. Build the application
echo "--> Building infoHotel application (this will take a while)..."
cd ~/infoHotel

flutter config --enable-web
flutter clean
flutter pub get

API_KEY=""
if [ -f ".api" ]; then
    echo "Found .api file. Using it for AEMET API key..."
    API_KEY="$(cat .api)"
else
    echo ""
    echo "=========================================================="
    echo "AEMET Weather API Key is required for weather functionality."
    read -p "Please enter your AEMET API Key (or press Enter to skip): " API_KEY
    echo "=========================================================="
fi

FLIGHT_KEY=""
if [ -f ".flight_api" ]; then
    echo "Found .flight_api file. Using it for Flight API key..."
    FLIGHT_KEY="$(cat .flight_api)"
else
    echo ""
    echo "=========================================================="
    echo "RapidAPI Key is required for flight board functionality."
    read -p "Please enter your RapidAPI Key (or press Enter to skip): " FLIGHT_KEY
    echo "=========================================================="
fi

BUILD_ARGS="--release"

if [ -n "$API_KEY" ]; then
    echo "--> Adding AEMET API key to build..."
    BUILD_ARGS="$BUILD_ARGS --dart-define=AEMET_API_KEY=\"$API_KEY\""
else
    echo "--> No AEMET API key provided (weather will be disabled)."
fi

if [ -n "$FLIGHT_KEY" ]; then
    echo "--> Adding FLIGHT API key to build..."
    BUILD_ARGS="$BUILD_ARGS --dart-define=FLIGHT_API_KEY=\"$FLIGHT_KEY\""
else
    echo "--> No FLIGHT API key provided (flight board will be disabled)."
fi

echo "--> Running flutter build..."
eval flutter build web $BUILD_ARGS --web-renderer canvaskit

echo "--> Incorporating assets folder..."
mkdir -p build/web/assets
cp -r assets build/web/assets/

# 6. Create a smart launch script and desktop icon
echo "--> Creating kiosk launch script..."
cd ~
cat << 'EOF' > launch_kiosk.sh
#!/bin/bash

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    exit 1
fi

echo "Starting micro-webserver on port $PORT..."
python3 -m http.server $PORT --directory "$WEB_DIR" > /dev/null 2>&1 &
SERVER_PID=$!

trap "kill $SERVER_PID" EXIT

echo "Initializing Cage + Cog Kiosk Display..."

# 2. Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-0
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1

exec cage -- cog --kiosk http://localhost:$PORT
EOF

chmod +x launch_kiosk.sh

echo "--> Configuring systemd service to start at boot..."
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
sudo systemctl enable infohotel.service

echo "=== Setup Complete! ==="
echo "The InfoHotel kiosk has been configured to start automatically at boot."
echo "You can also start it manually now by running: sudo systemctl start infohotel.service"
