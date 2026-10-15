# Construye la app para Android y la instala en el telefono conectado por USB.
# Con -ApiUrl la app queda apuntando a esa direccion por defecto (p. ej. la nube).
# Uso (desde la carpeta vital-guard):
#   powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1 -ApiUrl https://vitalguard-backend.onrender.com
#   powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1                (sin -ApiUrl: usa localhost)
#   Agrega -Debug si la version release falla.
param([switch]$Debug, [string]$ApiUrl = "")

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\mobile")

if ($Debug) { $mode = "--debug"; $apk = "build\app\outputs\flutter-apk\app-debug.apk" }
else        { $mode = "--release"; $apk = "build\app\outputs\flutter-apk\app-release.apk" }

$extra = @()
if ($ApiUrl -ne "") {
    $ApiUrl = $ApiUrl.TrimEnd('/')
    $extra += "--dart-define=API_BASE_URL=$ApiUrl"
    Write-Host "La app apuntara por defecto a: $ApiUrl" -ForegroundColor Cyan
}

Write-Host "Construyendo APK ($mode). La primera vez puede tardar varios minutos..." -ForegroundColor Cyan
flutter build apk $mode @extra
if (-not (Test-Path $apk)) {
    Write-Host "No se genero el APK. Revisa los errores de arriba." -ForegroundColor Red
    exit 1
}

$full = (Resolve-Path $apk).Path
Write-Host "APK listo: $full" -ForegroundColor Green

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$devices = & $adb devices | Select-String -Pattern "\tdevice$"
if ($devices) {
    Write-Host "Instalando en el telefono conectado..." -ForegroundColor Cyan
    & $adb install -r $apk
    Write-Host "Listo. Abre la app 'vital_guard' en el telefono." -ForegroundColor Green
} else {
    Write-Host "No hay telefono conectado por USB: solo se genero el APK (para compartirlo)." -ForegroundColor Yellow
}
