# Helper script to run the Flutter app against the deployed API by default.
# Usage:
#   .\run_dev.ps1                 -> https://ngingu.duvi.asia/api (deployed)
#   .\run_dev.ps1 -Local          -> local backend (detected IP / emulator loopback)
#   .\run_dev.ps1 -ApiUrl <url>   -> custom API base URL
param(
    [string]$ApiUrl,
    [switch]$Local
)

# Set output encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ($ApiUrl) {
    # Explicit URL wins.
} elseif ($Local) {
    # Get the first active IPv4 address from Wi-Fi or Ethernet
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -match "Wi-Fi|Ethernet|LAN" -and $_.IPAddress -notmatch "^169\.254|^127"
    } | Select-Object -First 1).IPAddress

    # Fallback to emulator host loopback if no network IP is found
    if (-not $ipAddress) {
        $ipAddress = "10.0.2.2"
        Write-Warning "[WARNING] Tidak dapat mendeteksi IP Wi-Fi/Ethernet. Menggunakan default emulator: $ipAddress"
    } else {
        Write-Host "[INFO] IP Lokal terdeteksi: $ipAddress" -ForegroundColor Green
    }

    $ApiUrl = "http://${ipAddress}:8000/api"
} else {
    $ApiUrl = "https://ngingu.duvi.asia/api"
}

Write-Host "[RUN] Menjalankan Flutter dengan API_URL: $ApiUrl" -ForegroundColor Cyan

# Run Flutter with the injected API URL (and disable CORS on web for dev)
flutter run --dart-define=API_URL=$ApiUrl --web-browser-flag "--disable-web-security" @args
