# Daily Life OS

A completely offline-first personal reflection and journaling tool. Built with Flutter for cross-platform support (Android, iOS, Windows, macOS) and a local FastAPI backend powered by Ollama for AI insights.

## Features
- **Fast Logging**: Quickly log mood, focus, sleep, and tasks.
- **Rich Media**: Upload photos or use voice transcription (coming soon / mocked via local whisper).
- **Local AI Analysis**: Uses open-weight local models (e.g. `phi4:mini`, `llama3.2:1b`, or vision models) to categorize your brain dumps, identify patterns, and offer actionable suggestions.
- **Offline First**: All data is stored in local SQLite databases (both on the frontend client and synced to the backend server). No cloud, no subscription, 100% private.
- **Data Visualization**: Built-in charts and history tracking.

---

## 🚀 Setup Instructions

### 1. Backend (Python + FastAPI + Ollama)

**Requirements**: Python 3.10+, [Ollama installed locally](https://ollama.com/).

```bash
# 1. Download the local AI model (run in another terminal)
ollama run phi4:mini

# 2. Setup python environment
cd backend
python -m venv .venv

# Activate venv:
# Windows: .venv\\Scripts\\activate
# macOS/Linux: source .venv/bin/activate

# 3. Install requirements
pip install fastapi uvicorn pydantic httpx

# 4. Start the backend server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
*Note: Make sure Ollama is running in the background.*

### 2. Frontend (Flutter)

**Requirements**: Flutter SDK.

```bash
# 1. Enter the root project folder
cd daily_life_os

# 2. Get dependencies
flutter pub get

# 3. Enable desktop support (if you want to run on Windows/macOS/Linux)
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# 4. Run the app
flutter run -d windows
# or flutter run -d macos
# or flutter run (for mobile emulator)
```

## Architecture Notes
- **State Management**: Riverpod (`hooks_riverpod` compatible).
- **Communication**: Frontend talks to `http://localhost:8000/analyze` via REST.
- **Database**: `sqflite_common_ffi` is initialized on desktop platforms to ensure SQLite works outside of mobile.
- **AI Processing**: Ollama's new `format: "json"` ensures structured responses so the client app doesn't break parsing string outputs.

## Customization
To change the AI personality or output schema, modify the `SYSTEM_PROMPT` inside `backend/analyze.py`.
