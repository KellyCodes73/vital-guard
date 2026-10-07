# Cierra el puerto 8081 (elimina la regla creada por abrir-firewall.ps1).
# EJECUTAR EN "Windows PowerShell (Administrador)":
#   powershell -ExecutionPolicy Bypass -File .\scripts\cerrar-firewall.ps1
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ejecuta este script desde PowerShell como ADMINISTRADOR." -ForegroundColor Red
    exit 1
}
$name = "Vital Guard 8081"
if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
    Remove-NetFirewallRule -DisplayName $name
    Write-Host "Regla eliminada: puerto 8081 cerrado." -ForegroundColor Green
} else {
    Write-Host "No existia la regla '$name'." -ForegroundColor Yellow
}
