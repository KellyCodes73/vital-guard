# Abre el puerto 8081 del Firewall de Windows para que el telefono llegue al backend por Wi-Fi.
# EJECUTAR EN "Windows PowerShell (Administrador)":
#   powershell -ExecutionPolicy Bypass -File .\scripts\abrir-firewall.ps1
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ejecuta este script desde PowerShell como ADMINISTRADOR." -ForegroundColor Red
    exit 1
}
$name = "Vital Guard 8081"
if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
    Write-Host "La regla '$name' ya existe." -ForegroundColor Yellow
} else {
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort 8081 -Action Allow -Profile Any | Out-Null
    Write-Host "Regla creada: puerto 8081 abierto. Al terminar la exposicion ejecuta cerrar-firewall.ps1" -ForegroundColor Green
}
