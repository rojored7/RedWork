# This file is intentionally clean - no secrets.
import os

DATABASE_URL = os.environ.get("DATABASE_URL")
API_KEY = os.environ["API_KEY"]

def get_config():
    return {
        "host": "localhost",
        "port": 8000,
        "debug": False,
    }
