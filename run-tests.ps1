# run-tests.ps1 - Multi-group test runner (v8)
# Runs tests in namespace-based groups to avoid native resource exhaustion.
# Single-process runs crash at ~460 tests due to BouncyCastle/GDI handle leaks.
# FrmOptions tests are isolated (1 per process) due to ObjectListView resource leaks.
#
# CRITICAL: --verbosity normal required (minimal crashes testhost on .NET 10).
# CRITICAL: --results-directory must be OUTSIDE the repo (TestResults in repo causes crashes).
# CRITICAL: Do NOT create testhost.runtimeconfig.json (BOM from Set-Content crashes testhost).
# v8: Uses TRX logger for reliable results even on partial crashes.
#     .NET Process API drains stdout to prevent buffer deadlock.

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

Write-Host "=== mRemoteNG Test Runner v8 ===" -ForegroundColor Cyan

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
    Start-Sleep -Milliseconds 500
}

function Run-DotnetTest($dll, $filter) {
    # Uses TRX logger for reliable result capture (survives partial crashes).
    # .NET Process API drains stdout to prevent buffer deadlock.
    $uid = [guid]::NewGuid().ToString("N").Substring(0,8)
    $resultsDir = "$resultsBase-$uid"
    $trxFile = "results.trx"
    $procArgs = "test `"$dll`" --results-directory `"$resultsDir`" --verbosity normal"
    $procArgs += " --logger `"trx;LogFileName=$trxFile`""
    if ($filter) { $procArgs += " --filter `"$filter`"" }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "dotnet"
    $psi.Arguments = $procArgs
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stderrTask = $proc.StandardError.ReadToEndAsync()

    # Drain stdout line-by-line, keep last 10 for crash detection
    $tail = New-Object System.Collections.Generic.Queue[string]
    while ($null -ne ($line = $proc.StandardOutput.ReadLine())) {
        $tail.Enqueue($line)
        while ($tail.Count -gt 10) { [void]$tail.Dequeue() }
    }

    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    $stderr = $stderrTask.GetAwaiter().GetResult()

    # Try to parse TRX file first (most reliable)
    $trxPath = Join-Path $resultsDir $trxFile
    $p = 0; $f = 0; $s = 0; $total = 0; $crashed = $false

    if (Test-Path $trxPath) {
        try {
            [xml]$trx = Get-Content $trxPath -Raw
            $counters = $trx.TestRun.ResultSummary.Counters
            $p = [int]$counters.passed
            $f = [int]$counters.failed
            $total = [int]$counters.total
            $s = $total - $p - $f
            # Check if test run was aborted
            $outcome = $trx.TestRun.ResultSummary.outcome
            if ($outcome -eq "Aborted" -or $outcome -eq "Error") {
                $crashed = $true
            }
        } catch {
            # TRX parse failed, fall back to stdout
        }
    }

    # Fall back to stdout parsing if TRX unavailable or empty
    if ($total -eq 0 -and $p -eq 0) {
        $tailText = ($tail.ToArray() -join "`n")
        if ($tailText -match 'Passed\s*[:-]\s*(\d+)') { $p = [int]$Matches[1] }
        if ($tailText -match 'Failed\s*[:-]\s*(\d+)') { $f = [int]$Matches[1] }
        if ($tailText -match 'Total tests:\s+(\d+)') { $total = [int]$Matches[1] }
    }

    # Crash detection from stderr and stdout
    $allText = ($tail.ToArray() -join "`n") + "`n" + $stderr
    if (($allText -match "crashed|aborted") -and ($p -eq 0)) {
        $crashed = $true
    }

    Remove-Item $resultsDir -Recurse -Force -ErrorAction SilentlyContinue

    return @{ Passed=$p; Failed=$f; Skipped=$s; Total=$total; Crashed=$crashed; ExitCode=$exitCode }
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
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
    $r = Run-DotnetTest $testDll $g.Filter
    if ($r.Crashed) {
        Write-Host "$($r.Passed)p/CRASHED" -ForegroundColor Red; $anyCrashed = $true
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
    $r = Run-DotnetTest $testDll $t.Filter
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
    $r = Run-DotnetTest $specsDll $null
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
if ($anyCrashed) { Write-Host "  CRASHES: yes (partial results included)" -ForegroundColor Red }
if ($totalTests -lt $MIN_TOTAL_TESTS) { Write-Host "  WARNING: Only $totalTests tests (expected >$MIN_TOTAL_TESTS)" -ForegroundColor Red }
Write-Host "  Time:    $($elapsed.ToString('mm\:ss'))"
Write-Host "=============================" -ForegroundColor Cyan

if ($totalFailed -gt 0 -or $anyCrashed -or $totalTests -lt $MIN_TOTAL_TESTS) { exit 1 }
exit 0
