# Enciende el backend de Vital Guard con un solo comando.
# Uso (desde la carpeta vital-guard):
#   powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-backend.ps1
#   powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-backend.ps1 -Fcm      (con Firebase)
# La contrasena de PostgreSQL se pide al iniciar (no se guarda en el script).
param(
    [string]$DbUser = "postgres",
    [string]$DbPassword = "",
    [string]$Port = "8081",
    [switch]$Fcm
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\backend")

if ([string]::IsNullOrEmpty($DbPassword)) {
    $secure = Read-Host "Contrasena de PostgreSQL (usuario $DbUser)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $DbPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$env:DB_USER = $DbUser
$env:DB_PASSWORD = $DbPassword
$env:SERVER_PORT = $Port

if ($Fcm) {
    $key = Join-Path $HOME "vital-guard-secrets\firebase-service-account.json"
    if (-not (Test-Path $key)) {
        Write-Host "No se encontro la credencial de Firebase en: $key" -ForegroundColor Red
        exit 1
    }
    $env:FCM_ENABLED = "true"
    $env:FCM_SERVICE_ACCOUNT_PATH = $key
    Write-Host "Notificaciones: Firebase (FCM) ACTIVADO" -ForegroundColor Green
} else {
    Write-Host "Notificaciones: simuladas (usa -Fcm para activar Firebase)" -ForegroundColor Yellow
}

Write-Host "Iniciando el backend en el puerto $Port ... (espera 'Started VitalGuardApplication')"
mvn spring-boot:run
