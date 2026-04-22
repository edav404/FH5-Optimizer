# Configuración Panel de Control NVIDIA — Quadro M1000M

Configuración recomendada para gaming con la NVIDIA Quadro M1000M (~GTX 950M).

> **Cómo abrir:** Clic derecho en el escritorio → "Panel de control NVIDIA"

## Configuración 3D Global

| Ajuste | Valor Recomendado | Razón |
|--------|-------------------|-------|
| Modo de administración de energía | Preferir máximo rendimiento | Evita que la GPU baje frecuencias |
| Filtrado de texturas - Calidad | Alto rendimiento | Reduce carga de GPU |
| Filtrado de texturas - Optimización trilineal | Activado | Mejora rendimiento sin impacto visual notable |
| Filtrado de texturas - Optimización anisotrópica | Activado | Reduce carga sin pérdida visible |
| Filtrado anisotrópico | Controlado por aplicación | FH5 lo maneja internamente |
| Antialiasing - Modo | Controlado por aplicación | Doble AA reduce FPS |
| Anti-aliasing FXAA | Desactivado | FH5 tiene su propio AA |
| Sincronización vertical | Desactivado | FH5 lo maneja internamente |
| Búfer triple | Desactivado | Solo útil con V-Sync del driver |
| Fotogramas pre-renderizados | 1 | Reduce input lag |
| Procesador de gráficos preferido | Procesador NVIDIA de alto rendimiento | Fuerza GPU dedicada en lugar de Intel HD 530 |

## Configuración del Programa (solo FH5)

> **Nota (Microsoft Store):** Las apps de Microsoft Store/Xbox se manejan como paquetes UWP.
> En el Panel de Control NVIDIA, busca **"Forza Horizon 5"** en la lista de programas.
> Si no aparece, haz clic en **"Agregar"** → **"Examinar"** y navega a:
> `C:\Program Files\WindowsApps\Microsoft.624F8B84B80_*\ForzaHorizon5.exe`
> (Puede que necesites habilitar "Ver archivos ocultos" y dar permisos a la carpeta WindowsApps).

1. Ir a **"Configuración 3D"** → **"Configuración del programa"**
2. Seleccionar o agregar **Forza Horizon 5**
3. Aplicar los mismos ajustes de arriba, más:

| Ajuste | Valor |
|--------|-------|
| Modo de bajo retardo | Activado |
| Escalado de imagen | Desactivado |

## Ajustar Configuración de Imagen con Vista Previa

- Seleccionar **"Configuración decidida por la aplicación 3D"**
