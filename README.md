<div align="center">

# 🏎️ FH5 Game Optimizer

**Optimizador de sistema Windows para Forza Horizon 5 (Microsoft Store) en hardware de gama media**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

<br>

*Script automatizado que optimiza procesos, servicios, memoria y energía de Windows para maximizar el rendimiento de FH5 (versión Microsoft Store) mientras Spotify suena en segundo plano. Todo temporal. Todo reversible.*

</div>

---

## 📋 Tabla de Contenidos

- [¿Qué Hace?](#-qué-hace)
- [Características](#-características)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Instalación](#-instalación)
- [Uso](#-uso)
- [Cómo Revertir los Cambios](#-cómo-revertir-los-cambios)
- [Qué Optimiza Exactamente](#-qué-optimiza-exactamente)
- [Advertencias y Riesgos](#%EF%B8%8F-advertencias-y-riesgos)
- [Ejemplo de Uso](#-ejemplo-de-uso)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Mejoras Futuras](#-mejoras-futuras)
- [Licencia](#-licencia)

---

## 🎯 ¿Qué Hace?

FH5 Game Optimizer es un script de PowerShell que **reasigna temporalmente los recursos del sistema operativo** a favor de Forza Horizon 5. No modifica el juego, los drivers ni archivos del sistema. Trabaja exclusivamente sobre la gestión de procesos, servicios y configuración de Windows.

### Problema que resuelve

En laptops de gama media (como la ThinkPad P50), Windows ejecuta docenas de servicios y procesos en segundo plano que compiten con el juego por CPU, RAM y disco. Esto causa:

- **Caídas aleatorias de FPS** (micro-stutters)
- **Frametimes inestables** por picos de carga del sistema
- **RAM insuficiente** compartida entre el OS, el juego y Spotify
- **Input lag** por buffering de red y prioridades incorrectas

Este script elimina esa competencia de recursos de forma temporal y segura.

---

## ✨ Características

| Característica | Descripción |
|---|---|
| 🔋 **Plan de energía** | Cambia a Alto Rendimiento para desbloquear Turbo Boost completo |
| 🛑 **Gestión de servicios** | Detiene 10 servicios innecesarios durante la sesión de juego |
| 📊 **Prioridad de procesos** | FH5 en prioridad Alta, Spotify confinado a 2 hilos con prioridad baja |
| 🧹 **Limpieza de RAM** | Libera working sets en momentos seguros (no durante gameplay) |
| 💾 **Optimización de disco** | Limpia temporales y reduce escrituras innecesarias |
| 🌐 **Latencia de red** | Desactiva Nagle algorithm para reducir latencia online |
| 🔕 **Notificaciones** | Suprime notificaciones de Windows durante el juego |
| 📈 **Monitor en tiempo real** | Dashboard con CPU, GPU, RAM, temperaturas y throttling |
| 🌡️ **Detección de throttling** | Alerta cuando el CPU throttlea por temperatura |
| ♻️ **100% reversible** | Restauración automática al cerrar + script de emergencia |

---

## 💻 Requisitos del Sistema

### Mínimos

- **SO:** Windows 10 o Windows 11
- **PowerShell:** 5.1 o superior (incluido en Windows 10/11)
- **Permisos:** Ejecución como Administrador
- **GPU:** NVIDIA con drivers instalados (para monitoreo GPU via `nvidia-smi`)

### Diseñado y testeado para

| Componente | Especificación |
|---|---|
| Laptop | Lenovo ThinkPad P50 |
| CPU | Intel Core i7-6700HQ (4C/8T) |
| RAM | 16 GB DDR4 |
| GPU | NVIDIA Quadro M1000M (~GTX 950M) |
| Almacenamiento | SSD NVMe 500 GB |

> **Nota:** Este proyecto está diseñado exclusivamente para la versión de **Microsoft Store** de Forza Horizon 5. El launcher utiliza el Package Family Name del paquete MSIX para iniciar el juego. Si tienes la versión de Steam, necesitarás modificar el archivo `FH5-Launcher.bat`. Las configuraciones de afinidad de CPU están calibradas para un procesador de 4 núcleos / 8 hilos.

---

## 📥 Instalación

### Opción 1: Clonar con Git

```bash
git clone https://github.com/TU_USUARIO/FH5-Optimizer.git
```

### Opción 2: Descargar manualmente

1. Haz clic en **Code** → **Download ZIP** en la página del repositorio
2. Extrae el ZIP en una carpeta de tu elección (ej: `C:\Users\TuUsuario\Documents\FH5-Optimizer`)

### Verificar política de ejecución de PowerShell

Windows puede bloquear scripts de PowerShell por defecto. Para verificar y ajustar:

```powershell
# Ver política actual
Get-ExecutionPolicy

# Si dice "Restricted", cambiar temporalmente (requiere Admin)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

> Esto permite ejecutar scripts locales. Scripts descargados de internet requerirán el flag `-ExecutionPolicy Bypass` (que el launcher ya incluye).

---

## 🚀 Uso

### Método 1: Launcher Automático (Recomendado)

El launcher abre Spotify, ejecuta las optimizaciones y lanza Forza Horizon 5 automáticamente.

1. Navega a la carpeta del proyecto en el Explorador de archivos
2. **Clic derecho** en `FH5-Launcher.bat` → **"Ejecutar como administrador"**
3. Deja la ventana de PowerShell del monitor abierta mientras juegas
4. Al terminar, cierra la ventana del monitor → todo se restaura automáticamente

### Método 2: Solo el optimizador (sin launcher)

```powershell
# Abrir PowerShell como Administrador, luego:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
cd "C:\ruta\a\FH5-Optimizer"
.\FH5-GameOptimizer.ps1
```

Luego abre Spotify y FH5 manualmente desde el menú Inicio. El script los detectará automáticamente.

### Método 3: Solo monitoreo (sin optimizaciones)

Si solo quieres ver el dashboard de rendimiento sin aplicar optimizaciones, actualmente no hay un modo separado. Considera usar herramientas como HWiNFO o MSI Afterburner para monitoreo standalone.

---

## ♻️ Cómo Revertir los Cambios

### Automáticamente

Los cambios **se revierten solos** al cerrar el script (Ctrl+C o cerrando la ventana de PowerShell).

### Manualmente (emergencia)

Si el script se cerró abruptamente (crash, bluescreen, corte de energía):

```powershell
# Ejecutar como Administrador
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\FH5-Restore.ps1
```

### Qué revierte `FH5-Restore.ps1`

- ✅ Plan de energía → Equilibrado
- ✅ Servicios detenidos → Reiniciados
- ✅ Configuración de red (Nagle/Autotuning) → Valores por defecto
- ✅ Notificaciones → Reactivadas
- ✅ Last Access Timestamp → Reactivado
- ✅ Prioridades de procesos → Normal

### Manual absoluto (sin scripts)

Si ni siquiera puedes ejecutar PowerShell:

1. **Reinicia Windows** — los servicios con arranque automático se reiniciarán solos
2. Ve a **Panel de Control → Opciones de energía** → Selecciona "Equilibrado"
3. Los cambios de registro de red (`TcpNoDelay`) se pueden borrar desde `regedit`

---

## 🔍 Qué Optimiza Exactamente

<details>
<summary><b>Servicios que se detienen temporalmente (clic para expandir)</b></summary>

| Servicio | Nombre técnico | Función |
|---|---|---|
| Superfetch | `SysMain` | Precarga aplicaciones en RAM. Innecesario durante gaming |
| Telemetría | `DiagTrack` | Envía datos de uso a Microsoft |
| Windows Search | `WSearch` | Indexa archivos en segundo plano. Causa picos de I/O |
| Mapas offline | `MapsBroker` | Descarga mapas de la app Mapas |
| Entrada de tablet | `TabletInputService` | Pantalla táctil y stylus |
| WMP Network | `WMPNetworkSvc` | Compartir media de Windows Media Player |
| WAP Push | `dmwappushservice` | Mensajes push de telemetría |
| Geolocalización | `lfsvc` | Servicios de ubicación |
| Demo en tiendas | `RetailDemo` | Modo demostración (nunca necesario) |
| Windows Insider | `wisvc` | Programa Insider de Microsoft |

</details>

<details>
<summary><b>Procesos cuya prioridad se reduce (clic para expandir)</b></summary>

- SearchUI, SearchApp, SearchHost (búsqueda de Windows)
- OneDrive (sincronización en la nube)
- Teams, Widgets
- PhoneExperienceHost, YourPhone (Tu Teléfono)
- GameBarPresenceWriter, BcastDVRUserService (Xbox Game Bar)
- Calculator, SkypeApp, Microsoft.Photos
- HxTsr, HxOutlook (Correo)
- GrooveMusic, MicrosoftEdgeUpdate

</details>

---

## ⚠️ Advertencias y Riesgos

### ✅ Es seguro

- No modifica archivos del sistema operativo
- No instala ni descarga software
- No toca drivers ni el kernel
- No usa prioridad `Realtime` (que sí sería peligrosa)
- No modifica voltajes ni frecuencias del hardware

### ⚠️ Ten en cuenta

- **Requiere Administrador**: El script necesita privilegios elevados para detener servicios y modificar prioridades
- **Tras un crash**: Si Windows se congela durante el juego, ejecuta `FH5-Restore.ps1` al reiniciar para restaurar los cambios de registro TCP y notificaciones
- **Pantalla táctil**: Si usas la pantalla táctil del ThinkPad P50, la perderás temporalmente (servicio `TabletInputService` detenido)
- **Monitoreo de temperatura**: La lectura de temperatura del CPU via ACPI puede no ser precisa en todos los equipos. Para diagnóstico real, usa HWiNFO

### ❌ No hace

- No desactiva Windows Defender ni el firewall
- No elimina servicios permanentemente
- No modifica archivos del juego
- No realiza overclocking ni undervolting

---

## 💡 Ejemplo de Uso

```
$ .\FH5-Launcher.bat (ejecutar como Admin)

 ╔══════════════════════════════════════════════════════════╗
 ║  FH5 Game Optimizer — Launcher Automatico               ║
 ╚══════════════════════════════════════════════════════════╝

 [1/4] Verificando archivos...
 [OK] Archivos verificados.

 [2/4] Abriendo Spotify...
 [OK] Spotify abierto (minimizado)

 [3/4] Iniciando optimizador del sistema...
 Esperando 10 segundos para que las optimizaciones se apliquen...

 [4/4] Lanzando Forza Horizon 5...

 ✓ Todo listo!
```

El monitor de rendimiento mostrará un dashboard como este:

```
  ┌─────────────────────────────────────────────────────────┐
  │          MONITOR DE RENDIMIENTO — FH5 OPTIMIZER        │
  ├─────────────────────────────────────────────────────────┤
  │  CPU: [████████████░░░░░░░░] 62%  |  Temp: 78°C
  │  GPU: [██████████████░░░░░░] 71%  |  Temp: 72°C
  │  RAM: [████████████████░░░░] 11.2/15.9 GB (70.4%)
  │  CPU Clock: 3100/3500 MHz (88.6%)
  │  Disk: 12.3%
  │  Throttling: ✓ Normal
  └─────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
FH5-Optimizer/
├── FH5-GameOptimizer.ps1    # Script principal de optimización
├── FH5-Launcher.bat         # Launcher automático (Spotify + Optimizer + FH5)
├── FH5-Restore.ps1          # Script de restauración de emergencia
├── README.md                # Este archivo
├── LICENSE                  # Licencia MIT
├── .gitignore               # Archivos ignorados por Git
├── docs/                    # Documentación adicional
│   ├── NVIDIA-SETTINGS.md   # Configuración recomendada del Panel NVIDIA
│   ├── FH5-GRAPHICS.md      # Ajustes gráficos recomendados para FH5
│   └── SPOTIFY-CONFIG.md    # Optimización de Spotify
└── logs/                    # Logs generados por el script (ignorados por Git)
    └── .gitkeep             # Placeholder para mantener la carpeta en Git
```

---

## 🔮 Mejoras Futuras

- [ ] **Modo solo-monitoreo** — Ejecutar el dashboard sin aplicar optimizaciones
- [ ] **Detección automática de núcleos** — Adaptar máscaras de afinidad según el CPU detectado
- [ ] **Perfil por juego** — Soporte para otros juegos además de FH5
- [ ] **GUI con Windows Forms** — Interfaz gráfica en lugar de consola
- [ ] **Undervolting guiado** — Integración con ThrottleStop para reducir temperaturas
- [ ] **Detección de `nvidia-smi`** — Verificar una sola vez al inicio en lugar de cada ciclo
- [ ] **Dashboard sin parpadeo** — Usar `SetCursorPosition` en lugar de `Clear-Host`
- [ ] **Soporte AMD** — Detección y monitoreo de GPUs Radeon

---

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT**.

```
MIT License — Puedes usar, copiar, modificar y distribuir este software
libremente, incluso para uso comercial, sin restricciones. Solo se requiere
incluir el aviso de copyright original.
```

Se eligió MIT porque:
- Es la licencia más permisiva y ampliamente reconocida
- Permite que cualquier persona adapte el script a su hardware
- No impone restricciones para uso personal ni comercial
- Es la licencia estándar para scripts/herramientas de utilidad

Consulta el archivo [LICENSE](./LICENSE) para el texto completo.

---

<div align="center">

**¿Preguntas o sugerencias?** Abre un [Issue](../../issues) en GitHub.

Hecho con ☕ y frustración por los micro-stutters.

</div>
