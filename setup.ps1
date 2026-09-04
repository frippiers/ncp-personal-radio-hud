# ============================================================
# NC PERSONAL Radio HUD - installer
# Usage: right-click -> Run with PowerShell
#        or:  powershell -ExecutionPolicy Bypass -File setup.ps1
# Optional: powershell -ExecutionPolicy Bypass -File setup.ps1 -GameDir "D:\Steam\steamapps\common\Cyberpunk 2077"
# ============================================================
param(
    [string]$GameDir = "",
    [string]$StationName = "",
    [switch]$NoAutoStart
)
$ErrorActionPreference = "Stop"
function Test-GameDir([string]$d) {
    if (-not $d) { return $false }
    return (Test-Path (Join-Path $d "Cyberpunk2077.exe")) -or
           (Test-Path (Join-Path $d "bin\x64\Cyberpunk2077.exe"))
}
trap {
    Write-Host "" -ForegroundColor DarkGray
    Write-Host ("ERROR at line {0}: {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message) -ForegroundColor Red
    Write-Host "Installation aborted." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$game = [System.IO.Path]::GetFullPath("$here\game")
$companion = "$here\companion"
$fontsDir = "$here\fonts"

Write-Host "== NC PERSONAL Radio HUD installer ==" -ForegroundColor Cyan

# ---- locate game (auto-detect, manual fallback) ----
function Find-GameRoot {
    $cands = @()
    # current directory
    if (Test-GameDir (Get-Location).Path) { return (Get-Location).Path }
    # Steam libraries (registry + libraryfolders.vdf)
    try {
        $sp = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
        if ($sp) {
            $cands += (Join-Path $sp "steamapps\common\Cyberpunk 2077")
            $vdf = Join-Path $sp "steamapps\libraryfolders.vdf"
            if (Test-Path $vdf) {
                $vtext = Get-Content $vdf -Raw -ErrorAction SilentlyContinue
                [regex]::Matches($vtext, '"path"\s+"([^"]+)"') | ForEach-Object {
                    $cands += (Join-Path $_.Groups[1].Value "steamapps\common\Cyberpunk 2077")
                }
            }
        }
    } catch { }
    # every drive, common locations
    Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
        $r = $_.Root.TrimEnd('\')
        $cands += @(
            "$r\Steam\steamapps\common\Cyberpunk 2077",
            "$r\steam\steamapps\common\Cyberpunk 2077",
            "$r\SteamLibrary\steamapps\common\Cyberpunk 2077",
            "$r\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077",
            "$r\Program Files\Steam\steamapps\common\Cyberpunk 2077",
            "$r\Program Files\Epic Games\Cyberpunk 2077",
            "$r\GOG Games\Cyberpunk 2077",
            "$r\Program Files (x86)\GOG Galaxy\Games\Cyberpunk 2077"
        )
    }
    foreach ($c in $cands) {
        if ($c -and (Test-GameDir $c)) { return [System.IO.Path]::GetFullPath($c) }
    }
    return ""
}

if (-not (Test-GameDir $GameDir)) {
    $GameDir = Find-GameRoot
    if ($GameDir) { Write-Host "Game auto-detected: $GameDir" -ForegroundColor Cyan }
}
$try = 0
while (-not (Test-GameDir $GameDir)) {
    $try++
    if ($try -gt 3) { throw "Game directory was not provided correctly. Please run setup.bat and type the path, or pass -GameDir." }
    $GameDir = Read-Host "Game directory (where Cyberpunk2077.exe is)"
    if ($GameDir) {
        $GameDir = $GameDir.Trim().Trim('"')
        if ($GameDir) {
            try { $GameDir = [System.IO.Path]::GetFullPath($GameDir) } catch { $GameDir = "" }
        }
    }
}
# normalize: if caller passed ...\bin\x64 instead of the game root,
# walk up until we find a folder that contains bin\x64\Cyberpunk2077.exe
while (-not (Test-Path (Join-Path $GameDir "bin\x64\Cyberpunk2077.exe")) -and $GameDir) {
    $parent = Split-Path -Parent $GameDir
    if ($parent -eq $GameDir) { break }
    $GameDir = $parent
}
$cet = "$GameDir\bin\x64\plugins\cyber_engine_tweaks"
$modDir = "$cet\mods\NCPersonal"

# ---- dependency warnings (non-fatal) ----
$missing = @()
if (-not (Test-Path "$GameDir\red4ext\plugins\cp77_external_radio.dll"))  { $missing += "External Radio (Nexus 3741) - required" }
if (-not (Test-Path "$GameDir\bin\x64\plugins\cyber_engine_tweaks.asi")) { $missing += "Cyber Engine Tweaks - required" }
if (-not (Test-Path "$GameDir\red4ext\plugins\TweakXL\TweakXL.dll"))       { $missing += "TweakXL - required" }
if (-not (Test-Path "$GameDir\r6\scripts"))                                { $missing += "redscript - required" }
if ($missing.Count -gt 0) {
    Write-Host "MISSING REQUIRED MODS (install them first):" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "Continuing with files we can install..." -ForegroundColor DarkYellow
}

# ---- 1) radio station tweak (overwrites External Radio's yaml to rename station) ----
$tw = "$GameDir\r6\tweaks"
if (-not (Test-Path $tw)) { New-Item -ItemType Directory -Force -Path $tw | Out-Null }
$srcYaml = "$game\r6\tweaks\CP77-External-Radio.yaml"
$dstYaml = "$tw\CP77-External-Radio.yaml"
if ((Test-Path $dstYaml) -and (-not (Test-Path "$dstYaml.bak"))) { Copy-Item $dstYaml "$dstYaml.bak" }
Copy-Item $srcYaml $dstYaml -Force
Write-Host "[1/5] station tweak installed (backup: $dstYaml.bak)" -ForegroundColor Green

# ---- 1b) move stale NCPersonal backup dirs out of mods (prevents double-load) ----
$mroot = "$cet\mods"
if (Test-Path $mroot) {
    Get-ChildItem $mroot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'NCPersonal*.__nc*' -or $_.Name -like '.*' -and $_.Name -like '*NCPersonal*' } |
        ForEach-Object {
            $bdir = Join-Path $env:LOCALAPPDATA "NCPersonalRadio\mods-backup"
            New-Item -ItemType Directory -Force -Path $bdir | Out-Null
            Move-Item $_.FullName (Join-Path $bdir $_.Name) -Force -ErrorAction SilentlyContinue
        }
}

# ---- 2) NCPersonal CET mod ----
if (-not (Test-Path $modDir)) { New-Item -ItemType Directory -Force -Path $modDir | Out-Null }
Copy-Item "$game\bin\x64\plugins\cyber_engine_tweaks\mods\NCPersonal\init.lua" "$modDir\init.lua" -Force
Write-Host "[2/5] NCPersonal HUD mod installed" -ForegroundColor Green

# ---- 2b) External Radio reds override (remove auto-play on entering vehicle) ----
$rsDir = "$GameDir\r6\scripts"
if (-not (Test-Path $rsDir)) { New-Item -ItemType Directory -Force -Path $rsDir | Out-Null }
$srcReds = "$game\r6\scripts\CP77-External-Radio.reds"
$dstReds = "$rsDir\CP77-External-Radio.reds"
if ((Test-Path $dstReds) -and (-not (Test-Path "$dstReds.nc-bak"))) { Copy-Item $dstReds "$dstReds.nc-bak" }
Copy-Item $srcReds $dstReds -Force
Write-Host "[2b] External Radio .reds override installed (backup: .nc-bak)" -ForegroundColor Green

# ---- 3) fonts (backup originals first) ----
$fBase = "$cet\fonts\NotoSans-Regular.ttf"
$fCJK  = "$cet\fonts\NotoSansTC-Regular.otf"
if (-not (Test-Path "$cet\fonts")) { New-Item -ItemType Directory -Force -Path "$cet\fonts" | Out-Null }
if ((Test-Path $fBase) -and (-not (Test-Path "$fBase.nc-bak"))) { Copy-Item $fBase "$fBase.nc-bak" }
if ((Test-Path $fCJK) -and (-not (Test-Path "$fCJK.nc-bak")))  { Copy-Item $fCJK  "$fCJK.nc-bak" }
Copy-Item "$fontsDir\Latin-Rajdhani-Regular.ttf" $fBase -Force
Copy-Item "$fontsDir\CJK-HarmonyOS-SC-Regular.ttf" $fCJK -Force
Write-Host "[3/6] fonts installed (originals backed up with .nc-bak)" -ForegroundColor Green

# ---- 4) CET font language = ChineseFull (merge config.json) ----
$cfgPath = "$cet\config.json"
$cfg = @{}
if (Test-Path $cfgPath) {
    try { $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json -AsHashtable } catch { $cfg = @{} }
}
if (-not $cfg.ContainsKey("font")) { $cfg["font"] = @{} }
$cfg["font"]["language"] = "ChineseFull"
if (-not $cfg["font"].ContainsKey("path")) { $cfg["font"]["path"] = "" }
[System.IO.File]::WriteAllText($cfgPath, ($cfg | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[4/6] CET ChineseFull font mode enabled" -ForegroundColor Green

# ---- 5) helper exe + side config + autostart ----
$appDir = Join-Path $env:LOCALAPPDATA "NCPersonalRadio"
New-Item -ItemType Directory -Force -Path $appDir | Out-Null
Copy-Item "$companion\ncp_media_helper.exe" "$appDir\ncp_media_helper.exe" -Force
$helperCfg = @{
    out     = "$modDir\media.json"
    cmd     = "$modDir\cmd.json"
    prefer  = "apple,cloudmusic"
    interval = 0.35
}
[System.IO.File]::WriteAllText("$appDir\config.json", ($helperCfg | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[5/6] media helper installed to $appDir" -ForegroundColor Green

# ---- optional autostart ----
if (-not $NoAutoStart) {
    $startup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut("$startup\NCPERSONAL Media Helper.lnk")
    $sc.TargetPath = "$appDir\ncp_media_helper.exe"
    $sc.WorkingDirectory = $appDir
    $sc.Save()
    Write-Host "Autostart enabled (delete the Startup shortcut to disable)" -ForegroundColor Green
}

Write-Host ""
function Set-StationName([string]$name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return $false }
    $name = $name.Trim().Trim('"')
    if ($name -notmatch '^\d') {
        Write-Host "Station name must start with a number (e.g. 88.8 My Radio). Kept the default." -ForegroundColor Yellow
        return $false
    }
    $name = $name -replace "['\r\n]", ''
    # tweak file
    $yf = "$GameDir\r6\tweaks\CP77-External-Radio.yaml"
    if (Test-Path $yf) {
        $yc = Get-Content $yf -Raw -Encoding UTF8
        $yc = $yc -replace '(?m)^(\s*)displayName:.*$', ('${1}displayName: "' + $name + '"')
        [System.IO.File]::WriteAllText($yf, $yc, (New-Object System.Text.UTF8Encoding($false)))
    }
    # lua HUD constant
    $lf = "$modDir\init.lua"
    if (Test-Path $lf) {
        $lc = Get-Content $lf -Raw -Encoding UTF8
        $lc = $lc -replace "(local STATION_NAME = ')[^']*(')", ('${1}' + $name + '${2}')
        [System.IO.File]::WriteAllText($lf, $lc, (New-Object System.Text.UTF8Encoding($false)))
    }
    Write-Host "Station renamed to: $name" -ForegroundColor Green
    return $true
}
if (-not $StationName) {
    $ans = Read-Host "Custom station name? (Enter for default, or type e.g. 88.8 My Radio)"
    if ($ans) { $StationName = $ans }
}
Set-StationName $StationName | Out-Null
Start-Process -FilePath "$appDir\ncp_media_helper.exe" -WindowStyle Hidden
Write-Host "Helper launched in background." -ForegroundColor Cyan
Write-Host "[6/6] Done. Start the helper once now? Run:  $appDir\ncp_media_helper.exe" -ForegroundColor Cyan
Write-Host "Reminders:" -ForegroundColor Yellow
Write-Host "  - Enable 'System Media Control' in NetEase Cloud Music / keep Apple Music SMTC on"
Write-Host "  - In game select 94.7 Piers station; switch app = edit prefer in $appDir\config.json"
Read-Host "Press Enter to exit"
