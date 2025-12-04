# Rebuild Mobile App - Fix Notification Alert Issue
# This script rebuilds the mobile app with the notification channel fix

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Rebuilding Mobile App with Alert Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$mobileAppPath = "lspu_dres\mobile_app"

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter is installed" -ForegroundColor Green
Write-Host ""

# Navigate to mobile app directory
Write-Host "Navigating to mobile app directory..." -ForegroundColor Yellow
Set-Location $mobileAppPath
Write-Host "✅ In directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build APK
Write-Host "Building APK (this may take a few minutes)..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host ""

# Copy APK to root directory with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
$apkDestination = "..\..\app-release-NOTIFICATION-FIX-$timestamp.apk"

Write-Host "Copying APK to root directory..." -ForegroundColor Yellow
Copy-Item $apkSource $apkDestination -Force
if ($LASTEXITCODE -ne 0 -and -not (Test-Path $apkDestination)) {
    Write-Host "⚠️ Could not copy APK to root directory" -ForegroundColor Yellow
    Write-Host "APK location: $apkSource" -ForegroundColor Yellow
} else {
    Write-Host "✅ APK copied to: $apkDestination" -ForegroundColor Green
}
Write-Host ""

# Show APK location
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "APK Locations:" -ForegroundColor Yellow
Write-Host "  1. $apkSource" -ForegroundColor White
if (Test-Path $apkDestination) {
    Write-Host "  2. $apkDestination" -ForegroundColor White
}
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Uninstall the old app from your device" -ForegroundColor White
Write-Host "  2. Install the new APK" -ForegroundColor White
Write-Host "  3. Open the app and log in" -ForegroundColor White
Write-Host "  4. Make sure to grant notification permissions" -ForegroundColor White
Write-Host "  5. Send a test earthquake alert from the web admin" -ForegroundColor White
Write-Host ""
Write-Host "To install via USB:" -ForegroundColor Yellow
Write-Host "  adb install -r $apkSource" -ForegroundColor Cyan
Write-Host ""

# Return to original directory
Set-Location ..\..

