import os

# Base directory is the project root (one level up from backend/)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOTEL_ASSETS_DIR = os.path.join(BASE_DIR, 'hotel_assets')
DATA_DIR = os.path.join(HOTEL_ASSETS_DIR, 'data')

def ensure_directories():
    os.makedirs(DATA_DIR, exist_ok=True)
