param([string]$Godot)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'resolve-godot.ps1') -Godot $Godot
$testRoot = Join-Path $repoRoot ('.local/tests/' + [guid]::NewGuid().ToString('N'))
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $testRoot 'import'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    & $Godot --headless --path $repoRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Import failed.' }
    $scenarios = @('check','card_layout','collection_build','hud_input','packs','ring_order','energy','damage_progression','production_prices','card_actions','ring_health')
    foreach ($scenario in $scenarios) {
        $env:APPDATA = Join-Path $testRoot $scenario
        New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
        $result = & $Godot --headless --path $repoRoot --script ('res://tests/' + $scenario + '.gd') 2>&1
        $code = $LASTEXITCODE
        $result | ForEach-Object { Write-Output "$_" }
        if ($code -ne 0 -or (($result -join "`n") -match '(?m)^(SCRIPT )?ERROR:')) { throw "Failed: $scenario" }
    }
    $env:APPDATA = Join-Path $testRoot 'smoke'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    & $Godot --headless --path $repoRoot --fixed-fps 120 -- --smoke-test
    if ($LASTEXITCODE -ne 0) { throw 'Smoke test failed.' }
} finally { $env:APPDATA = $previousAppData }
