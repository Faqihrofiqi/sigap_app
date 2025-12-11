# ============================================
# Fix Trust Location Package Namespace Issue
# ============================================
# Script ini memperbaiki error namespace pada package trust_location
# Jalankan script ini setelah menjalankan 'flutter pub get'
# ============================================

$trustLocationPath = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\trust_location-2.0.13\android\build.gradle"

if (Test-Path $trustLocationPath) {
    Write-Host "Memperbaiki trust_location package..." -ForegroundColor Yellow
    
    $content = Get-Content $trustLocationPath -Raw
    
    # Cek apakah namespace sudah ada
    if ($content -notmatch "namespace\s+'com\.wongpiwat\.trust_location'") {
        # Tambahkan namespace setelah android {
        $content = $content -replace "(android\s+\{)", "`$1`n    namespace 'com.wongpiwat.trust_location'"
        
        Set-Content -Path $trustLocationPath -Value $content -NoNewline
        Write-Host "✅ Namespace berhasil ditambahkan!" -ForegroundColor Green
    } else {
        Write-Host "✅ Namespace sudah ada, tidak perlu diperbaiki." -ForegroundColor Green
    }
} else {
    Write-Host "❌ File build.gradle tidak ditemukan di: $trustLocationPath" -ForegroundColor Red
    Write-Host "Pastikan sudah menjalankan 'flutter pub get' terlebih dahulu." -ForegroundColor Yellow
}

Write-Host "`nSelesai! Sekarang coba jalankan 'flutter run' lagi." -ForegroundColor Cyan

