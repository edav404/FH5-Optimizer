@echo off
:: ============================================================================
:: FH5 Game Optimizer — Launcher
:: Ejecuta las optimizaciones + abre Spotify + lanza Forza Horizon 5
::
:: USO: Clic derecho → Ejecutar como administrador
:: ============================================================================

title FH5 Game Optimizer - Launcher
color 0B

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  FH5 Game Optimizer — Launcher Automatico               ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] Este launcher requiere permisos de Administrador.
    echo  Haz clic derecho → "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo  [1/4] Verificando archivos...

:: Verificar que el script principal existe
if not exist "%~dp0FH5-GameOptimizer.ps1" (
    echo  [ERROR] No se encontro FH5-GameOptimizer.ps1 en el mismo directorio.
    echo  Asegurate de que todos los archivos estan en la misma carpeta.
    pause
    exit /b 1
)

echo  [OK] Archivos verificados.
echo.

:: ─── Paso 1: Abrir Spotify ───
echo  [2/4] Abriendo Spotify...
:: Intentar abrir Spotify (instalacion normal y Microsoft Store)
if exist "%APPDATA%\Spotify\Spotify.exe" (
    start "" "%APPDATA%\Spotify\Spotify.exe" --minimized
    echo  [OK] Spotify abierto (minimizado^)
) else (
    :: Intentar via URI protocol (funciona con Microsoft Store)
    start "" spotify:
    echo  [OK] Spotify abierto via protocolo
)

:: Esperar un momento para que Spotify inicie
timeout /t 3 /nobreak >nul
echo.

:: ─── Paso 2: Ejecutar optimizador ───
echo  [3/4] Iniciando optimizador del sistema...
echo  (Se abrira una ventana de PowerShell con el monitor)
echo.

:: Iniciar el optimizador en una nueva ventana de PowerShell
start "FH5 Optimizer - Monitor" powershell.exe -ExecutionPolicy Bypass -NoProfile -NoExit -File "%~dp0FH5-GameOptimizer.ps1"

:: Esperar a que las optimizaciones iniciales se apliquen
echo  Esperando 10 segundos para que las optimizaciones se apliquen...
timeout /t 10 /nobreak >nul
echo.

:: ─── Paso 3: Lanzar Forza Horizon 5 (Microsoft Store) ───
echo  [4/4] Lanzando Forza Horizon 5 (Microsoft Store)...
echo.

:: Lanzar FH5 via Microsoft Store usando PackageFamilyName + ApplicationId
:: PackageFamilyName: Microsoft.624F8B84B80_8wekyb3d8bbwe
:: ApplicationId: Forzahorizon5 (obtenido del manifiesto del paquete)
start "" shell:AppsFolder\Microsoft.624F8B84B80_8wekyb3d8bbwe!Forzahorizon5 2>nul

if %errorLevel% neq 0 (
    echo  [ERROR] No se pudo lanzar Forza Horizon 5 desde Microsoft Store.
    echo  Verifica que el juego esta instalado desde la Microsoft Store.
    echo  Puedes abrirlo manualmente desde el menu Inicio.
)

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║  ✓ Todo listo!                                          ║
echo  ║                                                          ║
echo  ║  - Spotify: Ejecutandose en segundo plano               ║
echo  ║  - Optimizador: Monitoreando en ventana separada        ║
echo  ║  - Forza Horizon 5: Lanzandose (Microsoft Store)...     ║
echo  ║                                                          ║
echo  ║  IMPORTANTE: No cierres la ventana del optimizador      ║
echo  ║  hasta que termines de jugar. Al cerrarla, se            ║
echo  ║  restaurara la configuracion original automaticamente.   ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: Mantener esta ventana abierta por un momento y luego cerrarla
echo  Esta ventana se cerrara en 15 segundos...
timeout /t 15 /nobreak >nul
exit /b 0
