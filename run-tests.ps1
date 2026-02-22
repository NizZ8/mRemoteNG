# run-tests.ps1 - The Final Truth Accountant v3 (Bulletproof)
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDll = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"
$logDir = "$repoRoot\TestResults"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

Write-Host "=== mRemoteNG Ultimate Test Runner ===" -ForegroundColor Cyan

# 1. Discover all tests
Write-Host "Discovering tests... " -NoNewline
$list = & dotnet test $testDll --list-tests --verbosity quiet 2>&1 | Out-String
$allTests = $list -split "`n" | Where-Object { $_ -match '^\s{4}\S' } | ForEach-Object { $_.Trim() }
$expected = $allTests.Count
Write-Host "$expected found" -ForegroundColor Yellow

# 2. Define Groups
$safeGroups = @(
    @{ Name = "Security"; Filter = "FullyQualifiedName~mRemoteNGTests.Security" },
    @{ Name = "Connection"; Filter = "FullyQualifiedName~mRemoteNGTests.Connection" },
    @{ Name = "Credential"; Filter = "FullyQualifiedName~mRemoteNGTests.Credential" },
    @{ Name = "Config"; Filter = "FullyQualifiedName~mRemoteNGTests.Config&FullyQualifiedName!~mRemoteNGTests.Config.Serializers.ConnectionSerializers.Xml" },
    @{ Name = "Tools"; Filter = "FullyQualifiedName~mRemoteNGTests.Tools|FullyQualifiedName~mRemoteNGTests.App|FullyQualifiedName~mRemoteNGTests.Messages|FullyQualifiedName~mRemoteNGTests.Tree" }
)

$actual = 0; $failedCount = 0;

# 3. Run Safe Groups in Parallel
$jobs = @()
foreach ($g in $safeGroups) {
    $log = "$logDir\$($g.Name).log"
    $job = Start-Job -ScriptBlock {
        param($dll, $filter, $log)
        & dotnet test $dll --filter "$filter" --verbosity quiet 2>&1 | Tee-Object -FilePath $log
    } -ArgumentList $testDll, $g.Filter, $log
    $jobs += @{ Job = $job; Name = $g.Name; Log = $log }
}

foreach ($j in $jobs) {
    Wait-Job $j.Job | Out-Null
    if (Test-Path $j.Log) {
        $content = Get-Content $j.Log -Raw
        $p = [regex]::Match($content, 'Passed:\s+(\d+)'); $f = [regex]::Match($content, 'Failed:\s+(\d+)')
        $pc = if ($p.Success) { [int]$p.Groups[1].Value } else { 0 }
        $fc = if ($f.Success) { [int]$f.Groups[1].Value } else { 0 }
        Write-Host "Group [$($j.Name)]: $pc Passed, $fc Failed" -ForegroundColor $(if ($fc -gt 0) { "Red" } else { "Green" })
        $actual += ($pc + $fc); $failedCount += $fc
    }
    Remove-Job $j.Job
}

# 4. Run Unsafe Groups (UI, XML) One-by-One
Write-Host "Running unstable/UI tests sequentially to ensure isolation..." -ForegroundColor Yellow
$unsafeFilter = "FullyQualifiedName~mRemoteNGTests.UI|FullyQualifiedName~mRemoteNGTests.Config.Serializers.ConnectionSerializers.Xml"
$unsafeList = & dotnet test $testDll --filter "$unsafeFilter" --list-tests --verbosity quiet 2>&1 | Out-String
$unsafeTests = $unsafeList -split "`n" | Where-Object { $_ -match '^\s{4}\S' } | ForEach-Object { $_.Trim() }

foreach ($t in $unsafeTests) {
    $out = & dotnet test $testDll --filter "FullyQualifiedName~.$t" --verbosity quiet 2>&1 | Out-String
    $p = [regex]::Match($out, 'Passed:\s+(\d+)'); $f = [regex]::Match($out, 'Failed:\s+(\d+)')
    if ($p.Success) { $actual++; }
    elseif ($f.Success) { 
        Write-Host " [FAIL: $t] " -ForegroundColor Red
        $actual++; $failedCount++
    }
    else {
        Write-Host " [CRASH: $t] " -ForegroundColor Red
        # Even on crash, we count it as 'attempted' but failed
        $actual++; $failedCount++
    }
}

# 5. Check Remnants (Anything else?)
if ($actual -lt $expected) {
    Write-Host "Checking for remnants..." -ForegroundColor Yellow
    # ... logic to run anything else ...
}

Write-Host ""
Write-Host "--- SUMMARY ---" -ForegroundColor Cyan
Write-Host "Expected: $expected"
Write-Host "Actual:   $actual"
if ($actual -lt $expected) { Write-Host "LOST:     $(($expected - $actual))" -ForegroundColor Red }

# Final Exit
if ($actual -lt $expected -or $failedCount -gt 0) { exit 1 }
exit 0
