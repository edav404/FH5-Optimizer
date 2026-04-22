<#
.SYNOPSIS
    FH5 Game Optimizer — Script de Restauración de Emergencia
    Restaura todos los cambios realizados por FH5-GameOptimizer.ps1

.DESCRIPTION
    Si el script principal fue interrumpido abruptamente o si deseas
    revertir manualmente los cambios, ejecuta este script como Administrador.
    Restaura: plan de energía, servicios, red, notificaciones, y prioridades.

.NOTES
    Ejecutar como Administrador
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   FH5 Optimizer — Restauración de Emergencia    ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Write-Status {
    param([string]$Message, [string]$Status = "OK")
    $color = switch ($Status) {
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "INFO"  { "Cyan" }
    }
    Write-Host "  [$Status] $Message" -ForegroundColor $color
}

# ─── 1. Restaurar Plan de Energía ───
Write-Status "Restaurando plan de energía..." "INFO"
try {
    # Intentar restaurar al plan "Equilibrado" (predeterminado de Windows)
    $balancedGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
    powercfg /setactive $balancedGUID 2>$null
    # Restaurar timeouts por defecto
    powercfg /change disk-timeout-ac 20
    powercfg /change standby-timeout-ac 30
    powercfg /change monitor-timeout-ac 10
    Write-Status "Plan de energía restaurado a Equilibrado" "OK"
} catch {
    Write-Status "No se pudo restaurar plan de energía: $($_.Exception.Message)" "WARN"
}

# ─── 2. Reiniciar Servicios ───
Write-Status "Reiniciando servicios..." "INFO"
$servicios = @(
    "SysMain", "DiagTrack", "WSearch", "MapsBroker",
    "TabletInputService", "WMPNetworkSvc", "dmwappushservice",
    "lfsvc", "RetailDemo", "wisvc"
)

foreach ($svc in $servicios) {
    try {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne "Running") {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-Status "Servicio reiniciado: $svc" "OK"
        } elseif ($service) {
            Write-Status "Servicio ya ejecutándose: $svc" "INFO"
        }
    } catch {
        Write-Status "No se pudo reiniciar $svc (puede no existir)" "WARN"
    }
}

# ─── 3. Restaurar Red ───
Write-Status "Restaurando configuración de red..." "INFO"
try {
    # Restaurar autotuning
    netsh interface tcp set global autotuninglevel=normal 2>$null | Out-Null
    Write-Status "Auto-tuning de red restaurado" "OK"

    # Limpiar TcpNoDelay y TcpAckFrequency de todas las interfaces
    $interfaces = Get-NetAdapter -ErrorAction SilentlyContinue
    foreach ($iface in $interfaces) {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($iface.InterfaceGuid)"
        if (Test-Path $regPath) {
            Remove-ItemProperty -Path $regPath -Name "TcpNoDelay" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        }
    }
    Write-Status "Configuración de red limpiada" "OK"
} catch {
    Write-Status "Error restaurando red: $($_.Exception.Message)" "WARN"
}

# ─── 4. Restaurar Notificaciones ───
Write-Status "Restaurando notificaciones..." "INFO"
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
    Set-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Status "Notificaciones restauradas" "OK"
} catch {
    Write-Status "Error restaurando notificaciones: $($_.Exception.Message)" "WARN"
}

# ─── 5. Restaurar Last Access Timestamp ───
Write-Status "Restaurando Last Access Timestamp..." "INFO"
try {
    fsutil behavior set disableLastAccess 0 | Out-Null
    Write-Status "Last Access Timestamp restaurado" "OK"
} catch {
    Write-Status "Error restaurando filesystem: $($_.Exception.Message)" "WARN"
}

# ─── 6. Restaurar Prioridades de Procesos ───
Write-Status "Restaurando prioridades de procesos..." "INFO"
$fh5Names = @("ForzaHorizon5", "forza_horizon_5", "GameLaunchHelper")
foreach ($name in $fh5Names) {
    $proc = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($proc) {
        try {
            $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
            Write-Status "FH5 restaurado a prioridad Normal" "OK"
        } catch {}
    }
}

$spotify = Get-Process -Name "Spotify" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($spotify) {
    try {
        $spotify.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
        $spotify.ProcessorAffinity = [IntPtr]0xFF
        Write-Status "Spotify restaurado: prioridad Normal, todos los núcleos" "OK"
    } catch {}
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   ✓ RESTAURACIÓN COMPLETA                       ║" -ForegroundColor Green
Write-Host "  ║   Tu sistema está en su configuración original.  ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Read-Host "Presiona Enter para cerrar"
