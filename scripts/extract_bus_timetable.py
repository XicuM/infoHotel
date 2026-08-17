#!/usr/bin/env python3
"""
scripts/extract_bus_timetable.py

Standalone extraction script to fetch the ALSA GTFS dataset from NAP,
filter for Ibiza stops, and generate a lightweight offline JSON timetable:
hotel_assets/data/bus_timetable.json

Usage:
    python3 scripts/extract_bus_timetable.py [--api-key <NAP_API_KEY>] [--file-id 1133]
"""

import argparse
import csv
import io
import json
import os
import re
import sys
import urllib.request
import zipfile

# Hotel & key bus stops in Ibiza
STOPS_CONFIG = [
    {
        'id': '0001454200000001',
        'code': '108',
        'name': 'Hotel',
        'direction': 'bus_dir_port_des_torrent',
    },
    {
        'id': '0001454300000001',
        'code': '408',
        'name': 'Hotel',
        'direction': 'bus_dir_sant_antoni',
    },
    {
        'id': '0001452800000001',
        'code': '101',
        'name': 'Estació de Sant Antoni',
        'direction': 'bus_dir_all',
    },
]

ROUTE_COLORS = {
    'T1': '#1565C0',
    'T2': '#1976D2',
    'T3': '#1E88E5',
    'T3-U6': '#1E88E5',
    'T4': '#2196F3',
    'T5': '#42A5F5',
    'T6': '#64B5F6',
    'T7': '#90CAF9',
    'A1': '#2E7D32',
    'A2': '#388E3C',
    'A4': '#43A047',
    'A7': '#4CAF50',
    'A8': '#4CAF50',
    'A9': '#4CAF50',
    'A10': '#66BB6A',
    'A11': '#66BB6A',
    'A16': '#81C784',
    'Aero1': '#6A1B9A',
    'Aero2': '#7B1FA2',
    'Aero3': '#8E24AA',
    'Aero4': '#9C27B0',
    'Aero5': '#AB47BC',
    'P1': '#E65100',
    'P2': '#EF6C00',
    'P3': '#F57C00',
    'P4': '#FB8C00',
    'P5': '#FFA726',
    'P7': '#FFB74D',
    'P9': '#FFCC02',
    'D1': '#00695C',
    'D2': '#00796B',
    'D3': '#00897B',
    'D4': '#009688',
    'D5': '#26A69A',
    'D6': '#4DB6AC',
    'U1': '#006064',
    'U2': '#00838F',
    'U4': '#0097A7',
    'U7': '#00ACC1',
    'U12': '#26C6DA',
    'N1': '#0D1B2A',
    'N2': '#1B263B',
    'N3': '#415A77',
    'N4': '#1B263B',
    'N5': '#415A77',
    'N6': '#415A77',
    '02': '#ea2423',
    '03': '#ea2423',
    '08': '#ea2423',
    '10': '#ea2423',
    '11': '#ea2423',
    '13': '#ea2423',
}


def clean_route_name(name: str) -> str:
    clean = name.strip()
    if clean.startswith('ALSA - '):
        clean = clean[7:].strip()
    return clean


def clean_destination(dest: str) -> str:
    if not dest:
        return dest
    cleaned = dest.strip()
    if cleaned.startswith('ALSA - '):
        cleaned = cleaned[7:].strip()
    cleaned = re.sub(r'^[A-Za-z0-9]+-\s*', '', cleaned)
    cleaned = (
        cleaned.replace('Estació de Sant Antoni', 'Sant Antoni')
        .replace('Eivissa/CETIS', 'Eivissa (CETIS)')
        .replace('Airport', 'Aeroport')
        .replace("Aeroport d'Eivissa", 'Aeroport')
        .replace('Ibiza Airport', 'Aeroport')
    )
    if cleaned:
        cleaned = cleaned[0].upper() + cleaned[1:]
    return cleaned


def is_valid_time(t: str) -> bool:
    parts = t.split(':')
    if len(parts) < 2:
        return False
    try:
        h, m = int(parts[0]), int(parts[1])
        return 0 <= h < 24 and 0 <= m < 60
    except ValueError:
        return False


def get_line_prefix(num: str) -> str:
    m = re.match(r'^([A-Za-z]+)', num)
    return m.group(1).upper() if m else ''


def get_api_key_from_env() -> str:
    env_file = os.path.join(os.path.dirname(__file__), '..', '.env')
    if os.path.exists(env_file):
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('BUS_API_KEY='):
                    return line.split('=', 1)[1].strip()
    return os.environ.get('BUS_API_KEY', '')


def download_gtfs(api_key: str, file_id: int) -> bytes:
    nap_base = 'https://nap.transportes.gob.es/api'
    link_url = f'{nap_base}/Fichero/downloadLink/{file_id}'
    print(f'Querying download link from {link_url}...')
    req = urllib.request.Request(link_url, headers={'ApiKey': api_key, 'User-Agent': 'InfoHotel/1.0'})
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode('utf-8').strip()
        if body.startswith('{'):
            download_url = json.loads(body).get('url')
        else:
            download_url = body

    if not download_url:
        raise ValueError(f'Could not get download URL from response: {body}')

    print(f'Downloading GTFS package from: {download_url}...')
    dl_req = urllib.request.Request(download_url, headers={'User-Agent': 'InfoHotel/1.0'})
    with urllib.request.urlopen(dl_req, timeout=60) as resp:
        return resp.read()


def process_gtfs(zip_bytes: bytes) -> dict:
    print('Processing GTFS ZIP archive...')
    target_stop_ids = {s['id'] for s in STOPS_CONFIG}
    stop_names = {s['id']: s['name'] for s in STOPS_CONFIG}
    stop_directions = {s['id']: s['direction'] for s in STOPS_CONFIG}

    stops_data = {}
    routes_data = {}
    trips_data = {}
    stop_times_data = {stop_id: [] for stop_id in target_stop_ids}

    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as z:
        # 1. stops.txt
        stops_file = next((name for name in z.namelist() if name.endswith('stops.txt')), None)
        if stops_file:
            with z.open(stops_file) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig'))
                for row in reader:
                    sid = row.get('stop_id', '')
                    if sid in target_stop_ids:
                        stops_data[sid] = {
                            'id': sid,
                            'code': row.get('stop_code', ''),
                            'name': row.get('stop_name', ''),
                        }

        # 2. routes.txt
        routes_file = next((name for name in z.namelist() if name.endswith('routes.txt')), None)
        if routes_file:
            with z.open(routes_file) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig'))
                for row in reader:
                    rid = row.get('route_id', '')
                    short_name = row.get('route_short_name', '')
                    long_name = row.get('route_long_name', '')
                    color = row.get('route_color', '')
                    text_color = row.get('route_text_color', '')
                    routes_data[rid] = {
                        'route_id': rid,
                        'short_name': short_name or long_name,
                        'long_name': long_name,
                        'color': f'#{color}' if color and not color.startswith('#') else (color or '#ea2423'),
                        'text_color': f'#{text_color}' if text_color and not text_color.startswith('#') else (text_color or '#ffffff'),
                    }

        # 3. trips.txt
        trips_file = next((name for name in z.namelist() if name.endswith('trips.txt')), None)
        if trips_file:
            with z.open(trips_file) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig'))
                for row in reader:
                    tid = row.get('trip_id', '')
                    trips_data[tid] = {
                        'trip_id': tid,
                        'route_id': row.get('route_id', ''),
                        'headsign': row.get('trip_headsign', ''),
                    }

        # 4. stop_times.txt (Stream and filter only relevant stop_ids)
        stop_times_file = next((name for name in z.namelist() if name.endswith('stop_times.txt')), None)
        if stop_times_file:
            with z.open(stop_times_file) as f:
                reader = csv.DictReader(io.TextIOWrapper(f, encoding='utf-8-sig'))
                for row in reader:
                    sid = row.get('stop_id', '')
                    if sid in target_stop_ids:
                        stop_times_data[sid].append({
                            'trip_id': row.get('trip_id', ''),
                            'departure': row.get('departure_time', ''),
                        })

    stops = []
    for s_config in STOPS_CONFIG:
        stop_id = s_config['id']
        stop_meta = stops_data.get(stop_id, {'id': stop_id, 'code': s_config['code'], 'name': s_config['name']})
        st_list = stop_times_data.get(stop_id, [])

        line_map = {}
        for st in st_list:
            trip_id = st['trip_id']
            trip = trips_data.get(trip_id)
            if not trip:
                continue

            route = routes_data.get(trip['route_id'])
            if not route:
                continue

            route_num = route['short_name'] or route['long_name'] or '?'
            route_num = clean_route_name(route_num)

            headsign = trip['headsign'] or route['long_name'] or ''
            cleaned_dest = clean_destination(headsign)

            # Skip trips terminating at Sant Antoni station for the Sant Antoni stop itself
            if stop_id == '0001452800000001' and 'Sant Antoni' in cleaned_dest:
                continue

            key = f'{route_num}_{headsign}'
            if key not in line_map:
                line_map[key] = {
                    'number': route_num,
                    'color': ROUTE_COLORS.get(route_num, route['color']),
                    'textColor': route['text_color'],
                    'destination': cleaned_dest,
                    'headsign': headsign,
                    'times': set(),
                }

            dep_time = st['departure']
            if is_valid_time(dep_time):
                line_map[key]['times'].add(dep_time[:5])

        lines_for_stop = []
        for l in line_map.values():
            sorted_times = sorted(list(l['times']))
            lines_for_stop.append({
                'number': l['number'],
                'color': l['color'],
                'textColor': l['textColor'],
                'destination': l['destination'],
                'headsign': l['headsign'],
                'times': sorted_times,
            })

        prefix_order = {'T': 0, 'A': 1, 'AERO': 2, 'P': 3, 'D': 4, 'U': 5, 'N': 6}

        def sort_key(x):
            pref = get_line_prefix(x['number'])
            p_ord = prefix_order.get(pref, 5)
            num_digits = re.sub(r'[^0-9]', '', x['number'])
            trailing_num = int(num_digits) if num_digits else 999
            return (p_ord, trailing_num, x['destination'])

        lines_for_stop.sort(key=sort_key)

        stops.append({
            'id': stop_id,
            'code': stop_meta.get('code', s_config['code']),
            'name': stop_names.get(stop_id, stop_meta.get('name', stop_id)),
            'direction': stop_directions.get(stop_id, ''),
            'lines': lines_for_stop,
        })

    return {
        'version': '1.5',
        'lastUpdate': '2026-08-17T11:00:00.000Z',
        'stops': stops,
    }


def main():
    parser = argparse.ArgumentParser(description='Extract Ibiza Bus Timetable from GTFS')
    parser.add_argument('--api-key', default='', help='NAP API Key')
    parser.add_argument('--file-id', type=int, default=1133, help='NAP GTFS File ID')
    parser.add_argument('--zip-file', default='', help='Path to local GTFS ZIP (if already downloaded)')
    parser.add_argument('--output', default='', help='Path to output JSON file')

    args = parser.parse_args()

    api_key = args.api_key or get_api_key_from_env()
    output_path = args.output or os.path.join(
        os.path.dirname(__file__), '..', 'hotel_assets', 'data', 'bus_timetable.json'
    )

    if args.zip_file and os.path.exists(args.zip_file):
        with open(args.zip_file, 'rb') as f:
            zip_bytes = f.read()
    else:
        if not api_key:
            print('Error: NAP API Key is required. Set BUS_API_KEY in .env or pass --api-key.', file=sys.stderr)
            sys.exit(1)
        zip_bytes = download_gtfs(api_key, args.file_id)

    data = process_gtfs(zip_bytes)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f'Successfully exported bus timetable to {output_path} ({os.path.getsize(output_path)} bytes).')


if __name__ == '__main__':
    main()
