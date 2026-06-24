#!/bin/bash

echo "=== infoHotel Setup ==="

# 0. Safety Check
if [ "$EUID" -eq 0 ]; then
  echo "ERROR: Do not run this script with sudo. Run it as your normal user."
  echo "The script will ask for your password when sudo is needed."
  exit 1
fi

# 1. Update system and install Linux UI dependencies
echo "--> Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

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
    git clone git@github.com:XicuM/infoHotel.git
    git submodule update --init --recursive
else
    echo "--> infoHotel already exists, pulling latest..."
    cd infoHotel
    git pull
fi

# 5. Build the application
echo "--> Building infoHotel application (this will take a while)..."
cd ~/infoHotel

flutter config --enable-linux-desktop
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

if [ -n "$API_KEY" ]; then
    echo "--> Building with AEMET API key..."
    flutter build linux --release --dart-define=AEMET_API_KEY="$API_KEY"
else
    echo "--> Building without AEMET API key (weather will be disabled)..."
    flutter build linux --release
fi

# 6. Create a smart launch script and desktop icon
echo "--> Creating launcher and desktop icon..."
cd ~
cat << 'EOF' > run_hotel.sh
#!/bin/bash
# Try to find the executable
APP_PATH=$(find $HOME/infoHotel -name "info_hotel" -type f | grep "release/bundle" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Could not find the compiled app. Did the build fail?"
    exit 1
fi

echo "Starting infoHotel..."
# Force Mesa to expose OpenGL 3.3 to Flutter so it doesn't crash on glBlitFramebuffer
# This tricks the Pi 3 GPU into accelerating what it can, rather than falling back entirely to CPU software rendering.
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330

GDK_BACKEND=x11 "$APP_PATH" || LIBGL_ALWAYS_SOFTWARE=1 "$APP_PATH"
EOF

chmod +x run_hotel.sh

mkdir -p ~/.local/share/applications
mkdir -p ~/Desktop
cat << EOF > ~/.local/share/applications/infohotel.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=InfoHotel Kiosk
Comment=Hotel Information Kiosk Application
Exec=$HOME/run_hotel.sh
Icon=utilities-terminal
Terminal=false
Categories=Utility;Application;
EOF
cp ~/.local/share/applications/infohotel.desktop ~/Desktop/
chmod +x ~/Desktop/infohotel.desktop

echo "=== Setup Complete! ==="
echo "You can now run your app by clicking the desktop icon or typing: ./run_hotel.sh"
