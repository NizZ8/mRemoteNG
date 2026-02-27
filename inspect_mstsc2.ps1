$asm = [System.Reflection.Assembly]::LoadFrom('D:\github\mRemoteNG\mRemoteNG\bin\x64\Release\Interop.MSTSCLib.dll')

# Show properties of AdvancedSettings5 through 8
foreach ($version in 5..8) {
    $typeName = "MSTSCLib.IMsRdpClientAdvancedSettings$version"
    $t = $asm.GetType($typeName)
    if ($t) {
        Write-Host "=== $typeName ==="
        $t.GetProperties() | ForEach-Object { Write-Host "  $($_.Name): $($_.PropertyType.Name)" }
    }
}

Write-Host ""
Write-Host "=== IMsRdpClientNonScriptable5 ==="
$t = $asm.GetType('MSTSCLib.IMsRdpClientNonScriptable5')
if ($t) {
    $t.GetMembers() | Where-Object { $_.MemberType -ne 'Method' -or -not $_.Name.StartsWith('get_') -and -not $_.Name.StartsWith('set_') } | ForEach-Object { Write-Host "  $($_.MemberType): $($_.Name)" }
}

Write-Host ""
Write-Host "=== IMsRdpExtendedSettings ==="
$t = $asm.GetType('MSTSCLib.IMsRdpExtendedSettings')
if ($t) {
    $t.GetMembers() | ForEach-Object { Write-Host "  $($_.MemberType): $($_.Name)" }
}
