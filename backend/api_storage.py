import os
import json
import time
import base64
from backend.config import DATA_DIR, HOTEL_ASSETS_DIR, ensure_directories, BASE_DIR

def handle_delete_image(request_handler):
    content_length = int(request_handler.headers.get('Content-Length', 0))
    body = request_handler.rfile.read(content_length).decode('utf-8')
    try:
        data = json.loads(body)
        path = data.get('path', '')
        
        # Only allow deleting from hotel_assets/
        if not path.startswith('hotel_assets/'):
            raise ValueError("Invalid path for deletion")
            
        # Security: prevent directory traversal
        norm_path = os.path.normpath(path)
        if '..' in norm_path:
            raise ValueError("Invalid path")
            
        full_path = os.path.join(BASE_DIR, norm_path)
        if os.path.exists(full_path):
            os.remove(full_path)
            
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

def handle_write_json(request_handler):
    content_length = int(request_handler.headers.get('Content-Length', 0))
    body = request_handler.rfile.read(content_length).decode('utf-8')
    try:
        data = json.loads(body)
        file_name = os.path.basename(data.get('fileName', ''))
        content = data.get('content')
        
        ensure_directories()
        
        with open(os.path.join(DATA_DIR, file_name), 'w') as f:
            json.dump(content, f, indent=2)
            
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

def handle_save_image(request_handler):
    content_length = int(request_handler.headers.get('Content-Length', 0))
    body = request_handler.rfile.read(content_length).decode('utf-8')
    try:
        data = json.loads(body)
        sub_folder = data.get('subFolder', 'markets')
        sub_folder = os.path.normpath(sub_folder).strip('/')
        if '..' in sub_folder:
            raise ValueError("Invalid subFolder")
            
        image_base64 = data.get('imageBase64', '')
        original_name = os.path.basename(data.get('originalName', 'image.jpg'))
        
        name, ext = os.path.splitext(original_name)
        timestamp = int(time.time() * 1000)
        new_filename = f"{name}_{timestamp}{ext}"
        
        target_dir = os.path.join(HOTEL_ASSETS_DIR, 'images', sub_folder)
        os.makedirs(target_dir, exist_ok=True)
        dest_path = os.path.join(target_dir, new_filename)
        
        with open(dest_path, 'wb') as f:
            f.write(base64.b64decode(image_base64))
            
        try:
            from scripts.optimize_assets import optimize_single_file
            optimize_single_file(dest_path)
        except Exception as opt_err:
            print(f"Asset optimizer warning: {opt_err}")

        relative_path = f"hotel_assets/images/{sub_folder}/{new_filename}"
        
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True, 'path': relative_path}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

def handle_list_images(request_handler):
    try:
        images = []
        valid_extensions = ('.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.pdf')
        
        if os.path.exists(HOTEL_ASSETS_DIR):
            for root, dirs, files in os.walk(HOTEL_ASSETS_DIR):
                for file in files:
                    if file.lower().endswith(valid_extensions):
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, BASE_DIR).replace('\\', '/')
                        images.append(rel_path)
                        
        images.sort()
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True, 'files': images}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

def handle_list_usb_files(request_handler):
    try:
        usb_files = []
        valid_extensions = ('.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.pdf')
        mount_points = ['/media', '/mnt', '/run/media']
        
        for mount in mount_points:
            if os.path.exists(mount):
                for root, dirs, files in os.walk(mount):
                    for file in files:
                        if file.lower().endswith(valid_extensions):
                            full_path = os.path.join(root, file)
                            try:
                                size = os.path.getsize(full_path)
                                usb_files.append({
                                    'path': full_path,
                                    'name': file,
                                    'size': size
                                })
                            except Exception:
                                pass
                                
        usb_files.sort(key=lambda x: x['name'])
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True, 'files': usb_files}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

def handle_copy_usb_file(request_handler):
    content_length = int(request_handler.headers.get('Content-Length', 0))
    body = request_handler.rfile.read(content_length).decode('utf-8')
    try:
        data = json.loads(body)
        usb_path = data.get('usbPath', '')
        sub_folder = data.get('subFolder', 'markets')
        sub_folder = os.path.normpath(sub_folder).strip('/')
        if '..' in sub_folder:
            raise ValueError("Invalid subFolder")
            
        if not os.path.exists(usb_path) or not os.path.isfile(usb_path):
            raise ValueError("USB file not found")
            
        original_name = os.path.basename(usb_path)
        name, ext = os.path.splitext(original_name)
        timestamp = int(time.time() * 1000)
        new_filename = f"{name}_{timestamp}{ext}"
        
        target_dir = os.path.join(HOTEL_ASSETS_DIR, 'images', sub_folder)
        os.makedirs(target_dir, exist_ok=True)
        dest_path = os.path.join(target_dir, new_filename)
        
        import shutil
        shutil.copy2(usb_path, dest_path)
        
        try:
            from scripts.optimize_assets import optimize_single_file
            optimize_single_file(dest_path)
        except Exception as opt_err:
            print(f"Asset optimizer warning: {opt_err}")

        relative_path = f"hotel_assets/images/{sub_folder}/{new_filename}"
        
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True, 'path': relative_path}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))

