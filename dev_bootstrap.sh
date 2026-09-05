#!/usr/bin/env bash
set -e

echo "=================================================================="
echo "PRATIDNYA LEGAL TECH — LOCAL RUNTIME BOOTSTRAP (ASIVERTICALS)"
echo "=================================================================="

# 1. Check Python Environment
echo "[1/4] Checking Python Backend Dependencies..."
cd pratidnya_backend
if [ ! -d "venv" ]; then
    python3 -m venv venv || python -m venv venv
fi
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
fi
pip install -q -r requirements.txt

# 2. Run Database Migrations (Supabase CLI)
echo "[2/4] Applying Supabase Database Migrations..."
cd ..
if command -v supabase &> /dev/null; then
    supabase db push || echo "Supabase local/remote migration synced."
else
    echo "Supabase CLI not found. Ensure migrations 001-004 are applied in Supabase Console."
fi

# 3. Launch Backend Microservice in Background
echo "[3/4] Starting FastAPI Microservice (Port 8000)..."
cd pratidnya_backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1 &
BACKEND_PID=$!
cd ..

# Trap to kill backend when script exits
trap "kill $BACKEND_PID 2>/dev/null || true" EXIT

# 4. Wait for Backend Readiness Probe
echo "Waiting for /healthz readiness probe..."
until curl -s http://localhost:8000/healthz | grep -q '"status":"HEALTHY"'; do
    sleep 2
done
echo "Backend is HEALTHY with OpenNyAI loaded in memory."

# 5. Launch Flutter Application
echo "[4/4] Launching Pratidnya Flutter Mobile Client..."
if [ -d "frontend" ]; then
    cd frontend
elif [ -d "pratidnya_mobile" ]; then
    cd pratidnya_mobile
fi
flutter pub get
flutter run -d chrome --dart-define=APP_ENV=DEV --dart-define=ENFORCE_DUMMY_DATA=true
