# OMEN 16-c0032ns: qué cambiar y qué dejar quieto

**English summary**

These notes are for owners of the same HP OMEN 16-c0032ns (Spain SKU 531D2EA#ABE): Ryzen 7 5800H, Radeon RX 6600M, no MUX, and a 1080p 144 Hz panel wired to the integrated GPU.

The useful optional changes are PCIe ASPM (off on AC, maximum savings on battery), leaving OMEN Gaming Hub on Performance/ECO, adaptive brightness on battery only, and switching the internal panel to 60 Hz on battery and 144 Hz on AC.

Do not install the old HP graphics package or the full AMD.com installer, do not disable the 6600M, and do not set an 80% charge cap on this chassis.

The battery figures are one laptop's reading on 2026-11-11, not a health score for every unit.

Changing the power plan and the panel rate is reversible. This is not an official HP guide.

Notas de un solo portátil, no una guía oficial de HP. Cambiar la directiva de energía y el modo de la pantalla es reversible. No instale controladores desde sitios de terceros. Se comparte tal cual.

## Resultado

En el equipo medido, lo que merece la pena es la energía y los hercios del panel interno. No merece la pena un controlador nuevo, ni un tope de carga al 80 %.

El escritorio se queda en la gráfica integrada. Los juegos llegan a la RX 6600M por la preferencia de Windows «Alto rendimiento». Forzar un cálculo D3D11 sobre la 6600M llegó a cerca del 101 % de su motor 3D, así que un juego que se queda cerca del 20 % ha terminado por límite de fotogramas. No es un tope oculto.

## Ruta rápida

1. Confirme que el equipo es un OMEN 16-c0032ns, SKU 531D2EA#ABE, antes de copiar ningún paso.
2. En el plan Equilibrado, deje ASPM de PCI Express desactivado en corriente alterna y en máximo ahorro en batería. Reinicie una vez: ASPM de PCIe no se aplica del todo hasta el reinicio.
3. Deje OMEN Gaming Hub en Performance con el equipo enchufado. En este chasis ya pasa solo a ECO en batería.
4. Active el brillo adaptable solo en batería.
5. Si quiere 60 Hz en batería y 144 Hz enchufado, copie `scripts/` y registre la tarea `EquipoPanelRefresh`. Los monitores externos no se tocan.
6. No instale el paquete gráfico de HP de 2023 ni el instalador completo de AMD.com.

## Equipo

Medidas de un HP OMEN by HP Laptop 16-c0032ns, SKU 531D2EA#ABE (España), con Windows 11.

| Pieza | Dato |
| --- | --- |
| Placa | 8902 |
| BIOS | AMI F.26, fecha 2025-04-22 |
| CPU | AMD Ryzen 7 5800H, 8 núcleos / 16 hilos |
| Gráfica integrada | AMD Radeon Graphics, PCI DEV_1638, controlador 31.0.12002.7004 (2022-08-24) |
| Gráfica dedicada | AMD Radeon RX 6600M, DEV_73FF, controlador 32.0.21045.16010 (2026-10-16). Es el paquete legacy dentro de AMD Software Adrenalin 26.10.1 |
| Panel | Interno, cableado a la gráfica integrada, 1920x1080 a 144 Hz. No hay MUX |
| RAM | 2x8 GB Samsung DDR4-3200, doble canal, ya a la velocidad nominal |
| Copia de memoria | Un ensayo de 512 MB con RtlMoveMemory llegó a unos 27,6 GB/s |

Si más adelante quiere más memoria, el salto útil es 32 GB (2x16) por capacidad, no por MHz.

Resizable BAR (ReBAR) figuraba activado. Radeon Chill y FRTC (Frame Rate Target Control) figuraban desactivados. Déjelos así.

## Qué cambiar

Son pasos opcionales. El plan de energía de referencia es Equilibrado. No importe otro plan.

### ASPM de PCI Express

Enchufado, ASPM apagado evita que el ahorro del enlace PCIe añada latencia mientras hay corriente. En batería, el máximo ahorro deja dormir el enlace.

```text
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 2
powercfg /setactive SCHEME_CURRENT
```

El índice 0 es desactivar. El índice 2 es el máximo ahorro de energía. Reinicie después. Compruebe con `powercfg /q SCHEME_CURRENT SUB_PCIEXPRESS ASPM`: corriente alterna en 0, batería en 2.

### OMEN Gaming Hub

Deje Performance con el equipo enchufado. En este modelo el hub ya cambia a ECO al pasar a batería. No hace falta una segunda automatización.

### Brillo adaptable

Solo en batería. En la interfaz de Windows el ajuste se llama «Habilitar brillo adaptable»: desactivar en corriente alterna, activar en batería.

```text
powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGHT 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGHT 1
powercfg /setactive SCHEME_CURRENT
```

Este ajuste no pide el reinicio que sí pide ASPM. Si aplica los dos, un reinicio al final cubre ASPM.

### Inicio de Windows

Los programas de inicio son un ejemplo, no una lista para copiar. En el equipo medido se quitaron del arranque aplicaciones que no hacían falta en cada inicio: Docker Desktop, Teams, Nearby Share y OneDrive. Quite solo lo que usted no use. No desinstale OneDrive por esta guía. Si juega a Valorant, deje el inicio de Riot Vanguard: es la pieza de seguridad del juego.

### Juegos y la RX 6600M

En Configuración de Windows, Pantalla, Gráficos, asigne cada juego a Alto rendimiento. Esa preferencia (`GpuPreference` de alto rendimiento) es la que hace llegar el juego a la 6600M. En el equipo medido, League of Legends y Marvel Rivals ya estaban así. La carga del escritorio sigue en la gráfica integrada, porque el panel interno va cableado a ella y no hay MUX.

## Qué no cambiar

Esto se valoró y se descartó. El motivo está en cada apartado.

### Controladores gráficos

No instale el controlador gráfico de HP de 2023. Es un solo paquete para las dos GPU, así que bajaría la RX 6600M desde el controlador de octubre de 2026 (32.0.21045.16010) hasta ese paquete viejo. HP ya no publica ese paquete para el SKU 531D2EA.

Tampoco ejecute el instalador completo actual de AMD.com, ni el auto-detect a solas. Propietarios del mismo chasis 5800H + 6600M (OMEN 16-c0500na, comunidad de HP) vieron Code 43 y reinicios al abrir un juego con el instalador completo. La secuencia que funcionó en ese caso fue el paquete de HP de 2023 y, después, el auto-detect de AMD en modo Minimal. Ese paquete de HP ya no está disponible, así que no lance el auto-detect solo.

La gráfica integrada puede seguir en su controlador de 2022 (31.0.12002.7004). No hace falta igualar las dos fechas.

### Desactivar la 6600M en batería

No la desactive, no la desinstale y no programe esa acción al cambiar la fuente de alimentación. ULPS y `PP_GPUPowerDownEnabled` ya están activos en la dedicada (`EnableUlps`, `EnableUlps_NA` y `PP_GPUPowerDownEnabled`). Duerme cuando no tiene carga. Apagarla del todo provoca Code 43 porque no hay MUX: el panel no puede reasignarse a la otra GPU.

### Tope de carga al 80 %

No active un tope del 80 % en este 16-c con CPU AMD. No hay un control de un clic del estilo «cargar al 100 % antes de salir». OMEN Gaming Hub no trae ajuste de salud de batería. La clave `HKLM\SOFTWARE\HP\HP Power Manager` está vacía. El dispositivo de límite de carga `\\.\QCOMBATTMGR` no existe. Un interruptor en la BIOS exigiría reiniciar para entrar y otro para salir.

El tope tampoco devuelve capacidad ya perdida. Con el consumo medido recortaría la autonomía de unas 2 h 13 min a unas 1 h 46 min.

### Plan Ultimate de Chris Titus

No lo use. En este portátil fija el mínimo de la CPU en corriente alterna al 100 % y solo añade calor. El plan Equilibrado del equipo medido deja el mínimo de corriente alterna en el 80 % y el máximo en el 100 %; en batería, el mínimo está en el 5 % y el máximo en el 100 %. No baje el máximo de batería y no suba el mínimo de corriente alterna.

### Integridad de memoria, HAGS, MPO y Game DVR

No desactive la integridad de memoria, HAGS (programación de GPU acelerada por hardware) ni MPO (Multiplane Overlay). Game DVR ya estaba desactivado; no hace falta tocar más. Deje los efectos visuales como están.

### BIOS

No flashee una BIOS más nueva. Este equipo ya está en AMI F.26 (2025-04-22).

## Batería

Lectura de un solo equipo el 2026-11-11. No es una nota de salud válida para todos los OMEN 16.

Los anuncios del SKU 531D2EA dicen batería de 6 celdas y 83 Wh (Data System e Innova Informática). La página de HP de ese SKU no cargó. Otros OMEN 16 salieron con un pack de unos 70 Wh. Un propietario con el mismo procesador y la misma GPU, en el foro de HP, tenía un pack de 70 Wh (WK04XL); ese caso no es este SKU.

Windows informó una carga completa de 67,870 Wh y 23 ciclos, tanto en el informe de batería como en `root\wmi` `BatteryCycleCount`.

La capacidad de diseño de ese informe no es fiable. `Win32_Battery.DesignCapacity` venía vacío. En las 73 filas del historial, la columna de diseño copia la de carga completa y las dos se mueven juntas, entre unos 57,9 Wh y unos 69,3 Wh. El mínimo, 57,934 Wh, cubre del 2026-05-04 al 2026-05-18. La semana siguiente el informe marca 59,773 Wh, y el periodo que empieza el 2026-05-25 marca 68,530 Wh. Use la carga completa del 2026-11-11: 67,870 Wh. No use la columna de diseño.

Si el pack es realmente de 83 Wh, queda alrededor del 81,8 % (unos 15 Wh, un 18 %). Al consumo medido son unos 30 minutos menos que un pack nuevo de 83 Wh: unas 2 h 13 min ahora, frente a unas 2 h 42 min. Con 23 ciclos, el desgaste por ciclos es despreciable. La pérdida encaja con envejecimiento de calendario por estar al 100 %, no con una batería agotada por uso. El número de serie que devuelve el controlador es el texto comodín `SerialNumber`, así que esta lectura no demuestra que el pack sea el original.

Fuentes de los 83 Wh, consultadas el 2026-11-11:

- Data System: [anuncio del 16-c0032ns](https://www.tiendadatasystem.es/portatil-gaming-hp-omen-16-c0032ns-ryzen-7-5800h-16gb-512gb-ssd-radeon-rx-6600m-161-sin-sistema-operativo)
- Innova Informática: [anuncio del SKU 531D2EA](https://innovainformatica.com/portatiles/omen-by-hp-16-c0032ns-5800h-portatil-40-9-cm-16-1-full-hd-amd-ryzen-7-16-gb-ddr4-sdram-512-gb-ssd-amd-radeon-rx-6600m-wi-fi-6e-802-11ax-freed-531d2ea.html)

## Panel interno: 60 Hz en batería, 144 Hz enchufado

El script `scripts/set-panel-refresh.ps1` cambia solo el panel interno de 1920x1080. Enchufado pasa a 144 Hz. En batería pasa a 60 Hz, o a la tasa más baja anunciada a 1920x1080 si 60 Hz no existe. No llama a `ChangeDisplaySettingsEx` para un monitor externo. Si no hay exactamente un panel `INTERNAL` a 1920x1080, o si esa fuente está clonada a otra salida, no cambia nada. También se detiene si el nombre descriptivo coincide con una lista corta de pantallas externas o virtuales (Dell, Samsung, Parsec y dos fragmentos de modelo). Edite ese patrón si incluye por error su panel interno.

Los dos scripts tienen que quedarse en la misma carpeta. La ruta se resuelve al registrar la tarea; no hay una carpeta fija.

Consulta, sin cambiar el modo:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\set-panel-refresh.ps1 -Query
```

Registro de la tarea `EquipoPanelRefresh`, para el usuario actual, al iniciar sesión y cuando el registro System anota el evento 105 de Microsoft-Windows-Kernel-Power (cambio de fuente de alimentación). No corre como SYSTEM. Puede arrancar en batería y no se detiene al pasar a batería. Volver a ejecutar el registro sustituye la tarea del mismo nombre.

```text
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\register-panel-refresh-task.ps1
```

Para desactivarla o quitarla:

```text
Disable-ScheduledTask -TaskName 'EquipoPanelRefresh'
Unregister-ScheduledTask -TaskName 'EquipoPanelRefresh' -Confirm:$false
```

Después de desactivarla, ejecute el script una vez con el equipo enchufado si quiere volver a 144 Hz. El script sigue la fuente de alimentación actual; no mantiene 60 Hz fijos mientras hay corriente.

Cada ejecución escribe `refresh-run.log` junto al script. Ese registro es local. No lo publique: puede incluir el nombre descriptivo del monitor.

## Comprobación

- [ ] El SKU es 531D2EA#ABE (OMEN 16-c0032ns).
- [ ] El plan activo sigue siendo Equilibrado.
- [ ] Tras reiniciar, ASPM está en 0 enchufado y en 2 en batería.
- [ ] El brillo adaptable está desactivado enchufado y activado en batería.
- [ ] OMEN Gaming Hub sigue en Performance enchufado y pasa a ECO en batería.
- [ ] `-Query` muestra un solo panel interno a 1920x1080 y no cambia el modo.
- [ ] Un monitor externo, si lo hay, conserva resolución y hercios.
- [ ] La tarea `EquipoPanelRefresh`, si la registra, es del usuario actual y no de SYSTEM.

## Siguiente paso

Confirme el SKU en la pegatina o en Información del sistema. Si coincide, aplique el bloque de ASPM y reinicie. El script del panel es opcional. El apartado [Qué no cambiar](#qué-no-cambiar) es la lista de lo que en este chasis conviene no tocar.
