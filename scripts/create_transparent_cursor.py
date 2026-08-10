#!/usr/bin/env python3
"""
Generates an invisible (transparent) XCursor theme for kiosk environments.
Works system-wide and user-wide for Wayland compositors (Cage/wlroots) and X11.
"""

import sys
import os
import struct

def generate_transparent_theme(dest_dir):
    cursors_dir = os.path.join(dest_dir, "cursors")
    os.makedirs(cursors_dir, exist_ok=True)

    # Write index.theme
    index_theme_path = os.path.join(dest_dir, "index.theme")
    with open(index_theme_path, "w") as f:
        f.write("[Icon Theme]\nName=transparent\nComment=Invisible Cursor Theme\n")

    # XCursor binary specification (1x1 fully transparent pixel)
    magic = b'Xcur'
    header_size = 16
    version = 0x00010000
    ntoc = 1
    toc_type = 0xfffd0002
    toc_subtype = 32
    toc_pos = header_size + 12

    img_header_size = 36
    img_type = 0xfffd0002
    img_subtype = 32
    img_version = 1
    width = 32
    height = 32
    xhot = 0
    yhot = 0
    delay = 0

    pixels = b'\x00' * (width * height * 4)

    data = (
        magic +
        struct.pack('<III', header_size, version, ntoc) +
        struct.pack('<III', toc_type, toc_subtype, toc_pos) +
        struct.pack('<IIIIIIIII', img_header_size, img_type, img_subtype, img_version, width, height, xhot, yhot, delay) +
        pixels
    )

    default_cursor = os.path.join(cursors_dir, "default")
    with open(default_cursor, "wb") as f:
        f.write(data)

    cursor_names = [
        "left_ptr", "pointer", "hand1", "hand2", "xterm", "crosshair", "right_ptr",
        "copy", "move", "wait", "watch", "text", "help", "progress", "alias", "cell",
        "col-resize", "row-resize", "n-resize", "s-resize", "w-resize", "e-resize",
        "nw-resize", "ne-resize", "sw-resize", "se-resize", "grab", "grabbing",
        "sb_h_double_arrow", "sb_v_double_arrow", "top_left_corner", "top_right_corner",
        "bottom_left_corner", "bottom_right_corner", "0000816000000681000000000006000c",
        "dnd-ask", "dnd-copy", "dnd-link", "dnd-move", "dnd-none"
    ]

    for name in cursor_names:
        link_path = os.path.join(cursors_dir, name)
        if os.path.exists(link_path) or os.path.islink(link_path):
            try:
                os.remove(link_path)
            except OSError:
                pass
        os.symlink("default", link_path)

    print(f"Generated transparent cursor theme in {dest_dir}")

def configure_gtk_theme():
    user_gtk = os.path.expanduser("~/.config/gtk-3.0/settings.ini")
    os.makedirs(os.path.dirname(user_gtk), exist_ok=True)
    with open(user_gtk, "w") as f:
        f.write("[Settings]\ngtk-cursor-theme-name=transparent\n")

def main():
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        target = os.path.expanduser("~/.icons/transparent")
    generate_transparent_theme(target)
    try:
        configure_gtk_theme()
    except Exception:
        pass

if __name__ == "__main__":
    main()
