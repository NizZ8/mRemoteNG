try {
    $dll = 'D:\github\mRemoteNG\mRemoteNG\bin\x64\Release\Assemblies\VncSharpCore.dll'
    $bytes = [System.IO.File]::ReadAllBytes($dll)
    $a = [System.Reflection.Assembly]::Load($bytes)

    $types = $null
    try { $types = $a.GetTypes() }
    catch [System.Reflection.ReflectionTypeLoadException] {
        $types = $_.Exception.Types | Where-Object { $_ -ne $null }
    }

    $t = $types | Where-Object { $_ -ne $null -and $_.Name -eq 'RemoteDesktop' }
    if ($t) {
        Write-Host "Found RemoteDesktop type: $($t.FullName)"
        Write-Host "`nMethods:"
        $t.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance) |
            Where-Object { $_.Name -match 'Clipboard|Server|Fill|Connect|Event' } |
            Select-Object Name, @{N='Params';E={($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + ' ' + $_.Name }) -join ', '}} |
            Format-Table
        Write-Host "`nAll Events:"
        $t.GetEvents() | Select-Object Name | Format-Table
    } else {
        Write-Host "RemoteDesktop type not found. Available types:"
        $types | Where-Object { $_ -ne $null } | Select-Object Name | Format-Table
    }
} catch {
    Write-Host "Error: $_"
}
