# run-tests.ps1 - The Truth Seeker
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDll = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"

Write-Host "=== mRemoteNG Strict Accountant ===" -ForegroundColor Cyan

# 1. Total static count
$list = & dotnet test $testDll --list-tests --verbosity quiet 2>&1 | Out-String
$allLines = $list -split "`n"
$expected = ($allLines | Where-Object { $_ -match '^\s{4}\S' }).Count
Write-Host "Expected Total (from DLL): $expected" -ForegroundColor Yellow

# 2. Run in groups
$groups = @("Security", "Config", "Connection", "Credential", "Tools", "App", "Messages", "Tree", "UI")
$actual = 0
$totalFailed = 0

foreach ($g in $groups) {
    Write-Host "Group [$g]: " -NoNewline
    $out = & dotnet test $testDll --filter "FullyQualifiedName~mRemoteNGTests.$g" --verbosity quiet 2>&1 | Out-String
    
    $pMatch = [regex]::Match($out, 'Passed:\s+(\d+)')
    $fMatch = [regex]::Match($out, 'Failed:\s+(\d+)')
    
    $p = 0; $f = 0
    if ($pMatch.Success) { $p = [int]$pMatch.Groups[1].Value }
    if ($fMatch.Success) { $f = [int]$fMatch.Groups[1].Value }
    
    $groupTotal = $p + $f
    if ($groupTotal -eq 0 -and $out -match "discovered") {
        Write-Host "CRASHED!" -ForegroundColor Red
    } else {
        Write-Host "$p Passed, $f Failed" -ForegroundColor Green
        $actual += $groupTotal
        $totalFailed += $f
    }
}

# 3. Final summary
Write-Host ""
Write-Host "--- SUMMARY ---" -ForegroundColor Cyan
Write-Host "Expected: $expected"
Write-Host "Actual:   $actual"
$lost = $expected - $actual
if ($lost -gt 0) { Write-Host "Lost:     $lost (Process Crashes)" -ForegroundColor Red }

if ($actual -lt $expected -or $totalFailed -gt 0) {
    exit 1
}
exit 0
