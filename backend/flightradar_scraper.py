import json
import time

# In-memory cache for flight data to avoid spamming FlightRadar24
FR_CACHE = {
    'timestamp': 0,
    'data': None
}
FR_CACHE_TTL = 300  # 5 minutes

def handle_flightradar_get(request_handler):
    global FR_CACHE
    now = time.time()
    
    # Return cached data if fresh
    if FR_CACHE['data'] is not None and (now - FR_CACHE['timestamp'] < FR_CACHE_TTL):
        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(FR_CACHE['data'])
        return

    try:
        from FlightRadar24 import FlightRadar24API
        fr_api = FlightRadar24API()
        
        # Get airport details which contains departures
        details = fr_api.get_airport_details('IBZ')
        
        try:
            deps_data = details['airport']['pluginData']['schedule']['departures']['data']
        except KeyError:
            deps_data = []

        transformed_flights = []
        for d in deps_data:
            try:
                flight = d['flight']
                
                # Extract flight numbers
                flight_nums = []
                num_info = flight.get('identification', {}).get('number', {})
                if num_info and num_info.get('default'):
                    flight_nums.append(num_info.get('default'))
                if num_info and num_info.get('alternative'):
                    flight_nums.append(num_info.get('alternative'))
                    
                if not flight_nums:
                    flight_nums = [flight.get('identification', {}).get('callsign', 'UNKNOWN')]

                # Extract destination
                dest = flight.get('airport', {}).get('destination', {})
                if dest:
                    dest_name = dest.get('position', {}).get('region', {}).get('city') or dest.get('name', 'Unknown')
                else:
                    dest_name = 'Unknown'

                # Extract times (Unix Epoch -> ISO8601 string)
                times = flight.get('time', {})
                scheduled_ts = times.get('scheduled', {}).get('departure')
                estimated_ts = times.get('estimated', {}).get('departure')
                
                # Format to YYYY-MM-DD HH:MM
                def format_ts(ts):
                    if not ts: return None
                    return time.strftime('%Y-%m-%d %H:%M', time.localtime(ts))

                scheduled_str = format_ts(scheduled_ts)
                estimated_str = format_ts(estimated_ts)

                # Extract status and gate
                status_text = flight.get('status', {}).get('text', 'Scheduled')
                
                # Custom logic for "Delayed" vs "On Time" based on > 15 mins difference
                if scheduled_ts and estimated_ts:
                    delay_mins = (estimated_ts - scheduled_ts) / 60
                    if delay_mins > 15:
                        # Ensure we clearly state it's delayed if it's more than 15 mins late
                        status_text = f"Delayed to {time.strftime('%H:%M', time.localtime(estimated_ts))}"
                    else:
                        # If the delay is 15 mins or less, wipe out estimated_str so Flutter doesn't force a delay status
                        if abs(delay_mins) <= 15:
                            estimated_str = None
                        
                        if "Estimated" in status_text or "Delayed" in status_text:
                            status_text = "Expected"
                elif status_text == "Scheduled":
                    status_text = "Expected"
                        
                # FlightRadar24's data for Ibiza is unreliable as it frequently mixes 
                # check-in desk numbers into the 'gate' field. Since we cannot definitively 
                # distinguish between Gate 12 and Check-in Desk 12, we must hide the gate 
                # to prevent sending tourists to the wrong location.
                gate = '-'

                transformed_flights.append({
                    "flightNumbers": flight_nums,
                    "destination": dest_name,
                    "scheduledTime": scheduled_str,
                    "estimatedTime": estimated_str,
                    "status": status_text,
                    "gate": str(gate)
                })
            except Exception as e:
                print(f"[flightradar] Error parsing flight: {e}")
                continue

        response_data = json.dumps({"departures": transformed_flights}).encode('utf-8')
        
        # Update cache
        FR_CACHE['timestamp'] = now
        FR_CACHE['data'] = response_data

        request_handler.send_response(200)
        request_handler.send_header('Content-Type', 'application/json')
        request_handler.end_headers()
        request_handler.wfile.write(response_data)
        
    except Exception as e:
        print(f"[flightradar] Critical error fetching data: {e}", flush=True)
        # If cache exists, serve stale data
        if FR_CACHE['data'] is not None:
            request_handler.send_response(200)
            request_handler.send_header('Content-Type', 'application/json')
            request_handler.end_headers()
            request_handler.wfile.write(FR_CACHE['data'])
        else:
            request_handler.send_error(502, str(e))
