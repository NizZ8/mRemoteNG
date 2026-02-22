# run-tests.ps1 - The Eternal Truth
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDll = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"

Write-Host "=== mRemoteNG Eternal Truth Test Runner ===" -ForegroundColor Cyan

# 1. Total static count
$list = & dotnet test $testDll --list-tests --verbosity quiet 2>&1 | Out-String
$allTests = $list -split "`n" | Where-Object { $_ -match '^\s{4}\S' } | ForEach-Object { $_.Trim() }
$expected = $allTests.Count
Write-Host "Expected Total: $expected" -ForegroundColor Yellow

# 2. Run in logical groups sequentially but with full accounting
$groups = @(
    @{ Name = "Security"; Filter = "FullyQualifiedName~mRemoteNGTests.Security" },
    @{ Name = "Connection"; Filter = "FullyQualifiedName~mRemoteNGTests.Connection" },
    @{ Name = "Credential"; Filter = "FullyQualifiedName~mRemoteNGTests.Credential" },
    @{ Name = "Tools"; Filter = "FullyQualifiedName~mRemoteNGTests.Tools|FullyQualifiedName~mRemoteNGTests.App|FullyQualifiedName~mRemoteNGTests.Messages|FullyQualifiedName~mRemoteNGTests.Tree" },
    @{ Name = "Config"; Filter = "FullyQualifiedName~mRemoteNGTests.Config" },
    @{ Name = "UI"; Filter = "FullyQualifiedName~mRemoteNGTests.UI" }
)

$actual = 0; $failedCount = 0; $processedNames = @{}

foreach ($g in $groups) {
    Write-Host "Running Group [$($g.Name)]... " -NoNewline
    $out = & dotnet test $testDll --filter "$($g.Filter)" --verbosity quiet 2>&1 | Out-String
    $pMatch = [regex]::Match($out, 'Passed:\s+(\d+)'); $fMatch = [regex]::Match($out, 'Failed:\s+(\d+)')
    $p = if ($pMatch.Success) { [int]$pMatch.Groups[1].Value } else { 0 }
    $f = if ($fMatch.Success) { [int]$fMatch.Groups[1].Value } else { 0 }
    
    if (($p + $f) -eq 0 -and $out -match "discovered") {
        Write-Host "CRASHED!" -ForegroundColor Red
    } else {
        Write-Host "$p Passed, $f Failed" -ForegroundColor Green
        $actual += ($p + $f); $failedCount += $f
    }
}

# 3. Final summary
Write-Host ""
Write-Host "--- SUMMARY ---" -ForegroundColor Cyan
Write-Host "Expected: $expected"
Write-Host "Actual:   $actual"
if ($actual -lt $expected) { Write-Host "LOST:     $(($expected - $actual)) tests" -ForegroundColor Red }

if ($actual -lt $expected -or $failedCount -gt 0) { exit 1 }
exit 0
