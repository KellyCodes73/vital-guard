# Construye la app para Android y la instala en el telefono conectado por USB.
# La direccion del servidor se configura DENTRO de la app (login -> Servidor), no hace falta recompilar.
# Uso (desde la carpeta vital-guard):
#   powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1            (version release)
#   powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1 -Debug     (si release falla)
param([switch]$Debug)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\mobile")

if ($Debug) { $mode = "--debug"; $apk = "build\app\outputs\flutter-apk\app-debug.apk" }
else        { $mode = "--release"; $apk = "build\app\outputs\flutter-apk\app-release.apk" }

Write-Host "Construyendo APK ($mode). La primera vez puede tardar varios minutos..." -ForegroundColor Cyan
flutter build apk $mode
if (-not (Test-Path $apk)) {
    Write-Host "No se genero el APK. Revisa los errores de arriba." -ForegroundColor Red
    exit 1
}

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
Write-Host "Instalando en el telefono..." -ForegroundColor Cyan
& $adb install -r $apk
Write-Host "Listo. Abre la app 'vital_guard' en el telefono." -ForegroundColor Green
