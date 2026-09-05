# ==================================================================
# PRATIDNYA LEGAL TECH — LOCAL RUNTIME BOOTSTRAP (ASIVERTICALS)
# ==================================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "PRATIDNYA LEGAL TECH — LOCAL RUNTIME BOOTSTRAP (WINDOWS POWERSHELL)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Check Python Environment
Write-Host "[1/4] Checking Python Backend Dependencies..." -ForegroundColor Green
Set-Location pratidnya_backend
if (-not (Test-Path "venv")) {
    python -m venv venv
}
if (Test-Path "venv\Scripts\Activate.ps1") {
    & ".\venv\Scripts\Activate.ps1"
}
pip install -q -r requirements.txt
Set-Location ..

# 2. Check Supabase Migrations
Write-Host "[2/4] Verifying Supabase Migrations..." -ForegroundColor Green
if (Get-Command "supabase" -ErrorAction SilentlyContinue) {
    supabase db push
} else {
    Write-Host "Supabase CLI not found in PATH. Ensure migrations in supabase/migrations/ are applied." -ForegroundColor Yellow
}

# 3. Launch Backend Microservice
Write-Host "[3/4] Starting FastAPI Microservice (Port 8000)..." -ForegroundColor Green
$backendProcess = Start-Process python -ArgumentList "-m uvicorn app.main:app --host 0.0.0.0 --port 8000" -WorkingDirectory "pratidnya_backend" -PassThru

# 4. Wait for /healthz probe
Write-Host "Waiting for /healthz readiness probe..." -ForegroundColor Yellow
$healthy = $false
$retries = 0
while (-not $healthy -and $retries -lt 30) {
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:8000/healthz" -Method Get -TimeoutSec 2
        if ($res.status -eq "HEALTHY") {
            $healthy = $true
        }
    } catch {
        Start-Sleep -Seconds 2
        $retries++
    }
}

if ($healthy) {
    Write-Host "Backend is HEALTHY with OpenNyAI loaded in memory!" -ForegroundColor Green
} else {
    Write-Host "Warning: Backend probe timeout or unhealthy." -ForegroundColor Red
}

# 5. Launch Flutter
Write-Host "[4/4] Launching Pratidnya Flutter Client..." -ForegroundColor Green
if (Test-Path "frontend") {
    Set-Location frontend
} elseif (Test-Path "pratidnya_mobile") {
    Set-Location pratidnya_mobile
}
flutter pub get
flutter run -d chrome --dart-define=APP_ENV=DEV --dart-define=ENFORCE_DUMMY_DATA=true
