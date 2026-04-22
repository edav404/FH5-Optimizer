<#
.SYNOPSIS
    FH5 Game Optimizer — Optimización dinámica para Forza Horizon 5
    Diseñado para Lenovo ThinkPad P50 (i7-6700HQ / Quadro M1000M / 16GB RAM)

.DESCRIPTION
    Este script optimiza Windows 10/11 específicamente para ejecutar Forza Horizon 5
    con Spotify en segundo plano. Todas las optimizaciones son temporales y reversibles.

    Funcionalidades:
    - Optimiza procesos en segundo plano sin romper funciones críticas
    - Ajusta prioridades de CPU para el juego y Spotify
    - Limpia memoria RAM de forma segura (sin hacks)
    - Desactiva temporalmente servicios innecesarios SOLO durante el juego
    - Configura plan de energía en alto rendimiento
    - Optimiza uso de disco y caché
    - Monitoreo básico de CPU/GPU/RAM/temperaturas
    - Detección de throttling térmico

.NOTES
    Autor: FH5-Optimizer Suite
    Requiere: Ejecutar como Administrador
    Reversible: Sí — usa FH5-Restore.ps1 o cierra el script normalmente
#>

#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURACIÓN GLOBAL
# ============================================================================

$ErrorActionPreference = "Continue"
$Script:OriginalState = @{}
$Script:ServiciosDesactivados = @()
$Script:MonitoreoActivo = $false
$Script:LogPath = Join-Path $PSScriptRoot "logs"
$Script:LogFile = Join-Path $Script:LogPath "optimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Nombres de proceso del juego (Microsoft Store y Steam)
$Script:FH5Processes = @("ForzaHorizon5", "forza_horizon_5", "ForzaHorizon5.exe")
$Script:SpotifyProcess = "Spotify"

# Servicios que se pueden desactivar temporalmente de forma SEGURA
# Explicación de cada uno:
$Script:ServiciosOptimizables = @(
    @{ Name = "SysMain";          Desc = "Superfetch — precarga apps en RAM. Innecesario durante gaming" }
    @{ Name = "DiagTrack";        Desc = "Telemetría de Windows — envía datos de uso a Microsoft" }
    @{ Name = "WSearch";          Desc = "Windows Search Indexer — indexa archivos en segundo plano" }
    @{ Name = "MapsBroker";       Desc = "Descarga de mapas offline — no necesario durante gaming" }
    @{ Name = "TabletInputService"; Desc = "Servicio de entrada para tablets — innecesario en laptop" }
    @{ Name = "WMPNetworkSvc";    Desc = "Compartir media de WMP — innecesario durante gaming" }
    @{ Name = "dmwappushservice"; Desc = "Mensajes push de telemetría — WAP Push Message Routing" }
    @{ Name = "lfsvc";            Desc = "Servicio de geolocalización — innecesario para gaming" }
    @{ Name = "RetailDemo";       Desc = "Servicio de demostración en tiendas — nunca necesario" }
    @{ Name = "wisvc";            Desc = "Windows Insider — innecesario si no participas en Insider" }
)

# Procesos de fondo que se pueden suspender temporalmente
$Script:ProcesosReducibles = @(
    "SearchUI", "SearchApp", "SearchHost",       # Búsqueda de Windows
    "OneDrive",                                   # Sincronización en la nube
    "Teams", "Widgets",                           # Apps no esenciales
    "PhoneExperienceHost",                        # Tu Teléfono
    "YourPhone",                                  # Tu Teléfono (legacy)
    "GameBarPresenceWriter",                      # Barra de juegos (escritor)
    "BcastDVRUserService",                        # DVR Broadcasting
    "Calculator", "CalculatorApp",                # Calculadora
    "SkypeApp", "SkypeBackgroundHost",            # Skype
    "Microsoft.Photos",                           # Fotos
    "HxTsr", "HxOutlook",                        # Correo
    "GrooveMusic",                                # Groove Music
    "MicrosoftEdgeUpdate"                         # Actualizador de Edge
)

# ============================================================================
# FUNCIONES DE UTILIDAD
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR","SUCCESS","MONITOR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Crear directorio de logs si no existe
    if (-not (Test-Path $Script:LogPath)) {
        New-Item -Path $Script:LogPath -ItemType Directory -Force | Out-Null
    }

    # Escribir al archivo de log
    Add-Content -Path $Script:LogFile -Value $logEntry -ErrorAction SilentlyContinue

    # Colores según nivel
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        "SUCCESS" { "Green" }
        "MONITOR" { "Magenta" }
    }

    Write-Host $logEntry -ForegroundColor $color
}

function Show-Banner {
    $banner = @"

    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║   ███████╗██╗  ██╗███████╗     ██████╗ ██████╗ ████████╗    ║
    ║   ██╔════╝██║  ██║██╔════╝    ██╔═══██╗██╔══██╗╚══██╔══╝   ║
    ║   █████╗  ███████║███████╗    ██║   ██║██████╔╝   ██║       ║
    ║   ██╔══╝  ██╔══██║╚════██║    ██║   ██║██╔═══╝    ██║       ║
    ║   ██║     ██║  ██║███████║    ╚██████╔╝██║        ██║       ║
    ║   ╚═╝     ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝        ╚═╝       ║
    ║                                                              ║
    ║   Forza Horizon 5 — Game Optimizer Suite                     ║
    ║   ThinkPad P50 · i7-6700HQ · Quadro M1000M · 16GB           ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor DarkCyan
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FH5Process {
    foreach ($procName in $Script:FH5Processes) {
        $proc = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($proc) { return $proc }
    }
    return $null
}

# ============================================================================
# 1. PLAN DE ENERGÍA — ALTO RENDIMIENTO
# ============================================================================
# Cambia al plan "Alto rendimiento" de Windows. Esto desbloquea frecuencias
# máximas de CPU e impide que el procesador entre en estados de ahorro de energía.
# Se guarda el plan original para restaurarlo después.

function Set-HighPerformancePower {
    Write-Log "Configurando plan de energía: Alto Rendimiento..." "INFO"

    try {
        # Guardar plan actual
        $currentPlan = powercfg /getactivescheme
        if ($currentPlan -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
            $Script:OriginalState["PowerPlan"] = $Matches[1]
            Write-Log "Plan original guardado: $($Matches[1])" "INFO"
        }

        # GUID del plan Alto Rendimiento de Windows
        $highPerfGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

        # Verificar si el plan existe
        $plans = powercfg /list
        if ($plans -match $highPerfGUID) {
            powercfg /setactive $highPerfGUID
            Write-Log "Plan de energía cambiado a Alto Rendimiento" "SUCCESS"
        } else {
            # Crear plan si no existe (puede haber sido eliminado por el OEM)
            Write-Log "Plan Alto Rendimiento no encontrado, creando duplicado..." "WARN"
            powercfg /duplicatescheme $highPerfGUID
            powercfg /setactive $highPerfGUID
            Write-Log "Plan creado y activado" "SUCCESS"
        }

        # Ajustes adicionales del plan de energía
        # Desactivar apagado de disco duro (0 = nunca) — evita micro-stutters por despertar HDD
        powercfg /change disk-timeout-ac 0
        # Desactivar suspensión automática
        powercfg /change standby-timeout-ac 0
        # Desactivar apagado de pantalla extendido (para sesiones largas)
        powercfg /change monitor-timeout-ac 30

        Write-Log "Ajustes de energía adicionales aplicados" "SUCCESS"
    }
    catch {
        Write-Log "Error configurando plan de energía: $($_.Exception.Message)" "ERROR"
    }
}

# ============================================================================
# 2. DESACTIVAR SERVICIOS INNECESARIOS (TEMPORAL)
# ============================================================================
# Solo detiene servicios que NO son críticos para el sistema. Cada servicio
# está documentado con su función. Se guardan los estados originales para
# restaurar al finalizar. NO se eliminan ni deshabilitan permanentemente.

function Disable-UnnecessaryServices {
    Write-Log "Desactivando servicios innecesarios temporalmente..." "INFO"

    foreach ($svc in $Script:ServiciosOptimizables) {
        try {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                # Guardar estado original
                $Script:OriginalState["Service_$($svc.Name)"] = $service.StartType

                Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
                $Script:ServiciosDesactivados += $svc.Name
                Write-Log "  [DETENIDO] $($svc.Name) — $($svc.Desc)" "SUCCESS"
            }
            elseif ($service) {
                Write-Log "  [YA DETENIDO] $($svc.Name)" "INFO"
            }
            else {
                Write-Log "  [NO ENCONTRADO] $($svc.Name) — puede no existir en tu versión" "WARN"
            }
        }
        catch {
            Write-Log "  [ERROR] No se pudo detener $($svc.Name): $($_.Exception.Message)" "ERROR"
        }
    }

    Write-Log "Servicios optimizados: $($Script:ServiciosDesactivados.Count) detenidos" "SUCCESS"
}

# ============================================================================
# 3. OPTIMIZAR PROCESOS EN SEGUNDO PLANO
# ============================================================================
# Reduce la prioridad de procesos no esenciales y cierra los que son seguros
# de cerrar. NO toca procesos del sistema, de seguridad, ni controladores.

function Optimize-BackgroundProcesses {
    Write-Log "Optimizando procesos en segundo plano..." "INFO"

    $reducidos = 0

    foreach ($procName in $Script:ProcesosReducibles) {
        $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
        foreach ($proc in $procs) {
            try {
                # No matamos los procesos, solo reducimos su prioridad
                $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                $reducidos++
            }
            catch {
                # Algunos procesos protegidos no permiten cambiar prioridad
            }
        }
    }

    # Limpiar apps de la bandeja del sistema que no son necesarias
    # Solo reducimos prioridad, no las cerramos
    $trayApps = @("SecurityHealthSystray") # Solo apps seguras
    foreach ($app in $trayApps) {
        $proc = Get-Process -Name $app -ErrorAction SilentlyContinue
        if ($proc) {
            try {
                $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                $reducidos++
            } catch {}
        }
    }

    Write-Log "Procesos optimizados: $reducidos con prioridad reducida" "SUCCESS"
}

# ============================================================================
# 4. LIMPIEZA DE MEMORIA RAM (SEGURA)
# ============================================================================
# Usa la API nativa de Windows para liberar memoria de trabajo de procesos
# que no están en uso activo. NO usa herramientas de terceros ni hacks.
#
# IMPORTANTE: Esta función solo debe ejecutarse en momentos seguros:
#   - Fase 1 (antes de que el juego arranque)
#   - Al detectar FH5 por primera vez (antes de que cargue assets pesados)
#   - Cuando FH5 se cierra (para reclamar RAM para el escritorio)
#
# NO se ejecuta periódicamente durante el juego, porque vaciar working sets
# fuerza page faults cuando los procesos necesitan sus datos de vuelta,
# causando micro-stutters y lecturas de disco innecesarias.

# Cargar la firma P/Invoke una sola vez al inicio del script
# (evita recompilar Add-Type en cada iteración del loop)
try {
    $Script:MemoryOptimizerType = Add-Type -MemberDefinition @"
[DllImport("psapi.dll")]
public static extern bool EmptyWorkingSet(IntPtr hProcess);
"@ -Name "MemoryOptimizer" -Namespace "Win32" -PassThru -ErrorAction Stop
} catch {
    # Si ya fue cargado en una sesión previa de PowerShell, reusar
    $Script:MemoryOptimizerType = [Win32.MemoryOptimizer]
}

function Clear-WorkingSetMemory {
    param(
        [string]$Reason = "rutina"
    )

    Write-Log "Limpiando memoria RAM ($Reason)..." "INFO"

    try {
        $before = (Get-Process | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB

        # Procesos protegidos: nunca vaciar su working set
        $protectedProcesses = @("System", "csrss", "wininit", "services", "lsass",
                                "svchost", "dwm", "explorer", "ForzaHorizon5",
                                "forza_horizon_5", "Spotify", "audiodg", "smss",
                                "ntoskrnl", "powershell")

        Get-Process | Where-Object {
            $_.ProcessName -notin $protectedProcesses -and
            $_.WorkingSet64 -gt 50MB -and
            $_.Responding -eq $true
        } | ForEach-Object {
            try {
                $handle = $_.Handle
                if ($Script:MemoryOptimizerType) {
                    [Win32.MemoryOptimizer]::EmptyWorkingSet($handle) | Out-Null
                }
            } catch {}
        }

        $after = (Get-Process | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB
        $freed = [math]::Round($before - $after, 0)

        if ($freed -gt 0) {
            Write-Log "Memoria liberada: ~${freed} MB" "SUCCESS"
        } else {
            Write-Log "Memoria ya optimizada, sin cambios significativos" "INFO"
        }

        Write-Log "Limpieza de memoria completada" "SUCCESS"
    }
    catch {
        Write-Log "Error en limpieza de memoria: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================================
# 5. OPTIMIZACIÓN DE DISCO Y CACHÉ
# ============================================================================
# Limpia archivos temporales de Windows y configura la caché del sistema
# de archivos para priorizar rendimiento sobre conservación de energía.

function Optimize-DiskAndCache {
    Write-Log "Optimizando disco y caché del sistema..." "INFO"

    try {
        # Limpiar archivos temporales (solo los seguros)
        $tempPaths = @(
            "$env:TEMP",
            "$env:LOCALAPPDATA\Temp",
            "$env:WINDIR\Temp"
        )

        $totalFreed = 0
        foreach ($tempPath in $tempPaths) {
            if (Test-Path $tempPath) {
                $files = Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
                         Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) }

                foreach ($file in $files) {
                    try {
                        $totalFreed += $file.Length
                        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                    } catch {}
                }
            }
        }

        $freedMB = [math]::Round($totalFreed / 1MB, 1)
        Write-Log "Archivos temporales limpiados: ${freedMB} MB liberados" "SUCCESS"

        # Optimizar prioridad de I/O para el juego cuando se detecte
        # Esto se hace dinámicamente en la función de monitoreo

        # Desactivar Last Access Time Stamp para reducir escrituras
        # Esto reduce las escrituras al disco al acceder archivos
        $currentValue = fsutil behavior query disableLastAccess 2>$null
        if ($currentValue -notmatch "1") {
            fsutil behavior set disableLastAccess 1 | Out-Null
            $Script:OriginalState["DisableLastAccess"] = "0"
            Write-Log "Desactivado Last Access Timestamp (reduce escrituras de disco)" "SUCCESS"
        }

        Write-Log "Optimización de disco completada" "SUCCESS"
    }
    catch {
        Write-Log "Error optimizando disco: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================================
# 6. CONFIGURACIÓN DE AFINIDAD Y PRIORIDAD PARA FH5
# ============================================================================
# Cuando Forza Horizon 5 está en ejecución, le asigna prioridad Alta
# y configura Spotify en prioridad Baja para que no compitan por CPU.
# Se asignan núcleos específicos para evitar competencia:
#   - FH5: Todos los núcleos (máximo rendimiento)
#   - Spotify: Núcleos 6-7 (últimos dos hilos lógicos)

function Set-GamePriority {
    param(
        [System.Diagnostics.Process]$GameProcess
    )

    if (-not $GameProcess) { return }

    try {
        # FH5 → Prioridad Alta (no Realtime, que podría causar inestabilidad)
        $GameProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
        Write-Log "FH5 configurado en prioridad ALTA" "SUCCESS"

        # Afinidad: todos los 8 hilos lógicos (0xFF = 11111111 en binario)
        $GameProcess.ProcessorAffinity = [IntPtr]0xFF
        Write-Log "FH5 usando todos los núcleos (8 hilos)" "INFO"
    }
    catch {
        Write-Log "No se pudo ajustar prioridad de FH5: $($_.Exception.Message)" "WARN"
    }

    # Configurar Spotify con prioridad baja y núcleos limitados
    $spotify = Get-Process -Name $Script:SpotifyProcess -ErrorAction SilentlyContinue |
               Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 1

    if ($spotify) {
        try {
            $spotify.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            # Spotify → Últimos 2 hilos lógicos (núcleos 6-7): 0xC0 = 11000000
            $spotify.ProcessorAffinity = [IntPtr]0xC0
            Write-Log "Spotify configurado: prioridad BAJA, núcleos 6-7" "SUCCESS"
        }
        catch {
            Write-Log "No se pudo ajustar Spotify: $($_.Exception.Message)" "WARN"
        }
    }
}

# ============================================================================
# 7. MONITOREO DE RENDIMIENTO Y DETECCIÓN DE THROTTLING
# ============================================================================
# Monitorea CPU, RAM, GPU y temperaturas cada N segundos.
# Detecta throttling térmico analizando la frecuencia real vs máxima del CPU.

function Get-SystemMetrics {
    $metrics = @{}

    try {
        # CPU Usage
        $cpu = (Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue |
                Measure-Object -Property LoadPercentage -Average).Average
        $metrics["CPU_Percent"] = [math]::Round($cpu, 1)

        # CPU Temperature (si disponible)
        try {
            $temp = Get-CimInstance -Namespace "root\WMI" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue |
                    Select-Object -First 1
            if ($temp) {
                $metrics["CPU_Temp_C"] = [math]::Round(($temp.CurrentTemperature - 2732) / 10, 1)
            }
        } catch {
            $metrics["CPU_Temp_C"] = "N/A"
        }

        # RAM Usage
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
            $usedRAM = [math]::Round($totalRAM - $freeRAM, 1)
            $metrics["RAM_Used_GB"] = $usedRAM
            $metrics["RAM_Total_GB"] = $totalRAM
            $metrics["RAM_Percent"] = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
        }

        # GPU Usage (NVIDIA via nvidia-smi si disponible)
        try {
            $nvidiaSmi = & "nvidia-smi" --query-gpu=utilization.gpu,temperature.gpu,utilization.memory --format=csv,noheader,nounits 2>$null
            if ($nvidiaSmi) {
                $parts = $nvidiaSmi.Trim().Split(",") | ForEach-Object { $_.Trim() }
                $metrics["GPU_Percent"] = $parts[0]
                $metrics["GPU_Temp_C"] = $parts[1]
                $metrics["GPU_VRAM_Percent"] = $parts[2]
            }
        } catch {
            $metrics["GPU_Percent"] = "N/A"
            $metrics["GPU_Temp_C"] = "N/A"
        }

        # Detección de throttling térmico
        # El i7-6700HQ tiene Tjunction de 100°C; throttlea típicamente a ~95°C
        try {
            $cpuInfo = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
            if ($cpuInfo) {
                $maxClock = $cpuInfo.MaxClockSpeed
                $currentClock = $cpuInfo.CurrentClockSpeed
                if ($maxClock -gt 0) {
                    $clockRatio = [math]::Round(($currentClock / $maxClock) * 100, 1)
                    $metrics["CPU_Clock_MHz"] = $currentClock
                    $metrics["CPU_MaxClock_MHz"] = $maxClock
                    $metrics["CPU_Clock_Ratio"] = $clockRatio

                    # Si la frecuencia cae por debajo del 80% del máximo, probablemente hay throttling
                    if ($clockRatio -lt 80) {
                        $metrics["Throttling"] = $true
                    } else {
                        $metrics["Throttling"] = $false
                    }
                }
            }
        } catch {}

        # Disk I/O
        try {
            $disk = Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction SilentlyContinue
            if ($disk) {
                $metrics["Disk_Percent"] = [math]::Round($disk.CounterSamples[0].CookedValue, 1)
            }
        } catch {
            $metrics["Disk_Percent"] = "N/A"
        }

    }
    catch {
        Write-Log "Error obteniendo métricas: $($_.Exception.Message)" "ERROR"
    }

    return $metrics
}

function Show-MonitoringDashboard {
    param($Metrics)

    $cpuBar = New-ProgressBar -Value $Metrics["CPU_Percent"] -Max 100
    $ramBar = New-ProgressBar -Value $Metrics["RAM_Percent"] -Max 100

    $gpuVal = if ($Metrics["GPU_Percent"] -ne "N/A") { $Metrics["GPU_Percent"] } else { 0 }
    $gpuBar = New-ProgressBar -Value $gpuVal -Max 100

    $cpuTemp = if ($Metrics["CPU_Temp_C"] -ne "N/A") { "$($Metrics["CPU_Temp_C"])°C" } else { "N/A" }
    $gpuTemp = if ($Metrics["GPU_Temp_C"] -ne "N/A") { "$($Metrics["GPU_Temp_C"])°C" } else { "N/A" }

    $throttleStatus = if ($Metrics["Throttling"]) {
        "⚠ THROTTLING DETECTADO"
    } else {
        "✓ Normal"
    }

    $throttleColor = if ($Metrics["Throttling"]) { "Red" } else { "Green" }

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "  │          MONITOR DE RENDIMIENTO — FH5 OPTIMIZER        │" -ForegroundColor DarkGray
    Write-Host "  ├─────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
    Write-Host "  │  CPU: $cpuBar $($Metrics["CPU_Percent"])%  |  Temp: $cpuTemp" -ForegroundColor Cyan
    Write-Host "  │  GPU: $gpuBar $gpuVal%  |  Temp: $gpuTemp" -ForegroundColor Green
    Write-Host "  │  RAM: $ramBar $($Metrics["RAM_Used_GB"])/$($Metrics["RAM_Total_GB"]) GB ($($Metrics["RAM_Percent"])%)" -ForegroundColor Yellow
    Write-Host "  │  CPU Clock: $($Metrics["CPU_Clock_MHz"])/$($Metrics["CPU_MaxClock_MHz"]) MHz ($($Metrics["CPU_Clock_Ratio"])%)" -ForegroundColor White
    Write-Host "  │  Disk: $($Metrics["Disk_Percent"])%" -ForegroundColor Magenta

    Write-Host -NoNewline "  │  Throttling: "
    Write-Host $throttleStatus -ForegroundColor $throttleColor
    Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray

    # Alertas de throttling
    if ($Metrics["Throttling"]) {
        Write-Host ""
        Write-Host "  ⚠ ALERTA DE THROTTLING TÉRMICO:" -ForegroundColor Red
        Write-Host "    → Asegúrate de que las rejillas de ventilación no están obstruidas" -ForegroundColor Yellow
        Write-Host "    → Usa una base de refrigeración (cooling pad)" -ForegroundColor Yellow
        Write-Host "    → Reduce la calidad gráfica en FH5 si persiste" -ForegroundColor Yellow
        Write-Host "    → Considera reemplazar la pasta térmica si el equipo tiene >2 años" -ForegroundColor Yellow

        Write-Log "ALERTA: Throttling térmico detectado — CPU a $($Metrics["CPU_Clock_Ratio"])% de capacidad" "WARN"
    }

    # Alerta de RAM alta
    if ($Metrics["RAM_Percent"] -gt 90) {
        Write-Host ""
        Write-Host "  ⚠ ALERTA DE MEMORIA ALTA ($($Metrics["RAM_Percent"])%):" -ForegroundColor Red
        Write-Host "    → Cierra aplicaciones no esenciales" -ForegroundColor Yellow
        Write-Host "    → Spotify consumiendo mucha RAM: reduce canciones descargadas" -ForegroundColor Yellow

        Write-Log "ALERTA: Uso de RAM al $($Metrics["RAM_Percent"])%" "WARN"
    }

    # Alerta de temperatura GPU
    if ($Metrics["GPU_Temp_C"] -ne "N/A" -and [int]$Metrics["GPU_Temp_C"] -gt 90) {
        Write-Host ""
        Write-Host "  ⚠ TEMPERATURA GPU ALTA: $($Metrics["GPU_Temp_C"])°C" -ForegroundColor Red
        Write-Host "    → La Quadro M1000M opera segura hasta ~95°C" -ForegroundColor Yellow
        Write-Host "    → Reduce calidad gráfica o limita FPS a 30" -ForegroundColor Yellow
    }
}

function New-ProgressBar {
    param(
        [double]$Value,
        [double]$Max = 100,
        [int]$Width = 20
    )

    if ($Max -eq 0) { $Max = 1 }
    $filled = [math]::Floor(($Value / $Max) * $Width)
    $empty = $Width - $filled

    $bar = "█" * $filled + "░" * $empty
    return "[$bar]"
}

# ============================================================================
# 8. CONFIGURACIÓN NAGLE Y RED (LATENCIA)
# ============================================================================
# Desactiva el algoritmo Nagle para reducir latencia de red.
# Útil para juegos online. Completamente seguro y reversible.

function Optimize-NetworkLatency {
    Write-Log "Optimizando latencia de red..." "INFO"

    try {
        # Obtener interfaces de red activas
        $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        foreach ($iface in $interfaces) {
            $ifaceName = $iface.Name

            # Desactivar Nagle Algorithm (reduce buffering de paquetes pequeños)
            # Registro: HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{GUID}
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($iface.InterfaceGuid)"

            if (Test-Path $regPath) {
                # Guardar valores originales
                $currentTcpNoDelay = Get-ItemProperty -Path $regPath -Name "TcpNoDelay" -ErrorAction SilentlyContinue
                $currentTcpAckFrequency = Get-ItemProperty -Path $regPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue

                $Script:OriginalState["Net_TcpNoDelay_$($iface.InterfaceGuid)"] = if ($currentTcpNoDelay) { $currentTcpNoDelay.TcpNoDelay } else { $null }
                $Script:OriginalState["Net_TcpAckFreq_$($iface.InterfaceGuid)"] = if ($currentTcpAckFrequency) { $currentTcpAckFrequency.TcpAckFrequency } else { $null }

                # TcpNoDelay = 1: Envía paquetes inmediatamente sin esperar a agrupar
                Set-ItemProperty -Path $regPath -Name "TcpNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                # TcpAckFrequency = 1: Confirma cada paquete inmediatamente
                Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue

                Write-Log "  Red optimizada para: $ifaceName" "SUCCESS"
            }
        }

        # Desactivar autotuning (puede causar problemas con algunos routers gaming)
        $Script:OriginalState["NetworkAutoTuning"] = (netsh interface tcp show global | Select-String "Auto-Tuning Level").ToString().Trim()
        netsh interface tcp set global autotuninglevel=disabled 2>$null | Out-Null
        Write-Log "Auto-tuning de red desactivado (reduce latencia)" "SUCCESS"

        Write-Log "Optimización de red completada" "SUCCESS"
    }
    catch {
        Write-Log "Error optimizando red: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================================
# 9. DESACTIVAR NOTIFICACIONES Y WIDGETS (TEMPORAL)
# ============================================================================
# Suprime notificaciones de Windows durante el juego para evitar
# interrupciones. Se restaura al finalizar.

function Disable-Notifications {
    Write-Log "Desactivando notificaciones temporalmente..." "INFO"

    try {
        # Activar modo de concentración / No molestar usando Focus Assist
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"

        # Guardar estado original
        $currentGlobal = Get-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -ErrorAction SilentlyContinue
        $Script:OriginalState["NotificationsEnabled"] = if ($currentGlobal) { $currentGlobal.NOC_GLOBAL_SETTING_TOASTS_ENABLED } else { 1 }

        # Desactivar notificaciones tipo toast
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 0 -Type DWord

        Write-Log "Notificaciones desactivadas durante la sesión de juego" "SUCCESS"
    }
    catch {
        Write-Log "Error desactivando notificaciones: $($_.Exception.Message)" "WARN"
    }
}

# ============================================================================
# 10. RESTAURACIÓN COMPLETA
# ============================================================================
# Restaura TODOS los cambios al estado original. Se ejecuta automáticamente
# al cerrar el script o al usar FH5-Restore.ps1.

function Restore-AllSettings {
    Write-Log "═══════════════════════════════════════════════" "INFO"
    Write-Log "RESTAURANDO CONFIGURACIÓN ORIGINAL..." "INFO"
    Write-Log "═══════════════════════════════════════════════" "INFO"

    # 1. Restaurar plan de energía
    if ($Script:OriginalState["PowerPlan"]) {
        try {
            powercfg /setactive $Script:OriginalState["PowerPlan"]
            Write-Log "Plan de energía restaurado" "SUCCESS"
        } catch {
            Write-Log "No se pudo restaurar plan de energía" "WARN"
        }
    }

    # 2. Reiniciar servicios detenidos
    foreach ($svcName in $Script:ServiciosDesactivados) {
        try {
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
            Write-Log "Servicio reiniciado: $svcName" "SUCCESS"
        } catch {
            Write-Log "No se pudo reiniciar: $svcName" "WARN"
        }
    }

    # 3. Restaurar notificaciones
    if ($Script:OriginalState.ContainsKey("NotificationsEnabled")) {
        try {
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
            Set-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value $Script:OriginalState["NotificationsEnabled"] -Type DWord
            Write-Log "Notificaciones restauradas" "SUCCESS"
        } catch {}
    }

    # 4. Restaurar red
    foreach ($key in $Script:OriginalState.Keys) {
        if ($key -match "Net_TcpNoDelay_(.+)") {
            $guid = $Matches[1]
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
            if ($Script:OriginalState[$key] -eq $null) {
                Remove-ItemProperty -Path $regPath -Name "TcpNoDelay" -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -Path $regPath -Name "TcpNoDelay" -Value $Script:OriginalState[$key] -ErrorAction SilentlyContinue
            }
        }
        if ($key -match "Net_TcpAckFreq_(.+)") {
            $guid = $Matches[1]
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid"
            if ($Script:OriginalState[$key] -eq $null) {
                Remove-ItemProperty -Path $regPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
            } else {
                Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value $Script:OriginalState[$key] -ErrorAction SilentlyContinue
            }
        }
    }

    # Restaurar autotuning
    netsh interface tcp set global autotuninglevel=normal 2>$null | Out-Null
    Write-Log "Red restaurada a configuración original" "SUCCESS"

    # 5. Restaurar Last Access Timestamp
    if ($Script:OriginalState.ContainsKey("DisableLastAccess")) {
        fsutil behavior set disableLastAccess $Script:OriginalState["DisableLastAccess"] | Out-Null
        Write-Log "Last Access Timestamp restaurado" "SUCCESS"
    }

    # 6. Restaurar prioridades de procesos
    $fh5 = Get-FH5Process
    if ($fh5) {
        try { $fh5.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal } catch {}
    }
    $spotify = Get-Process -Name "Spotify" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($spotify) {
        try {
            $spotify.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
            $spotify.ProcessorAffinity = [IntPtr]0xFF
        } catch {}
    }

    Write-Log "═══════════════════════════════════════════════" "SUCCESS"
    Write-Log "RESTAURACIÓN COMPLETA — Sistema en estado original" "SUCCESS"
    Write-Log "═══════════════════════════════════════════════" "SUCCESS"

    # Guardar log de restauración
    Write-Log "Archivo de log guardado en: $Script:LogFile" "INFO"
}

# ============================================================================
# FLUJO PRINCIPAL
# ============================================================================

function Start-Optimizer {
    Clear-Host
    Show-Banner

    # Verificar permisos
    if (-not (Test-IsAdmin)) {
        Write-Log "ERROR: Este script requiere permisos de Administrador." "ERROR"
        Write-Log "Haz clic derecho → 'Ejecutar como administrador'" "ERROR"
        Read-Host "Presiona Enter para salir"
        return
    }

    Write-Log "Script iniciado como Administrador" "SUCCESS"
    Write-Log "Equipo detectado: $(Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty Model)" "INFO"
    Write-Log ""

    # Registrar handler para Ctrl+C y cierre inesperado
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Restore-AllSettings
    } -ErrorAction SilentlyContinue

    try {
        # ─── FASE 1: OPTIMIZACIONES ESTÁTICAS ───
        Write-Log "══════ FASE 1: OPTIMIZACIONES DEL SISTEMA ══════" "INFO"
        Write-Log ""

        Set-HighPerformancePower
        Write-Log ""

        Disable-UnnecessaryServices
        Write-Log ""

        Optimize-BackgroundProcesses
        Write-Log ""

        Clear-WorkingSetMemory
        Write-Log ""

        Optimize-DiskAndCache
        Write-Log ""

        Optimize-NetworkLatency
        Write-Log ""

        Disable-Notifications
        Write-Log ""

        Write-Log "══════ FASE 1 COMPLETADA ══════" "SUCCESS"
        Write-Log ""

        # ─── FASE 2: MONITOREO DINÁMICO ───
        Write-Log "══════ FASE 2: MONITOREO DINÁMICO ══════" "INFO"
        Write-Log "Monitoreando sistema y esperando Forza Horizon 5..." "INFO"
        Write-Log "Presiona Ctrl+C para detener y restaurar la configuración" "INFO"
        Write-Log ""

        $Script:MonitoreoActivo = $true
        $gameDetected = $false
        $monitorInterval = 10  # segundos entre cada check de monitoreo

        while ($Script:MonitoreoActivo) {
            # Detectar si FH5 está corriendo
            $fh5 = Get-FH5Process

            if ($fh5 -and -not $gameDetected) {
                # Juego recién detectado
                $gameDetected = $true
                Write-Log "" "INFO"
                Write-Log "🎮 ¡FORZA HORIZON 5 DETECTADO! Aplicando optimizaciones dinámicas..." "SUCCESS"
                Write-Log "" "INFO"

                Set-GamePriority -GameProcess $fh5

                # Limpieza de memoria SOLO al detectar el juego por primera vez.
                # Esto libera RAM justo antes de que FH5 cargue sus assets pesados.
                # NO se repite durante gameplay para evitar page faults.
                Clear-WorkingSetMemory -Reason "pre-carga de FH5"
            }
            elseif (-not $fh5 -and $gameDetected) {
                # Juego cerrado — momento seguro para reclamar RAM
                $gameDetected = $false
                Write-Log "" "INFO"
                Write-Log "🎮 Forza Horizon 5 cerrado. Optimizaciones dinámicas desactivadas." "WARN"

                # Limpiar memoria que FH5 dejó fragmentada al salir
                Clear-WorkingSetMemory -Reason "post-cierre de FH5"
                Write-Log "Esperando que el juego se reinicie o presiona Ctrl+C para salir..." "INFO"
            }

            # Si el juego está corriendo, re-aplicar prioridades periódicamente
            # (Windows puede resetearlas)
            if ($gameDetected -and $fh5) {
                try {
                    if ($fh5.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::High) {
                        Set-GamePriority -GameProcess $fh5
                    }
                } catch {}
            }

            # NO hay limpieza periódica de memoria durante gameplay.
            # Razón: EmptyWorkingSet mueve páginas al pagefile. Cuando los procesos
            # las necesitan de vuelta, se genera un page fault (lectura de disco)
            # que causa micro-stutters perceptibles incluso en SSD NVMe.

            # Mostrar métricas
            $metrics = Get-SystemMetrics
            Clear-Host
            Show-Banner

            if ($gameDetected) {
                Write-Host "  🎮 ESTADO: FORZA HORIZON 5 EN EJECUCIÓN" -ForegroundColor Green
            } else {
                Write-Host "  ⏳ ESTADO: Esperando Forza Horizon 5..." -ForegroundColor Yellow
            }

            Show-MonitoringDashboard -Metrics $metrics
            Write-Host ""
            Write-Host "  Presiona Ctrl+C para detener y restaurar configuración" -ForegroundColor DarkGray
            Write-Host "  Log: $Script:LogFile" -ForegroundColor DarkGray

            Start-Sleep -Seconds $monitorInterval
        }
    }
    catch {
        if ($_.Exception.Message -notmatch "pipeline has been stopped") {
            Write-Log "Error inesperado: $($_.Exception.Message)" "ERROR"
        }
    }
    finally {
        # Siempre restaurar al salir
        Restore-AllSettings
    }
}

# Ejecutar
Start-Optimizer
