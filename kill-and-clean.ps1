# kill-and-clean.ps1
Write-Host "Killing all related processes..." -ForegroundColor Yellow
$processes = @("mRemoteNG", "testhost", "dotnet", "MSBuild", "VBCSCompiler")
foreach ($p in $processes) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

Write-Host "Cleaning bin/obj folders..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include bin,obj -Recurse | ForEach-Object {
    $path = $_.FullName
    Write-Host "Removing $path"
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "Clean finished." -ForegroundColor Green
