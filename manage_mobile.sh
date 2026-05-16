#!/bin/bash

# NeverEndingQuest Mobile Management Script for Termux
# This script helps manage the Flutter mobile app environment.

set -e

APP_DIR="mobile_app"
FLUTTER_BIN="/data/data/com.termux/files/usr/opt/flutter/bin"
BACKEND_SCRIPT="run_web.py"

# Ensure Flutter is in PATH
if [[ ":$PATH:" != *":$FLUTTER_BIN:"* ]]; then
    export PATH="$PATH:$FLUTTER_BIN"
fi

show_help() {
    echo "Usage: ./manage_mobile.sh [command]"
    echo ""
    echo "Commands:"
    echo "  setup    - Install Flutter dependencies and run generators"
    echo "  run      - Run the app (prompts for platform)"
    echo "  build    - Build the app (APK/Web)"
    echo "  backend  - Start the NeverEndingQuest backend server"
    echo "  doctor   - Check environment health"
    echo "  clean    - Clean build artifacts"
    echo "  install  - Install system dependencies (Java, Python, etc.)"
    echo "  help     - Show this help message"
}

check_env() {
    echo "Checking environment..."
    if ! command -v flutter &> /dev/null; then
        echo "Error: Flutter is not installed or not in PATH."
        echo "Please install it or ensure it's at $FLUTTER_BIN"
        exit 1
    fi
    
    if ! command -v java &> /dev/null; then
        echo "Warning: Java not found. Android builds will fail."
        echo "To install: ./manage_mobile.sh install"
    fi
}

do_install() {
    echo "Installing system dependencies..."
    pkg update
    pkg install openjdk-17 python -y
    if [ -f "requirements.txt" ]; then
        echo "Installing Python requirements..."
        pip install -r requirements.txt
    fi
    echo "System dependencies installed!"
}

do_setup() {
    check_env
    echo "Installing Flutter dependencies..."
    cd "$APP_DIR"
    flutter pub get
    echo "Running code generation (build_runner)..."
    flutter pub run build_runner build --delete-conflicting-outputs
    cd ..
    echo "Setup complete!"
}

do_run() {
    check_env
    echo "Which platform would you like to run on?"
    echo "1) Web (runs a local server, best for Termux)"
    echo "2) Linux Desktop (requires X11/Wayland)"
    echo "3) Android Device (requires connected device/ADB)"
    read -p "Select [1-3]: " choice
    
    cd "$APP_DIR"
	    case $choice in
	        1) 
	           BACKEND_PORT=$(python3 -c "import sys; sys.path.insert(0,'.'); import config_template as config; print(getattr(config,'WEB_PORT',8357))" 2>/dev/null || echo "8357")
	           echo "Starting Web Server at http://localhost:8080 — connecting to backend on port $BACKEND_PORT"
	           flutter run -d web-server \
	             --web-hostname 0.0.0.0 \
	             --web-port 8080 \
	             --dart-define=API_HOST=http://127.0.0.1:$BACKEND_PORT/ ;;
	        2) flutter run -d linux ;;
        3) flutter run -d android ;;
        *) echo "Invalid selection." ;;
    esac
    cd ..
}

do_build() {
    check_env
    echo "What would you like to build?"
    echo "1) APK (Android)"
    echo "2) Web (Static files)"
    read -p "Select [1-2]: " choice
    
    cd "$APP_DIR"
    case $choice in
        1) 
            if ! command -v java &> /dev/null; then
                echo "Error: Java is required for APK builds. Run './manage_mobile.sh install'"
                exit 1
            fi
            flutter build apk --release 
            ;;
        2) flutter build web ;;
        *) echo "Invalid selection." ;;
    esac
    cd ..
}

do_backend() {
    if [ ! -f "$BACKEND_SCRIPT" ]; then
        echo "Error: Backend script $BACKEND_SCRIPT not found in current directory."
        exit 1
    fi
    echo "Starting NeverEndingQuest Backend..."
    python "$BACKEND_SCRIPT"
}

case "$1" in
    setup)    do_setup ;;
    run)      do_run ;;
    build)    do_build ;;
    backend)  do_backend ;;
    doctor)   flutter doctor -v ;;
    clean)    cd "$APP_DIR" && flutter clean && cd .. ;;
    install)  do_install ;;
    help|*)   show_help ;;
esac
