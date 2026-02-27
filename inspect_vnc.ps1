$dll = 'C:\Users\robert.popa\.nuget\packages\vncsharpcore\1.2.1\lib\net6.0-windows7.0\VncSharpCore.dll'
$asm = [System.Reflection.Assembly]::LoadFile($dll)
Write-Host "Assembly loaded: $($asm.FullName)"
Write-Host "Types:"
$asm.GetTypes() | ForEach-Object { $_.FullName }
