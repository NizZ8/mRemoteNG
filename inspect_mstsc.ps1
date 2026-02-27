$asm = [System.Reflection.Assembly]::LoadFrom('D:\github\mRemoteNG\mRemoteNG\bin\x64\Release\Interop.MSTSCLib.dll')
foreach ($t in $asm.GetTypes()) {
    $members = $t.GetMembers() | Where-Object { $_.Name -match 'Printer|printer|Redirect|redirect' }
    if ($members) {
        Write-Host "$($t.FullName): $($members.Name -join ', ')"
    }
}

Write-Host "`n=== AdvancedSettings members ==="
foreach ($t in $asm.GetTypes()) {
    if ($t.Name -match 'AdvancedSettings') {
        Write-Host "$($t.Name):"
        $t.GetMembers() | Where-Object { $_.MemberType -eq 'Property' } | ForEach-Object { Write-Host "  $($_.Name)" }
    }
}
