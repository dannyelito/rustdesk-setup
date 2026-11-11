# Setup-RustDesk.ps1
# Instala/configura RustDesk apuntando a un servidor propio.
# Uso: powershell -ExecutionPolicy Bypass -File Setup-RustDesk.ps1
param(
  [string]$Server = "rd.disoftx.solutions",
  [string]$Key = "seRCpZ2VWWY3vEjv1dJv0csgr42dbbO4VJ49lIoL3Fo=",
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$exe = "C:\Program Files\RustDesk\rustdesk.exe"
$setup = "C:\Temp\rd-setup.exe"
$url = "https://github.com/rustdesk/rustdesk/releases/download/1.5.1/rustdesk-1.5.1-x86_64.exe"

Write-Host "== RustDesk setup ==" -ForegroundColor Cyan

if ((-not (Test-Path $exe)) -or $Force) {
    if (-not (Test-Path $setup)) {
        Write-Host "Descargando instalador firmado..."
        New-Item -ItemType Directory -Force -Path C:\Temp | Out-Null
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $setup
    }
    $sig = (Get-AuthenticodeSignature $setup).Status
    Write-Host "Firma del instalador: $sig"
    if ($sig -ne "Valid") { throw "El instalador no tiene firma valida. Abortado." }
    Write-Host "Instalando en silencio..."
    Start-Process -FilePath $setup -ArgumentList "--silent-install" -Wait
    Start-Sleep -Seconds 12
} else {
    Write-Host "RustDesk ya instalado."
}

$cfgDir = "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config"
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
$toml = Join-Path $cfgDir "RustDesk2.toml"

function Set-TomlValue([string]$text, [string]$keyName, [string]$value, [string]$section) {
    $line = "$keyName = '$value'"
    if ($section -eq "top") {
        if ($text -match "(?m)^$([regex]::Escape($keyName))\s*=") {
            return [regex]::Replace($text, "(?m)^$([regex]::Escape($keyName))\s*=.*$", $line)
        }
        return "$line`r`n" + $text
    }
    # dentro de [options]
    if ($text -match "(?m)^$([regex]::Escape($keyName))\s*=") {
        return [regex]::Replace($text, "(?m)^$([regex]::Escape($keyName))\s*=.*$", $line)
    }
    if ($text -match "(?m)^\[options\]\s*$") {
        return [regex]::Replace($text, "(?m)^\[options\]\s*$", "[options]`r`n$line", 1)
    }
    return $text.TrimEnd() + "`r`n`r`n[options]`r`n$line`r`n"
}

$text = if (Test-Path $toml) { Get-Content -Raw -Path $toml } else { "" }
$text = Set-TomlValue $text "rendezvous_server" "$Server`:21116" "top"
$text = Set-TomlValue $text "custom-rendezvous-server" $Server "options"
$text = Set-TomlValue $text "relay-server" $Server "options"
$text = Set-TomlValue $text "key" $Key "options"
$text = Set-TomlValue $text "allow-websocket" "N" "options"
Set-Content -Path $toml -Value $text -Encoding UTF8
Write-Host "Configuracion escrita en $toml"

Write-Host "Reiniciando servicio..."
sc.exe stop rustdesk | Out-Null
Start-Sleep -Seconds 3
sc.exe start rustdesk | Out-Null
Start-Sleep -Seconds 5

$st = (sc.exe query rustdesk | Select-String "STATE").ToString().Trim()
Write-Host "Servicio: $st"

Write-Host "Listo. Revisa en RustDesk que el estado diga LISTO." -ForegroundColor Green
