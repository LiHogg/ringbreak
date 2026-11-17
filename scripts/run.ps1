param([string]$Godot, [switch]$Editor)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'resolve-godot.ps1') -Godot $Godot
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $repoRoot '.local/player-data'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    if ($Editor) { & $Godot --path $repoRoot --editor }
    else { & $Godot --path $repoRoot }
    if ($LASTEXITCODE -ne 0) { throw 'Godot exited with an error.' }
} finally { $env:APPDATA = $previousAppData }
