# Optimización de Spotify para Gaming

Configuración de Spotify para minimizar consumo de CPU, RAM y red mientras juegas.

> Con el script activo, Spotify se ejecuta en los **2 últimos hilos de tu CPU** con prioridad baja. Estos ajustes reducen aún más su consumo.

## Ajustes dentro de Spotify

Abrir Spotify → ⚙️ **Configuración**:

| Ajuste | Valor | Razón |
|--------|-------|-------|
| Calidad de streaming | Normal (96 kbps) o Alta (160 kbps) | "Muy alta" (320 kbps) consume más CPU y red |
| Crossfade | Desactivado | Reduce procesamiento de audio |
| Ecualizador | Desactivado | Cada filtro EQ consume CPU |
| Normalización de volumen | Desactivado | Ligero consumo de CPU |
| Reproducción sin cortes (gapless) | Activado | Bajo consumo, mejor experiencia |
| Aceleración por hardware | Activado | Descarga procesamiento a la GPU |
| Canvas (videos animados) | **Desactivado** | Consume GPU y RAM |
| Mostrar amigos | Desactivado | Reduce consultas de red |

## Inicio automático

- Configuración → "Abrir Spotify automáticamente al iniciar sesión" → **No**
- Dejar que el launcher (`FH5-Launcher.bat`) lo abra cuando sea necesario

## Descargas Offline (Premium)

Si tienes Spotify Premium, descarga las playlists que planeas escuchar antes de jugar. Esto elimina completamente el uso de red durante gameplay.

## ¿Por qué 96 kbps es suficiente?

La diferencia entre 96 kbps y 320 kbps es imperceptible mientras juegas — el sonido del juego (motor, ambiente, música in-game) enmascara las diferencias de calidad del streaming de Spotify.
