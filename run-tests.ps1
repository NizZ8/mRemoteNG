# run-tests.ps1 - Multi-group test runner (v6)
# Runs tests in namespace-based groups to avoid native resource exhaustion.
# Single-process runs crash at ~460 tests due to BouncyCastle/GDI handle leaks.
# FrmOptions tests are isolated (1 per process) due to ObjectListView resource leaks.
#
# CRITICAL: --verbosity normal required (minimal crashes testhost on .NET 10).
# CRITICAL: --results-directory must be OUTSIDE the repo (TestResults in repo causes crashes).
# CRITICAL: Do NOT create testhost.runtimeconfig.json (BOM from Set-Content crashes testhost).

param(
    [switch]$Headless,
    [switch]$NoBuild,
    [switch]$Sequential
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDll  = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"
$specsDll = "$repoRoot\mRemoteNGSpecs\bin\x64\Release\mRemoteNGSpecs.dll"
$testDir  = "$repoRoot\mRemoteNGTests\bin\x64\Release"
$resultsBase = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "mremoteng-testresults")

Write-Host "=== mRemoteNG Test Runner v6 ===" -ForegroundColor Cyan

# Build
if (-not $NoBuild) {
    Write-Host "[Build] Full build..." -ForegroundColor Yellow
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repoRoot\build.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[Build] FAILED" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $testDll)) {
    Write-Host "[ERROR] Test DLL not found: $testDll" -ForegroundColor Red
    exit 1
}

# Backup test DLL (protect from crash deletion)
$backupDir = "$testDir\.backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
Copy-Item $testDll "$backupDir\mRemoteNGTests.dll" -Force

function Ensure-TestEnvironment {
    Get-Process testhost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process testhost.x86 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item "$repoRoot\TestResults" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$testDir\testhost.runtimeconfig.json" -Force -ErrorAction SilentlyContinue
}

function Run-DotnetTest($dll, $filter) {
    # Run via cmd.exe batch file to bypass PowerShell pipeline back-pressure.
    # PowerShell pipeline (even Select-Object -Last) causes testhost crashes in larger groups.
    $uid = [guid]::NewGuid().ToString("N").Substring(0,8)
    $resultsDir = "$resultsBase-$uid"
    $outFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "mrt-out-$uid.txt")
    $batFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "mrt-run-$uid.cmd")
    $cmd = "dotnet test `"$dll`" --results-directory `"$resultsDir`" --verbosity normal"
    if ($filter) { $cmd += " --filter `"$filter`"" }
    [System.IO.File]::WriteAllText($batFile, "@echo off`r`n$cmd", [System.Text.Encoding]::ASCII)
    & cmd /c "`"$batFile`" > `"$outFile`" 2>&1"
    $result = ""
    if (Test-Path $outFile) { $result = [System.IO.File]::ReadAllText($outFile) }
    Remove-Item $batFile -Force -ErrorAction SilentlyContinue
    Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    Remove-Item $resultsDir -Recurse -Force -ErrorAction SilentlyContinue
    return $result
}

function Parse-TestOutput($out) {
    if (-not $out) { return @{ Passed=0; Failed=0; Skipped=0; Total=0; Crashed=$false } }
    $p = 0; $f = 0; $s = 0; $total = 0
    $allLines = $out -split "`n"
    foreach ($line in $allLines) {
        if ($line -match 'Total tests:\s+(\d+)') { $total = [int]$Matches[1] }
        if ($line -match '^\s{2,}Passed\s*[:-]\s*(\d+)') { $p = [int]$Matches[1] }
        if ($line -match '^\s{2,}Failed\s*[:-]\s*(\d+)') { $f = [int]$Matches[1] }
        if ($line -match '^\s{2,}Skipped\s*[:-]\s*(\d+)') { $s = [int]$Matches[1] }
    }
    $joined = $allLines -join "`n"
    if ($p -eq 0 -and $joined -match 'Passed\s*[:-]\s*(\d+)') { $p = [int]$Matches[1] }
    if ($f -eq 0 -and $joined -match 'Failed\s*[:-]\s*(\d+)') { $f = [int]$Matches[1] }
    if ($s -eq 0 -and $joined -match 'Skipped\s*[:-]\s*(\d+)') { $s = [int]$Matches[1] }
    $crashed = (($out -match "crashed") -or ($out -match "aborted")) -and ($total -eq 0) -and ($p -eq 0)
    return @{ Passed=$p; Failed=$f; Skipped=$s; Total=$total; Crashed=$crashed }
}

$totalPassed = 0; $totalFailed = 0; $totalSkipped = 0; $anyCrashed = $false
$startTime = Get-Date

# Test groups - each runs in its own process to avoid native resource exhaustion
# Single process crashes at ~460 tests due to BouncyCastle/GDI handle leaks
$groups = @(
    @{ Name="Connection"; Filter="FullyQualifiedName~mRemoteNGTests.Connection" },
    @{ Name="Config.Xml"; Filter="FullyQualifiedName~mRemoteNGTests.Config.Serializers.ConnectionSerializers.Xml" },
    @{ Name="Config.Other"; Filter="FullyQualifiedName~mRemoteNGTests.Config&FullyQualifiedName!~Serializers.ConnectionSerializers.Xml" },
    @{ Name="UI"; Filter="FullyQualifiedName~mRemoteNGTests.UI&FullyQualifiedName!~OptionsFormTests&FullyQualifiedName!~AllOptionsPagesTests" },
    @{ Name="Tools"; Filter="FullyQualifiedName~mRemoteNGTests.Tools" },
    @{ Name="Security"; Filter="FullyQualifiedName~mRemoteNGTests.Security" },
    @{ Name="Tree+Container+Cred"; Filter="FullyQualifiedName~mRemoteNGTests.Tree|FullyQualifiedName~mRemoteNGTests.Container|FullyQualifiedName~mRemoteNGTests.Credential" },
    @{ Name="Remaining"; Filter="FullyQualifiedName!~mRemoteNGTests.Connection&FullyQualifiedName!~mRemoteNGTests.Config&FullyQualifiedName!~mRemoteNGTests.UI&FullyQualifiedName!~mRemoteNGTests.Tools&FullyQualifiedName!~mRemoteNGTests.Security&FullyQualifiedName!~mRemoteNGTests.Tree&FullyQualifiedName!~mRemoteNGTests.Container&FullyQualifiedName!~mRemoteNGTests.Credential&FullyQualifiedName!~mRemoteNGTests.IntegrationTests&FullyQualifiedName!~OptionsFormTests&FullyQualifiedName!~AllOptionsPagesTests" },
    @{ Name="Integration"; Filter="FullyQualifiedName~mRemoteNGTests.IntegrationTests" }
)

Write-Host "`n[Phase 1] Running $($groups.Count) test groups sequentially..." -ForegroundColor Yellow
foreach ($g in $groups) {
    Write-Host "  [$($g.Name)] " -NoNewline
    Ensure-TestEnvironment
    $out = Run-DotnetTest $testDll $g.Filter
    $r = Parse-TestOutput $out
    if ($r.Crashed) {
        Write-Host "CRASHED (0 tests)" -ForegroundColor Red; $anyCrashed = $true
    } elseif ($r.Failed -gt 0) {
        Write-Host "$($r.Passed)p/$($r.Failed)f" -ForegroundColor Red
    } else {
        Write-Host "$($r.Passed) passed" -ForegroundColor Green
    }
    $totalPassed += $r.Passed; $totalFailed += $r.Failed; $totalSkipped += $r.Skipped
}

# Phase 2: FrmOptions isolated (each test in its own process)
Write-Host "`n[Phase 2] FrmOptions isolated..." -ForegroundColor Yellow
$isolatedFilters = @(
    @{ Name = "FormBehavior"; Filter = "Name=FormBehavior" },
    @{ Name = "AllPages";     Filter = "Name=AllPagesExistWithIconsAndLoadCorrectSettings" }
)

foreach ($t in $isolatedFilters) {
    Write-Host "  [$($t.Name)] " -NoNewline
    Ensure-TestEnvironment
    $out = Run-DotnetTest $testDll $t.Filter
    $r = Parse-TestOutput $out
    if ($r.Crashed) {
        Write-Host "CRASHED" -ForegroundColor Red; $anyCrashed = $true
    } elseif ($r.Failed -gt 0) {
        Write-Host "FAILED" -ForegroundColor Red
    } else {
        Write-Host "passed" -ForegroundColor Green
    }
    $totalPassed += $r.Passed; $totalFailed += $r.Failed; $totalSkipped += $r.Skipped
}

# Phase 3: Specs (skip in headless mode)
if (-not $Headless -and (Test-Path $specsDll)) {
    Write-Host "`n[Phase 3] Specs (FlaUI)..." -ForegroundColor Yellow
    Ensure-TestEnvironment
    $out = Run-DotnetTest $specsDll $null
    $r = Parse-TestOutput $out
    $specColor = if ($r.Failed -gt 0) { "Yellow" } else { "Green" }
    Write-Host "  Specs: $($r.Passed)p/$($r.Failed)f" -ForegroundColor $specColor
}

# Restore DLL if crash deleted it
if (-not (Test-Path $testDll) -and (Test-Path "$backupDir\mRemoteNGTests.dll")) {
    Write-Host "`n[Recovery] Restoring test DLL from backup" -ForegroundColor Yellow
    Copy-Item "$backupDir\mRemoteNGTests.dll" $testDll -Force
}

# Final cleanup
Remove-Item "$repoRoot\TestResults" -Recurse -Force -ErrorAction SilentlyContinue

# Summary
$elapsed = (Get-Date) - $startTime
$totalTests = $totalPassed + $totalFailed + $totalSkipped
$MIN_TOTAL_TESTS = 2800

Write-Host ""
Write-Host "========== RESULTS ==========" -ForegroundColor Cyan
Write-Host "  Total:   $totalTests"
Write-Host "  Passed:  $totalPassed" -ForegroundColor Green
if ($totalFailed -gt 0) { Write-Host "  Failed:  $totalFailed" -ForegroundColor Red }
if ($totalSkipped -gt 0) { Write-Host "  Skipped: $totalSkipped" -ForegroundColor Yellow }
if ($anyCrashed) { Write-Host "  CRASHES: yes" -ForegroundColor Red }
if ($totalTests -lt $MIN_TOTAL_TESTS) { Write-Host "  WARNING: Only $totalTests tests (expected >$MIN_TOTAL_TESTS)" -ForegroundColor Red }
Write-Host "  Time:    $($elapsed.ToString('mm\:ss'))"
Write-Host "=============================" -ForegroundColor Cyan

if ($totalFailed -gt 0 -or $anyCrashed -or $totalTests -lt $MIN_TOTAL_TESTS) { exit 1 }
exit 0
