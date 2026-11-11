# RustDesk — instalación y configuración automática

Script para Windows que instala RustDesk (versión firmada) y lo deja apuntando al servidor propio de Disoftx, sin tocar la interfaz.

## Uso

1. Descargar `Setup-RustDesk.ps1`.
2. Abrir **PowerShell como administrador**.
3. Ejecutar:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\Setup-RustDesk.ps1
```

Si el equipo no tiene el instalador, el script lo descarga desde GitHub, **verifica la firma digital** y lo instala en silencio.

## Qué configura

Escribe la configuración del **servicio** (no la de la interfaz) en:

`C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml`

Valores:

- `rendezvous_server` → servidor propio
- `custom-rendezvous-server`
- `relay-server`
- `key` → clave pública del servidor
- `allow-websocket = N` ← **crítico**: con `Y`, el cliente intenta WebSocket al puerto 80 y nunca registra.

Después reinicia el servicio `rustdesk`.

## Verificación

- Abrir RustDesk: el estado debe decir **Listo**.
- En el servidor, el peer debe aparecer registrado.

## Notas

- Ejecutar como administrador: sin elevación no puede escribir en `ServiceProfiles` ni reiniciar el servicio.
- Si RustDesk ya está instalado, el script solo reescribe la configuración.
- La clave es la **pública** del servidor; no es un secreto, pero no conviene publicarla fuera del equipo.
