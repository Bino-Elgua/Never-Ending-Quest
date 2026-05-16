#!/bin/sh
set -e

# Ensure data directory exists
mkdir -p /app/data

# Initialize the database (SQLite)
python -c "import sqlite3; sqlite3.connect('/app/neverendingquest.db').close()"

# Start the application with gunicorn and eventlet worker
exec gunicorn --worker-class eventlet -w 1 -b 0.0.0.0:$WEB_PORT web.web_interface:app
