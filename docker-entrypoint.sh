#!/bin/sh
set -e

# Ensure data directory exists for persistent storage
mkdir -p /app/data

# Use the .env file if it exists, otherwise fall back to environment variables
if [ -f /app/.env ]; then
    echo "Loading environment from .env file"
fi

# Initialize the database (SQLite)
python -c "import sqlite3; sqlite3.connect('/app/neverendingquest.db').close()"

# Start the application
exec python web/web_interface.py
