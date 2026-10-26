<#
K1 High-Res Feat & Power Trees - patcher for Star Wars: Knights of the Old Republic (2003)

At high resolutions the feat and Force power selection screens draw their icons at the size the
engine hardcodes for 640x480: every tree row is 40 px tall (icons are row-height squares) and the
arrows between icons are 32 px. KotOR High Resolution Menus rescales the .gui files, but these
sizes are not read from any .gui (LB_FEATS' PROTOITEM is ignored), so the icons stay tiny.

This script rescales the six hardcoded values in swkotor.exe by (menu height / 480), the same
factor High Resolution Menus applies to everything else, so the trees keep vanilla proportions.

    K1FeatTrees.ps1 [-GameDir <folder>] [-Height <menu height>] [-Uninstall] [-DryRun]

-Height overrides the menu height that is otherwise read from High Resolution Menus' constants
in the exe. -Uninstall writes the six original values back. Nothing else in the file is touched.
#>
[CmdletBinding()]
param(
    [string]$GameDir,
    [int]$Height = 0,
    [switch]$Uninstall,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$Product = 'K1 High-Res Feat & Power Trees 1.0.0'

# VA -> file offset is VA - 0x400000 for .text in swkotor.exe (Editable Executable / GOG 1.03).
# Each site: file offset of the operand, the instruction bytes that must precede it, operand size,
# the vanilla value, and what it becomes ('row', 'arrow', '-arrow', '-arrow/2').
$Sites = @(
    @{ Off = 0x2CD8D9; Prefix = 'C7442424'; Size = 4; Vanilla = 40;  Kind = 'row';      What = 'feat tree row height (mov dword [esp+0x24], 40)' },
    @{ Off = 0x2CDB79; Prefix = 'C7442424'; Size = 4; Vanilla = 40;  Kind = 'row';      What = 'power tree row height (mov dword [esp+0x24], 40)' },
    @{ Off = 0x2CCE5F; Prefix = 'B8';       Size = 4; Vanilla = 32;  Kind = 'arrow';    What = 'arrow size (mov eax, 32)' },
    @{ Off = 0x2CCF08; Prefix = '8D41';     Size = 1; Vanilla = -32; Kind = '-arrow';   What = 'arrow vertical centring (lea eax, [ecx-32])' },
    @{ Off = 0x2CCF2A; Prefix = '8D5408';   Size = 1; Vanilla = -16; Kind = '-arrow/2'; What = 'first arrow horizontal centring (lea edx, [eax+ecx-16])' },
    @{ Off = 0x2CCF5C; Prefix = '8D5408';   Size = 1; Vanilla = -16; Kind = '-arrow/2'; What = 'second arrow horizontal centring (lea edx, [eax+ecx-16])' }
)
# KotOR High Resolution Menus writes the menu size into these int32 operands (negated for the first
# pair). Same offsets K1 Area Map Fixes reads.
$HrHeightNeg = @(0xB6DA, 0xBA83)
$HrHeightPos = @(0xAA85)

function Fail([string]$msg) {
    Write-Host ''
    Write-Host '  STOPPED - your game has not been changed.' -ForegroundColor Yellow
    Write-Host ''
    foreach ($line in $msg -split "`n") { Write-Host "  $line" }
    Write-Host ''
    exit 1
}

function Find-Game {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($GameDir) { $candidates.Add($GameDir) }
    $candidates.Add((Get-Location).Path)
    $dir = $PSScriptRoot
    while ($dir) { $candidates.Add($dir); $dir = Split-Path $dir -Parent }
    foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1207666283', 'HKLM:\SOFTWARE\GOG.com\Games\1207666283') {
        try { $candidates.Add((Get-ItemProperty $key -ErrorAction Stop).path) } catch {}
    }
    try {
        $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        $libs = @($steam)
        if (Test-Path $vdf) {
            $libs += [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
        }
        foreach ($lib in $libs) { $candidates.Add((Join-Path $lib 'steamapps\common\swkotor')) }
    } catch {}
    foreach ($c in $candidates) {
        if ($c -and (Test-Path (Join-Path $c 'swkotor.exe')) -and (Test-Path (Join-Path $c 'chitin.key'))) { return (Resolve-Path $c).Path }
    }
    if ($GameDir) { Fail "There is no swkotor.exe in:`n    $GameDir" }
    Write-Host 'I could not find KOTOR by myself.'
    $typed = (Read-Host 'Paste your KOTOR folder (the one containing swkotor.exe)').Trim('"', ' ')
    if ($typed -and (Test-Path (Join-Path $typed 'swkotor.exe'))) { return (Resolve-Path $typed).Path }
    Fail 'That folder has no swkotor.exe in it.'
}

function Read-Value([byte[]]$data, $site) {
    if ($site.Size -eq 4) { return [BitConverter]::ToInt32($data, $site.Off) }
    $b = [int]$data[$site.Off]; if ($b -ge 128) { $b -= 256 }; return $b
}

function Write-Value([byte[]]$data, $site, [int]$value) {
    if ($site.Size -eq 4) { [Array]::Copy([BitConverter]::GetBytes([int32]$value), 0, $data, $site.Off, 4) }
    else { $data[$site.Off] = [byte]($value -band 0xFF) }
}

function Hex([byte[]]$data, [int]$off, [int]$n) { -join ($data[$off..($off + $n - 1)] | ForEach-Object { $_.ToString('X2') }) }

Write-Host $Product
Write-Host ''
$game = Find-Game
$exe = Join-Path $game 'swkotor.exe'
Write-Host "  Game:        $game"

$data = [IO.File]::ReadAllBytes($exe)
if ($data.Length -lt 0x300000 -or $data[0] -ne 0x4D -or $data[1] -ne 0x5A) {
    Fail "swkotor.exe is not the executable this patcher knows ($($data.Length) bytes)."
}
foreach ($s in $Sites) {
    $plen = $s.Prefix.Length / 2
    if ((Hex $data ($s.Off - $plen) $plen) -ne $s.Prefix) {
        Fail ("This swkotor.exe is not one I can patch.`n`n" +
              "Steam players: install the 'KOTOR Editable Executable' first - the Steam exe is packed and`n" +
              "no exe patch (UniWS, High Resolution Menus, this) can work on it. GOG players: your exe`n" +
              "should work as-is; this usually means a different language build or the 4-CD retail exe.`n`n" +
              ("(Expected {0} before file offset 0x{1:X}.)" -f $s.Prefix, $s.Off))
    }
}

$current = $Sites | ForEach-Object { Read-Value $data $_ }
$rowNow, $arrowNow = $current[0], $current[2]
if ($current[1] -ne $rowNow -or $current[3] -ne -$arrowNow -or $current[4] -ne [int](-$arrowNow / 2) -or $current[5] -ne $current[4] -or $rowNow -lt 16 -or $rowNow -gt 1000) {
    Fail ("The values at the patch sites do not look like the original game or an earlier install of`n" +
          "this mod, so another patch may have changed them. Found: $($current -join ', ').")
}
$installed = $rowNow -ne 40
Write-Host ("  Now:         rows {0} px, arrows {1} px{2}" -f $rowNow, $arrowNow, $(if ($installed) { ' (this mod is installed)' } else { ' (original game values)' }))

if ($Uninstall) {
    $row, $arrow = 40, 32
} else {
    if ($Height -le 0) {
        $hs = @($HrHeightNeg | ForEach-Object { -[BitConverter]::ToInt32($data, $_) }) + @($HrHeightPos | ForEach-Object { [BitConverter]::ToInt32($data, $_) })
        if (@($hs | Select-Object -Unique).Count -ne 1) {
            Fail ("I could not read your menu size from the exe (found $($hs -join ', ')).`n" +
                  "Run again with your menu height, e.g.:  K1FeatTrees.ps1 -Height 1440")
        }
        $Height = $hs[0]
        if ($Height -eq 480) {
            Fail ("Your menus are still the original 640x480 size, so there is nothing to fix.`n" +
                  "Install UniWS and KotOR High Resolution Menus first, then run this again.")
        }
        Write-Host "  Menus:       $Height px tall (from KotOR High Resolution Menus)"
    } else {
        Write-Host "  Menus:       $Height px tall (given with -Height)"
    }
    if ($Height -lt 480 -or $Height -gt 8640) { Fail "A menu height of $Height px is not plausible." }
    $k = $Height / 480.0
    $row = [int][Math]::Round(40 * $k)
    $arrow = [Math]::Min(128, [int][Math]::Round(32 * $k))   # 128: the centring offsets are signed bytes
    $arrow -= $arrow % 2
}

$new = @{ 'row' = $row; 'arrow' = $arrow; '-arrow' = -$arrow; '-arrow/2' = [int](-$arrow / 2) }
Write-Host ("  Target:      rows {0} px, arrows {1} px" -f $row, $arrow)
if ($row -eq $rowNow -and $arrow -eq $arrowNow) {
    Write-Host ''
    Write-Host '  Nothing to do - already set to these sizes.' -ForegroundColor Green
    exit 0
}

$out = [byte[]]$data.Clone()
foreach ($s in $Sites) {
    Write-Value $out $s $new[$s.Kind]
    Write-Verbose ("0x{0:X6}  {1,5} -> {2,5}  {3}" -f $s.Off, (Read-Value $data $s), $new[$s.Kind], $s.What)
}
if ($DryRun) {
    Write-Host ''
    Write-Host '  -DryRun: nothing was written.'
    exit 0
}

$backup = "$exe.before-feat-trees.bak"
if (-not $installed -and -not (Test-Path $backup)) {
    Copy-Item $exe $backup
    Write-Host "  Backup:      $backup"
}
try { [IO.File]::WriteAllBytes($exe, $out) }
catch { Fail "Could not write swkotor.exe. Close the game (and any editor holding the file) and try again.`n`n$($_.Exception.Message)" }

$check = [IO.File]::ReadAllBytes($exe)
if (-not [Linq.Enumerable]::SequenceEqual($check, $out)) { Fail "The file on disk does not match what was written. Restore from $backup." }
$changed = 0
foreach ($s in $Sites) { for ($i = $s.Off; $i -lt $s.Off + $s.Size; $i++) { if ($data[$i] -ne $out[$i]) { $changed++ } } }

Write-Host ''
if ($Uninstall) { Write-Host '  Uninstalled - original sizes restored.' -ForegroundColor Green }
else { Write-Host "  Done - $changed bytes changed and verified. Feat and Force power icons now scale with your menus." -ForegroundColor Green }
Write-Host '  If you change resolution with High Resolution Menus later, run Install.bat again.'
