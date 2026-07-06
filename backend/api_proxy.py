import urllib.request
import urllib.parse
import urllib.error

import time

# Simple in-memory cache to prevent 429 Too Many Requests across multiple kiosks
PROXY_CACHE = {}
CACHE_TTL = 900 # 15 minutes

def handle_proxy_get(request_handler):
    q = urllib.parse.urlparse(request_handler.path).query
    url = urllib.parse.parse_qs(q).get('url', [None])[0]
    if not url:
        request_handler.send_error(400, "Missing 'url'")
        return

    # Check cache
    now = time.time()
    if url in PROXY_CACHE:
        entry = PROXY_CACHE[url]
        if now - entry['timestamp'] < CACHE_TTL:
            if entry.get('error'):
                request_handler.send_error(entry['error'], entry['body'].decode('utf-8'))
                return
                
            request_handler.send_response(200)
            request_handler.send_header('Content-Type', entry['content_type'])
            request_handler.end_headers()
            request_handler.wfile.write(entry['body'])
            return

    headers = {}
    for name, value in request_handler.headers.items():
        if name.lower() in ('api_key', 'apikey', 'x-rapidapi-key',
                             'x-rapidapi-host', 'user-agent'):
            headers[name] = value
            
    headers.setdefault('User-Agent',
        'Mozilla/5.0 (X11; Linux) AppleWebKit/605.1.15 (KHTML, like Gecko)')

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read()
            ct = resp.headers.get('Content-Type', 'application/json')
            
        # Save to cache
        PROXY_CACHE[url] = {
            'timestamp': now,
            'body': body,
            'content_type': ct,
            'error': None
        }

        request_handler.send_response(200)
        request_handler.send_header('Content-Type', ct)
        request_handler.end_headers()
        request_handler.wfile.write(body)
    except Exception as e:
        error_body = ""
        try:
            if hasattr(e, 'read'):
                error_body = e.read().decode('utf-8')
                print(f"[proxy] RapidAPI Error Body: {error_body}", flush=True)
        except:
            pass

        # If we have a stale cache, serve it instead of failing
        if url in PROXY_CACHE and PROXY_CACHE[url]['error'] is None:
            entry = PROXY_CACHE[url]
            request_handler.send_response(200)
            request_handler.send_header('Content-Type', entry['content_type'])
            request_handler.end_headers()
            request_handler.wfile.write(entry['body'])
            return
            
        # Cache the failure to prevent spamming the upstream API
        PROXY_CACHE[url] = {
            'timestamp': now,
            'body': str(e).encode('utf-8'),
            'content_type': 'text/plain',
            'error': 502
        }
        
        request_handler.send_error(502, str(e))
