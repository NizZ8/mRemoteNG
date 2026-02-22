# hunt-crasher.ps1
param([string]$Filter)
$repoRoot = "D:\github\mRemoteNG"
$testDll = "$repoRoot\mRemoteNGTests\bin\x64\Release\mRemoteNGTests.dll"

Write-Host "Listing tests for filter: $Filter"
# Only take lines that look like test names (starting with 4 spaces)
$list = & dotnet test $testDll --filter "$Filter" --list-tests --verbosity quiet 2>&1
$tests = $list | Where-Object { $_ -match '^\s{4}[a-zA-Z0-9_]' } | ForEach-Object { $_.Trim() }

if ($null -eq $tests) { Write-Host "No tests found."; exit }

Write-Host "Found $($tests.Count) tests. Running one by one..."
$crashes = 0
foreach ($t in $tests) {
    Write-Host "[$crashes] Running: $t ... " -NoNewline
    $out = & dotnet test $testDll --filter "FullyQualifiedName~.$t" --verbosity quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CRASHED or FAILED!" -ForegroundColor Red
        $crashes++
    } else {
        Write-Host "OK" -ForegroundColor Green
    }
}
