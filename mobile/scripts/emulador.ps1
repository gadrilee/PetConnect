<#
.SYNOPSIS
    Arranca el emulador de Android y garantiza que la ventana quede dentro de la pantalla.

.DESCRIPTION
    El emulador guarda la posicion de su ventana en emulator-user.ini, pero puede
    ignorarla y abrirse fuera del area visible: aparece como "corriendo" en adb y
    en flutter devices, pero no se ve nada en pantalla.

    Este script arranca el AVD, espera a que termine de bootear y despues mueve la
    ventana a una posicion valida, recortada contra los limites del monitor real.

.PARAMETER Avd
    Nombre del AVD. Por defecto el primero que devuelva el emulador.

.EXAMPLE
    .\scripts\emulador.ps1
    .\scripts\emulador.ps1 -Avd Pixel_10_Pro_Fold
#>
param(
    [string]$Avd = '',
    [int]$MargenX = 40,
    [int]$MargenY = 0,
    # Arranque en frio, sin restaurar el snapshot. Necesario despues de
    # cambiar hw.ramSize, vm.heapSize o hw.cpu.ncore en config.ini: el
    # snapshot restaura la configuracion vieja y los cambios no se aplican.
    [switch]$ColdBoot
)

$ErrorActionPreference = 'Stop'

# --- Ubicar el SDK ---
$sdk = $env:ANDROID_HOME
if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }

$emulator = Join-Path $sdk 'emulator\emulator.exe'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
if (-not (Test-Path $emulator)) { throw "No se encontro emulator.exe en $sdk. Defini ANDROID_HOME." }
if (-not (Test-Path $adb)) { $adb = 'adb' }

if (-not $Avd) {
    $Avd = (& $emulator -list-avds | Select-Object -First 1)
    if (-not $Avd) { throw 'No hay ningun AVD creado.' }
}

# --- Arrancar si no esta corriendo ---
$yaCorre = Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue
if ($yaCorre) {
    Write-Host "El emulador ya esta corriendo." -ForegroundColor Yellow
} else {
    $argumentos = @('-avd', $Avd)
    if ($ColdBoot) {
        $argumentos += '-no-snapshot-load'
        Write-Host "Arrancando el AVD '$Avd' en frio (tarda mas)..." -ForegroundColor Cyan
    } else {
        Write-Host "Arrancando el AVD '$Avd'..." -ForegroundColor Cyan
    }
    Start-Process -FilePath $emulator -ArgumentList $argumentos -WindowStyle Normal
}

# --- Esperar el boot ---
Write-Host 'Esperando a que termine de arrancar...' -NoNewline
$listo = $false
foreach ($i in 1..120) {
    $r = (& $adb shell getprop sys.boot_completed 2>$null)
    if ("$r".Trim() -eq '1') { $listo = $true; break }
    Start-Sleep -Seconds 2
    Write-Host '.' -NoNewline
}
Write-Host ''
if (-not $listo) { throw 'El emulador no termino de arrancar a tiempo.' }
Write-Host 'Arrancado.' -ForegroundColor Green

# --- Reposicionar la ventana dentro del monitor ---
Add-Type @'
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public class Win {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int t, bool p);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
}
'@
Add-Type -AssemblyName System.Windows.Forms

$proc = $null
foreach ($i in 1..30) {
    $proc = Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($proc) { break }
    Start-Sleep -Seconds 1
}
if (-not $proc) {
    Write-Warning 'El emulador arranco pero no expone una ventana (puede estar en modo headless).'
    return
}

$h = $proc.MainWindowHandle
$r = New-Object RECT
[void][Win]::GetWindowRect($h, [ref]$r)
$ancho = $r.Right - $r.Left
$alto = $r.Bottom - $r.Top

$pantalla = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Si no entra, achicamos a lo que haya disponible.
if ($ancho -gt $pantalla.Width) { $ancho = $pantalla.Width - ($MargenX * 2) }
if ($alto -gt $pantalla.Height) { $alto = $pantalla.Height }

# Recortar la posicion contra los limites reales del monitor.
$x = [Math]::Max($pantalla.Left, [Math]::Min($pantalla.Left + $MargenX, $pantalla.Right - $ancho))
$y = [Math]::Max($pantalla.Top, [Math]::Min($pantalla.Top + $MargenY, $pantalla.Bottom - $alto))

$fuera = ($r.Top -lt $pantalla.Top) -or ($r.Left -lt $pantalla.Left) -or
         ($r.Right -gt $pantalla.Right) -or ($r.Bottom -gt $pantalla.Bottom)

[void][Win]::ShowWindow($h, 9)   # SW_RESTORE
[void][Win]::MoveWindow($h, $x, $y, $ancho, $alto, $true)
[void][Win]::SetForegroundWindow($h)

if ($fuera) {
    Write-Host "La ventana estaba fuera de pantalla (T=$($r.Top) L=$($r.Left)). Reubicada en ($x,$y) $ancho x $alto." -ForegroundColor Yellow
} else {
    Write-Host "Ventana en ($x,$y) $ancho x $alto." -ForegroundColor Green
}
Write-Host ''
Write-Host 'Listo. Ahora: flutter run' -ForegroundColor Cyan
