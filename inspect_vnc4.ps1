$dll = 'D:\github\mRemoteNG\mRemoteNG\bin\x64\Release\Assemblies\VncSharpCore.dll'
if (!(Test-Path $dll)) {
    $dll = (Get-ChildItem -Recurse -Path 'D:\github\mRemoteNG' -Filter 'VncSharpCore.dll' | Select-Object -First 1).FullName
}
Write-Host "Loading: $dll"
$a = [System.Reflection.Assembly]::LoadFile($dll)
$t = $a.GetTypes() | Where-Object { $_.Name -eq 'RemoteDesktop' }
Write-Host "Methods matching Clipboard/Server/Fill:"
$t.GetMethods() | Where-Object { $_.Name -match 'Clipboard|Server|Fill' } | Select-Object Name | Format-Table
Write-Host "`nAll public methods:"
$t.GetMethods() | Where-Object { $_.IsPublic } | Select-Object Name | Format-Table
Write-Host "`nPublic properties:"
$t.GetProperties() | Where-Object { $_.CanRead } | Select-Object Name | Format-Table
Write-Host "`nPublic events:"
$t.GetEvents() | Select-Object Name | Format-Table
