import subprocess
import os
import json

def handle_open_terminal(handler):
    """
    Handles POST /api/openTerminal request.
    Spawns a system terminal process under the active Wayland or X display.
    """
    env = os.environ.copy()
    
    # Ensure standard Wayland / X display environment variables are present
    if 'XDG_RUNTIME_DIR' not in env:
        try:
            uid = os.getuid()
            env['XDG_RUNTIME_DIR'] = f'/run/user/{uid}'
        except Exception:
            pass

    if 'WAYLAND_DISPLAY' not in env:
        env['WAYLAND_DISPLAY'] = 'wayland-0'

    if 'DISPLAY' not in env:
        env['DISPLAY'] = ':0'

    terminals = [
        'x-terminal-emulator',
        'lxterminal',
        'foot',
        'kitty',
        'alacritty',
        'gnome-terminal',
        'xfce4-terminal',
        'xterm'
    ]

    launched = False
    last_error = ""

    for term in terminals:
        try:
            subprocess.Popen([term], env=env)
            launched = True
            print(f"[api_system] Successfully launched terminal emulator: {term}", flush=True)
            break
        except FileNotFoundError:
            continue
        except Exception as e:
            last_error = str(e)
            print(f"[api_system] Failed to launch {term}: {e}", flush=True)
            continue

    if launched:
        response_data = json.dumps({"status": "ok", "message": "Terminal launched"}).encode('utf-8')
        handler.send_response(200)
        handler.send_header('Content-Type', 'application/json')
        handler.send_header('Content-Length', str(len(response_data)))
        handler.end_headers()
        handler.wfile.write(response_data)
    else:
        err_msg = f"No terminal emulator available. {last_error}".strip()
        response_data = json.dumps({"status": "error", "message": err_msg}).encode('utf-8')
        handler.send_response(500)
        handler.send_header('Content-Type', 'application/json')
        handler.send_header('Content-Length', str(len(response_data)))
        handler.end_headers()
        handler.wfile.write(response_data)
