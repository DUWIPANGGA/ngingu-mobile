# Ngingu — jalan sekali klik: backend + emulator + app.
# Cara pakai: klik kanan file ini > "Run with PowerShell".

$ErrorActionPreference = 'Stop'
$mobile = $PSScriptRoot
$backend = Join-Path (Split-Path $mobile -Parent) 'Kaliwedi-Backend'

# 1. Backend Laravel (jendela baru, biarkan terbuka)
$serveRunning = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if (-not $serveRunning) {
  Start-Process powershell -ArgumentList '-NoExit', '-Command', "cd '$backend'; php artisan serve --host=0.0.0.0 --port=8000"
  Write-Host '[1/3] Backend dinyalakan...' -ForegroundColor Green
} else {
  Write-Host '[1/3] Backend sudah jalan.' -ForegroundColor Green
}

# 2. Emulator (nyalakan bila belum siap; tunggu sampai penuh boot)
Set-Location $mobile
function Test-EmuReady {
  $online = @(adb devices 2>$null | Select-String 'emulator-5554\s+device')
  if (-not $online) { return $false }
  $boot = (adb shell getprop sys.boot_completed 2>$null) -match '1'
  return [bool]$boot
}
if (-not (Test-EmuReady)) {
  Write-Host '[2/3] Menyalakan emulator...' -ForegroundColor Yellow
  $emuExe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\emulator\emulator.exe'
  $qemu = Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue
  if (-not $qemu) {
    Start-Process $emuExe -ArgumentList '-avd', 'Pixel_API34'
  } else {
    adb reconnect offline 2>$null | Out-Null
  }
  $ready = $false
  for ($i = 0; $i -lt 60 -and -not $ready; $i++) {
    Start-Sleep 10
    $ready = Test-EmuReady
  }
  if (-not $ready) { throw 'Emulator tidak siap setelah 10 menit. Coba wipe data via Device Manager.' }
}
Write-Host '[2/3] Emulator siap.' -ForegroundColor Green

# 3. App
Write-Host '[3/3] Menjalankan app...' -ForegroundColor Cyan
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8000/api
