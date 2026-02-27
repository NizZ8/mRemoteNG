try {
    $dll = 'D:\github\mRemoteNG\mRemoteNG\bin\x64\Release\Assemblies\VncSharpCore.dll'
    $bytes = [System.IO.File]::ReadAllBytes($dll)
    $a = [System.Reflection.Assembly]::Load($bytes)

    $types = $null
    try { $types = $a.GetTypes() }
    catch [System.Reflection.ReflectionTypeLoadException] {
        $types = $_.Exception.Types | Where-Object { $_ -ne $null }
    }

    Write-Host "All types in VncSharpCore:"
    $types | Where-Object { $_ -ne $null } | Select-Object FullName | Format-Table -AutoSize
} catch {
    Write-Host "Error: $_"
}
