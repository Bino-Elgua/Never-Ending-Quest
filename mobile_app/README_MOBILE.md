# NeverEndingQuest - Mobile App (Termux Edition)

This directory contains the Flutter mobile application for NeverEndingQuest.

## Quick Start (Termux)

We've provided a management script to make running and building the app as easy as possible in the Termux environment.

### 1. Initial Setup
From the project root, run:
```bash
./manage_mobile.sh install  # Install Java and Python dependencies
./manage_mobile.sh setup    # Fetch Flutter dependencies and run generators
```

### 2. Running the App
Start the backend first, then the mobile app:
```bash
./manage_mobile.sh backend  # Start the backend in one terminal
./manage_mobile.sh run      # Start the app in another terminal (Select Option 1)
```
Then select **Option 1 (Web)**.

### 3. Building for Android (APK)
Building an APK directly in Termux requires the Android SDK and OpenJDK.
1. Install Java: `pkg install openjdk-17`
2. Ensure you have the Android SDK installed and `flutter config --android-sdk <path>` configured.
3. Run:
```bash
./manage_mobile.sh build
```
Then select **Option 1 (APK)**.

## Troubleshooting

### Missing Platform Folders
If you don't see `android/` or `web/` folders, they have been restored. If they go missing again, run:
```bash
cd mobile_app && flutter create .
```

### Compilation Errors
If you see errors related to `objective_c` or `native assets` during web builds in Termux, this is often due to environment limitations. Try running with:
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```
(The `manage_mobile.sh run` command does this for you!)

### Connecting to the Backend
By default, the app expects the NeverEndingQuest backend to be running on `localhost:5000`. 
1. Start the backend: `python run_web.py`
2. Start the mobile app: `./manage_mobile.sh run` (Web mode)

## Architecture Notes
- **State Management:** Riverpod
- **Local Database:** Isar (Offline-first support)
- **AI Integration:** Supports both remote (WebSocket) and experimental local LLM providers.
- **Voice:** Integrated Text-to-Speech and Speech-to-Text for a hands-free DM experience.
