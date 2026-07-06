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
        
        # Only allow deleting from hotel_assets/images/
        if not path.startswith('hotel_assets/images/'):
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
            
        relative_path = f"hotel_assets/images/{sub_folder}/{new_filename}"
        
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(json.dumps({'success': True, 'path': relative_path}).encode('utf-8'))
    except Exception as e:
        request_handler.send_error(500, str(e))
