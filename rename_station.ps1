# ============================================================
# NC PERSONAL Radio HUD - station rename tool
# Usage (double-click rename_station.bat, or):
#   powershell -ExecutionPolicy Bypass -File rename_station.ps1 -StationName "88.8 My Radio"
# The name MUST start with a number + space (RadioExt sorting).
# ============================================================
param(
    [string]$GameDir = "",
    [string]$StationName = ""
)
$ErrorActionPreference = "Stop"
$DefaultName = '94.7 Piers "Piercer" Random Radio'

trap {
    Write-Host "" -ForegroundColor DarkGray
    Write-Host "ERROR: $_" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

function Test-GameDir([string]$d) {
    if (-not $d) { return $false }
    return (Test-Path (Join-Path $d "Cyberpunk2077.exe")) -or
           (Test-Path (Join-Path $d "bin\x64\Cyberpunk2077.exe"))
}
function Find-GameRoot {
    $cands = @()
    if (Test-GameDir (Get-Location).Path) { return (Get-Location).Path }
    # infer from helper config if it exists
    $lapCfg = Join-Path $env:LOCALAPPDATA "NCPersonalRadio\config.json"
    if (Test-Path $lapCfg) {
        try {
            $jc = Get-Content $lapCfg -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($jc.out) {
                $guess = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $jc.out)) # ...\mods\NCPersonal -> cet -> plugins...
                # climb to game root
                while ($guess -and -not (Test-Path (Join-Path $guess "bin\x64\Cyberpunk2077.exe"))) {
                    $up = Split-Path -Parent $guess; if ($up -eq $guess) { break }; $guess = $up
                }
                if (Test-GameDir $guess) { return $guess }
            }
        } catch { }
    }
    try {
        $sp = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($sp) {
            $cands += (Join-Path $sp "steamapps\common\Cyberpunk 2077")
            $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
            if (Test-Path $vdf) {
                $vt = Get-Content $vdf -Raw -ErrorAction SilentlyContinue
                [regex]::Matches($vt, '"path"\s+"([^"]+)"') | ForEach-Object {
                    $cands += (Join-Path $_.Groups[1].Value "steamapps\common\Cyberpunk 2077")
                }
            }
        }
    } catch { }
    Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
        $r = $_.Root.TrimEnd('\')
        $cands += @("$r\Steam\steamapps\common\Cyberpunk 2077", "$r\steam\steamapps\common\Cyberpunk 2077",
                    "$r\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077", "$r\Program Files\Epic Games\Cyberpunk 2077")
    }
    foreach ($c in $cands) { if ($c -and (Test-GameDir $c)) { return [System.IO.Path]::GetFullPath($c) } }
    return ""
}

# locate game
if (-not (Test-GameDir $GameDir)) { $GameDir = Find-GameRoot }
$try = 0
while (-not (Test-GameDir $GameDir)) {
    $try++
    if ($try -gt 3) { throw "Game directory not found. Pass -GameDir or run rename_station.bat from a console." }
    $GameDir = Read-Host "Game directory"
    if ($GameDir) { $GameDir = $GameDir.Trim().Trim('"') }
}
while (-not (Test-Path (Join-Path $GameDir "bin\x64\Cyberpunk2077.exe")) -and $GameDir) {
    $up = Split-Path -Parent $GameDir; if ($up -eq $GameDir) { break }; $GameDir = $up
}

# ask name if not given
if (-not $StationName) {
    $StationName = Read-Host "New station name (Enter for default: 94.7 Piers \"Piercer\" Random Radio)"
    if (-not $StationName) {
        $StationName = $DefaultName
        Write-Host "Using the default name." -ForegroundColor Cyan
    }
}
$StationName = $StationName.Trim().Trim('"')
if ($StationName -notmatch '^\d' -and $StationName -ne $DefaultName) {
    Write-Host "Station name must start with a number (e.g. 88.8 My Radio)." -ForegroundColor Red
    Read-Host "Press Enter to close"; exit 1
}
$StationName = $StationName -replace "['`r`n]", ''

$yaml = "$GameDir\r6\tweaks\CP77-External-Radio.yaml"
$lua  = "$GameDir\bin\x64\plugins\cyber_engine_tweaks\mods\NCPersonal\init.lua"
if (-not (Test-Path $yaml) -or -not (Test-Path $lua)) {
    throw "Could not find installed mod files. Install first with setup.bat."
}

$yc = Get-Content $yaml -Raw -Encoding UTF8
$yamlName = $StationName -replace '"', '\"'
$yc = $yc -replace '(?m)^(\s*)displayName:.*$', ('${1}displayName: "' + $yamlName + '"')
[System.IO.File]::WriteAllText($yaml, $yc, (New-Object System.Text.UTF8Encoding($false)))

$lc = Get-Content $lua -Raw -Encoding UTF8
$lc = $lc -replace "(local STATION_NAME = ')[^']*(')", ('${1}' + $StationName + '${2}')
[System.IO.File]::WriteAllText($lua, $lc, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Station renamed to: $StationName" -ForegroundColor Green
Write-Host "Restart the game to apply." -ForegroundColor Cyan
Read-Host "Press Enter to exit"
