# run-tests.ps1 - Test runner with FrmOptions process isolation
# FrmOptions + ObjectListView leak native Win32 resources.
# Even 2 tests touching FrmOptions in the same testhost crash it.
# Solution: run everything in one process EXCEPT FrmOptions tests.

param(
    [switch]$Headless,
    [switch]$NoBuild,
    [switch]$Sequential
)

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDll  = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"
$specsDll = "$repoRoot\mRemoteNGSpecs\bin\x64\Release\mRemoteNGSpecs.dll"

Write-Host "=== mRemoteNG Test Runner v4 ===" -ForegroundColor Cyan

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
$backupDir = "$repoRoot\mRemoteNGTests\bin\x64\Release\.backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
Copy-Item $testDll "$backupDir\mRemoteNGTests.dll" -Force

function Parse-TestOutput($out) {
    $p = 0; $f = 0; $s = 0
    if ($out -match 'Passed\s*[:\s]+(\d+)')  { $p = [int]$Matches[1] }
    if ($out -match 'Failed\s*[:\s]+(\d+)')  { $f = [int]$Matches[1] }
    if ($out -match 'Skipped\s*[:\s]+(\d+)') { $s = [int]$Matches[1] }
    $crashed = (($out -match "crashed") -or ($out -match "aborted")) -and (($p + $f) -eq 0)
    return @{ Passed=$p; Failed=$f; Skipped=$s; Crashed=$crashed }
}

$totalPassed = 0; $totalFailed = 0; $totalSkipped = 0; $anyCrashed = $false
$startTime = Get-Date

# Phase 1: ALL tests EXCEPT FrmOptions (single process)
Write-Host "`n[Phase 1] All tests (except FrmOptions)..." -ForegroundColor Yellow
$mainFilter = "FullyQualifiedName!~OptionsFormTests&FullyQualifiedName!~AllOptionsPagesTests"
$out1 = & dotnet test $testDll --filter $mainFilter --verbosity minimal 2>&1 | Out-String
$r1 = Parse-TestOutput $out1
Write-Host "  Passed: $($r1.Passed), Failed: $($r1.Failed), Skipped: $($r1.Skipped)" -ForegroundColor $(if ($r1.Failed -gt 0 -or $r1.Crashed) { "Red" } else { "Green" })
if ($r1.Crashed) { Write-Host "  CRASH DETECTED" -ForegroundColor Red; $anyCrashed = $true }
$totalPassed += $r1.Passed; $totalFailed += $r1.Failed; $totalSkipped += $r1.Skipped

# Phase 2: FrmOptions isolated (each test in its own process)
Write-Host "`n[Phase 2] FrmOptions isolated..." -ForegroundColor Yellow
$isolatedFilters = @(
    @{ Name = "FormBehavior"; Filter = "Name=FormBehavior" },
    @{ Name = "AllPages";     Filter = "Name=AllPagesExistWithIconsAndLoadCorrectSettings" }
)

foreach ($t in $isolatedFilters) {
    Write-Host "  [$($t.Name)] " -NoNewline
    $out = & dotnet test $testDll --filter $t.Filter --verbosity minimal 2>&1 | Out-String
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
    $out = & dotnet test $specsDll --verbosity minimal 2>&1 | Out-String
    $r = Parse-TestOutput $out
    $specColor = if ($r.Failed -gt 0) { "Yellow" } else { "Green" }
    Write-Host "  Specs: $($r.Passed)p/$($r.Failed)f" -ForegroundColor $specColor
}

# Restore DLL if crash deleted it
if (-not (Test-Path $testDll) -and (Test-Path "$backupDir\mRemoteNGTests.dll")) {
    Write-Host "`n[Recovery] Restoring test DLL from backup" -ForegroundColor Yellow
    Copy-Item "$backupDir\mRemoteNGTests.dll" $testDll -Force
}

# Summary
$elapsed = (Get-Date) - $startTime
$totalTests = $totalPassed + $totalFailed + $totalSkipped

Write-Host ""
Write-Host "========== RESULTS ==========" -ForegroundColor Cyan
Write-Host "  Total:   $totalTests"
Write-Host "  Passed:  $totalPassed" -ForegroundColor Green
if ($totalFailed -gt 0) { Write-Host "  Failed:  $totalFailed" -ForegroundColor Red }
if ($totalSkipped -gt 0) { Write-Host "  Skipped: $totalSkipped" -ForegroundColor Yellow }
if ($anyCrashed) { Write-Host "  CRASHES: yes" -ForegroundColor Red }
Write-Host "  Time:    $($elapsed.ToString('mm\:ss'))"
Write-Host "=============================" -ForegroundColor Cyan

if ($totalFailed -gt 0 -or $anyCrashed) { exit 1 }
exit 0
