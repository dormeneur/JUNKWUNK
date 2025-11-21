# Theme System Verification Script
# This script checks for hardcoded colors in the codebase

Write-Host "=== Theme System Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check for hardcoded Color(0x constructors
Write-Host "Checking for hardcoded Color(0x constructors..." -ForegroundColor Yellow
$hardcodedColors = Select-String -Path "lib\**\*.dart" -Pattern "Color\(0x" -Exclude "colors.dart","design_constants.dart"

if ($hardcodedColors) {
    Write-Host "WARNING: Found hardcoded colors:" -ForegroundColor Red
    $hardcodedColors | ForEach-Object {
        Write-Host "  $($_.Filename):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor Yellow
    }
    $colorCount = ($hardcodedColors | Measure-Object).Count
    Write-Host "Total: $colorCount instances" -ForegroundColor Red
} else {
    Write-Host "✓ No hardcoded Color(0x constructors found" -ForegroundColor Green
}

Write-Host ""

# Check for Flutter Colors.* usage
Write-Host "Checking for Flutter Colors.* usage..." -ForegroundColor Yellow
$flutterColors = Select-String -Path "lib\**\*.dart" -Pattern "Colors\." -Exclude "colors.dart","design_constants.dart"

if ($flutterColors) {
    Write-Host "WARNING: Found Flutter Colors.* usage:" -ForegroundColor Red
    $flutterColors | ForEach-Object {
        Write-Host "  $($_.Filename):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor Yellow
    }
    $flutterColorCount = ($flutterColors | Measure-Object).Count
    Write-Host "Total: $flutterColorCount instances" -ForegroundColor Red
} else {
    Write-Host "✓ No Flutter Colors.* usage found" -ForegroundColor Green
}

Write-Host ""

# Run theme system tests
Write-Host "Running theme system tests..." -ForegroundColor Yellow
flutter test test/theme_system_verification_test.dart --no-pub

Write-Host ""
Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
