param([string]$Godot)
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $Godot) { $Godot = $env:GODOT_BIN }
if (-not $Godot -and (Test-Path (Join-Path $repoRoot '.local/godot-path.txt'))) {
    $Godot = (Get-Content (Join-Path $repoRoot '.local/godot-path.txt') -Raw).Trim()
}
if (-not $Godot) {
    foreach ($name in @('godot', 'godot4')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { $Godot = $command.Source; break }
    }
}
if (-not $Godot -or -not (Test-Path -LiteralPath $Godot)) {
    throw 'Set GODOT_BIN to the Godot 4.6.3 console executable, or pass -Godot.'
}
$Godot = (Resolve-Path -LiteralPath $Godot).Path
