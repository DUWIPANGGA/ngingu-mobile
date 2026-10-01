# Helper script to automatically run Flutter with the developer's local IP address
# Usage: .\run_dev.ps1

# Set output encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

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

# Sesuaikan path '/api' atau '/api/mobile' dengan route Laravel kamu nantinya
$apiUrl = "http://${ipAddress}:8000/api"
Write-Host "[RUN] Menjalankan Flutter dengan API_URL: $apiUrl" -ForegroundColor Cyan

# Run Flutter with the dynamically injected API URL (and disable CORS on web for dev)
flutter run --dart-define=API_URL=$apiUrl --web-browser-flag "--disable-web-security" @args

