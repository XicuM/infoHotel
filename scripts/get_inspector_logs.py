import sys

async def get_logs():
    try:
        ip = sys.argv[1] if len(sys.argv) > 1 else '192.168.1.158'
        # Get the debugger URL
        url = f'http://{ip}:8081/json/list'
        print(f"Connecting to inspector at {url}...")
        req = urllib.request.urlopen(url, timeout=3)
        pages = json.loads(req.read())
        if not pages:
            print("No pages open in Cog inspector.")
            return
            
        ws_url = pages[0].get('webSocketDebuggerUrl')
        if not ws_url:
            print("No websocket URL found in inspector response.")
            return
            
        print(f"Connecting to {ws_url}...")
        
        async with websockets.connect(ws_url) as ws:
            # Enable Runtime and Console domains to receive logs
            await ws.send(json.dumps({"id": 1, "method": "Runtime.enable"}))
            await ws.send(json.dumps({"id": 2, "method": "Console.enable"}))
            await ws.send(json.dumps({"id": 3, "method": "Log.enable"}))
            
            print("Listening for console errors for 5 seconds...")
            
            # Listen for 5 seconds
            end_time = asyncio.get_event_loop().time() + 5.0
            while asyncio.get_event_loop().time() < end_time:
                try:
                    msg = await asyncio.wait_for(ws.recv(), timeout=1.0)
                    data = json.loads(msg)
                    
                    if data.get('method') == 'Console.messageAdded':
                        message = data['params']['message']
                        if message['level'] in ['error', 'warning']:
                            print(f"[{message['level'].upper()}] {message['text']}")
                            
                    elif data.get('method') == 'Log.entryAdded':
                        entry = data['params']['entry']
                        if entry['level'] in ['error', 'warning']:
                            print(f"[{entry['level'].upper()}] {entry['text']}")
                            
                    elif data.get('method') == 'Runtime.consoleAPICalled':
                        if data['params']['type'] in ['error', 'warning']:
                            args = data['params'].get('args', [])
                            text = " ".join([str(a.get('value', a.get('description', ''))) for a in args])
                            print(f"[{data['params']['type'].upper()}] {text}")
                            
                    elif data.get('method') == 'Runtime.exceptionThrown':
                        exception = data['params']['exceptionDetails']
                        text = exception.get('exception', {}).get('description', str(exception))
                        print(f"[EXCEPTION] {text}")
                        
                except asyncio.TimeoutError:
                    continue
                    
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    asyncio.run(get_logs())
