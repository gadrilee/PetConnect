<#
.SYNOPSIS
    Vigila el emulador de Android y trae su ventana a la pantalla cuando abre fuera.

.DESCRIPTION
    El emulador abre su ventana fuera del area visible (Y = -1000). La causa es
    window.scale = -1 (automatico) en emulator-user.ini: calcula la posicion con
    el tamano SIN escalar del dispositivo (1440x3200) y despues escala solo el
    tamano, no la posicion.

    Fijar window.scale a un valor explicito lo arregla, pero no sirve de nada:
    el emulador BORRA Y RECREA emulator-user.ini al cerrarse, reseteando la
    escala a -1. Ni el atributo de solo-lectura lo frena (lo limpia al recrear).

    Por eso hace falta un vigilante. Este script:
      1. Reubica la ventana en cuanto detecta un emulador nuevo abierto fuera.
      2. Al cerrarse el emulador, reescribe emulator-user.ini con una escala
         explicita, para que el proximo arranque ya abra bien por si solo.

    Solo actua UNA VEZ por sesion de emulador: si despues mueves la ventana a
    mano, no te la va a volver a correr.

.EXAMPLE
    .\scripts\emulador-watcher.ps1 -Install     # que arranque solo al iniciar sesion
    .\scripts\emulador-watcher.ps1 -Uninstall   # quitarlo
    .\scripts\emulador-watcher.ps1              # ejecutarlo a mano en esta consola
#>
param(
    [switch]$Install,
    [switch]$Uninstall,
    [int]$IntervaloSegundos = 2,
    [int]$MargenX = 40,
    [int]$MargenY = 20
)

$ErrorActionPreference = 'Stop'
$TAREA = 'AlquilaMatch - Emulador a la vista'

# ---------------------------------------------------------------- instalacion
if ($Install) {
    $yo = $MyInvocation.MyCommand.Path
    # Se lanza a traves de "conhost.exe --headless": cuando Windows Terminal es
    # la terminal predeterminada, -WindowStyle Hidden por si solo NO oculta la
    # ventana y queda una terminal vacia abierta en cada inicio de sesion
    # (microsoft/terminal #12464). Con conhost headless nunca aparece ventana.
    $accion = New-ScheduledTaskAction -Execute 'conhost.exe' `
        -Argument "--headless powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$yo`""
    $disparador = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $opciones = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -Hidden
    Register-ScheduledTask -TaskName $TAREA -Action $accion -Trigger $disparador `
        -Settings $opciones -Description 'Reubica la ventana del emulador de Android cuando abre fuera de pantalla.' -Force | Out-Null
    Start-ScheduledTask -TaskName $TAREA
    Write-Host "Instalado y corriendo. Arranca solo al iniciar sesion." -ForegroundColor Green
    Write-Host "Para quitarlo:  .\scripts\emulador-watcher.ps1 -Uninstall"
    return
}

if ($Uninstall) {
    if (Get-ScheduledTask -TaskName $TAREA -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TAREA -Confirm:$false
        Write-Host 'Desinstalado.' -ForegroundColor Green
    } else {
        Write-Host 'No estaba instalado.' -ForegroundColor Yellow
    }
    # Get-Process no expone CommandLine en Windows PowerShell 5.1 (el filtro no
    # encontraba nada y el vigilante seguia corriendo). Con CIM funciona en 5.1 y 7.
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*emulador-watcher*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    return
}

# ------------------------------------------------------------------- vigilante
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

function Reubicar($handle) {
    $r = New-Object RECT
    if (-not [Win]::GetWindowRect($handle, [ref]$r)) { return $false }

    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $fuera = ($r.Top -lt $wa.Top) -or ($r.Left -lt $wa.Left) -or
             ($r.Bottom -gt $wa.Bottom) -or ($r.Right -gt $wa.Right)
    if (-not $fuera) { return $false }

    # Holgura: la ventana del emulador ajusta su propio tamano por relacion de
    # aspecto y devuelve unos pixeles mas de los que se le piden.
    $HOLGURA = 24
    $ancho = [Math]::Min($r.Right - $r.Left, $wa.Width - ($MargenX * 2))
    $alto = [Math]::Min($r.Bottom - $r.Top, $wa.Height - $MargenY - $HOLGURA)
    $x = [Math]::Max($wa.Left, [Math]::Min($wa.Left + $MargenX, $wa.Right - $ancho))
    $y = [Math]::Max($wa.Top, [Math]::Min($wa.Top + $MargenY, $wa.Bottom - $alto))

    [void][Win]::ShowWindow($handle, 9)
    [void][Win]::MoveWindow($handle, $x, $y, $ancho, $alto, $true)

    # Segunda pasada: releer el tamano real que quedo y reacomodar la posicion
    # para que entre entera, sin volver a tocar el tamano.
    Start-Sleep -Milliseconds 250
    $r2 = New-Object RECT
    if ([Win]::GetWindowRect($handle, [ref]$r2)) {
        $anchoReal = $r2.Right - $r2.Left
        $altoReal = $r2.Bottom - $r2.Top
        $x2 = [Math]::Max($wa.Left, [Math]::Min($r2.Left, $wa.Right - $anchoReal))
        $y2 = [Math]::Max($wa.Top, [Math]::Min($r2.Top, $wa.Bottom - $altoReal))
        if ($x2 -ne $r2.Left -or $y2 -ne $r2.Top) {
            [void][Win]::MoveWindow($handle, $x2, $y2, $anchoReal, $altoReal, $true)
        }
    }

    [void][Win]::SetForegroundWindow($handle)
    return $true
}

function FijarEscalaParaLaProximaVez {
    <# Deja una escala explicita en cada AVD para que el proximo arranque ya
       abra bien sin depender del vigilante. El emulador lo pisa al cerrarse,
       por eso se reescribe justo despues de que se cierra. #>
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    foreach ($avd in Get-ChildItem "$env:USERPROFILE\.android\avd\*.avd" -Directory -ErrorAction SilentlyContinue) {
        $cfg = Join-Path $avd.FullName 'config.ini'
        $ini = Join-Path $avd.FullName 'emulator-user.ini'
        if (-not (Test-Path $cfg)) { continue }

        $alto = 2400
        $texto = Get-Content $cfg -ErrorAction SilentlyContinue
        $m = $texto | Select-String '^hw\.lcd\.height=(\d+)'
        if ($m) { $alto = [int]$m.Matches[0].Groups[1].Value }

        # Escala que hace entrar el alto del dispositivo en el area util.
        $escala = [Math]::Round((($wa.Height - $MargenY - 40) / $alto), 2)
        if ($escala -le 0) { $escala = 0.2 }
        if ($escala -gt 1) { $escala = 1 }

        $valores = [ordered]@{}
        if (Test-Path $ini) {
            foreach ($l in Get-Content $ini) {
                if ($l -match '^\s*([^=]+?)\s*=\s*(.*)$') { $valores[$Matches[1]] = $Matches[2] }
            }
        }
        $valores['window.x'] = "$MargenX"
        $valores['window.y'] = "$MargenY"
        $valores['window.scale'] = ('{0:N6}' -f $escala).Replace(',', '.')

        try {
            Set-ItemProperty -Path $ini -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            ($valores.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" }) |
                Set-Content -Path $ini -Encoding ascii
        } catch { }
    }
}

$atendidos = @{}
$habiaEmulador = $false

while ($true) {
    $procesos = @(Get-Process qemu-system-x86_64 -ErrorAction SilentlyContinue)

    foreach ($p in $procesos) {
        if ($p.MainWindowHandle -eq 0) { continue }
        if ($atendidos.ContainsKey($p.Id)) { continue }
        # Solo una vez por emulador: si despues la moves a mano, se respeta.
        [void](Reubicar $p.MainWindowHandle)
        $atendidos[$p.Id] = $true
    }

    if ($procesos.Count -gt 0) {
        $habiaEmulador = $true
    } elseif ($habiaEmulador) {
        # Se cerro el emulador: dejar la escala lista para el proximo arranque.
        $habiaEmulador = $false
        $atendidos.Clear()
        FijarEscalaParaLaProximaVez
    }

    Start-Sleep -Seconds $IntervaloSegundos
}
