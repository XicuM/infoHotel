#!/bin/bash
exec >&2

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    echo "Please transfer the build using the build_for_pi.sh script on your PC."
    exit 1
fi

echo "Starting modular backend server on port $PORT..."
export PYTHONPATH="$HOME/infoHotel"
python3 -m backend.server $PORT "$WEB_DIR" &

echo "Initializing Cage + Cog Kiosk Display..."

# Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
# Clean up any stale Wayland socket from a previous run to ensure the wait loop triggers correctly
rm -f "$XDG_RUNTIME_DIR/wayland-0" "$XDG_RUNTIME_DIR/wayland-0.lock"
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1

# Enable remote Web Inspector for debugging (access at http://<pi-ip>:8081)
export WEBKIT_INSPECTOR_SERVER=0.0.0.0:8081

# Prevent wlroots/cage from crashing if no mouse or keyboard is plugged in
export WLR_LIBINPUT_NO_DEVICES=1

# Disable the WebKit sandbox to fix the 'bwrap' / 'dbus-proxy' crash on Raspbian
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
export WPE_DISABLE_SANDBOX=1

# Force WebGL and ignore GPU blacklists which often block the Pi 3B+
export WEBKIT_IGNORE_GPU_BLACKLIST=1
export WEBKIT_FORCE_COMPOSITING_MODE=1
export COG_USE_WEBGL=1
export WPE_DRM_DEVICE=/dev/dri/card0
export WPE_DRM_RENDER_NODE=/dev/dri/renderD128

# Execute cage as the main process, allowing logs to flow directly to systemd journal
# You can set the COG_SCALE environment variable (e.g. export COG_SCALE=1.25) to scale the UI.
# You can set the KIO_RES environment variable (e.g. export KIO_RES=1280x720) to change the display resolution.

if [ -n "$KIO_RES" ]; then
    (
        # Wait for the Wayland compositor socket to be initialized
        while [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; do
            sleep 0.5
        done
        export WAYLAND_DISPLAY=wayland-0
        
        # Wait for outputs to populate in wlroots
        sleep 2
        
        echo "=== Display diagnostic logs ==="
        wlr-randr || echo "wlr-randr failed to run!"
        echo "==============================="
        
        # Find the active display connector name (e.g. HDMI-A-1 or DSI-1)
        CONNECTOR=$(wlr-randr | grep -m1 '^[A-Za-z0-9-]' | awk '{print $1}')
        
        if [ -n "$CONNECTOR" ]; then
            echo "Applying resolution ${KIO_RES} to output ${CONNECTOR}..."
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}@60.000000Hz" || \
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}@60Hz" || \
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}" || \
            echo "Failed to set resolution with wlr-randr"
        fi
    ) 2>&1 &
fi

cage -d -- cog --platform=fdo --scale="${COG_SCALE:-1.0}" http://localhost:$PORT
