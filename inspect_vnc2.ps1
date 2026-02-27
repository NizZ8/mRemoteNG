# Extract VncSharpCore nupkg to look at source
$nupkg = 'C:\Users\robert.popa\.nuget\packages\vncsharpcore\1.2.1\vncsharpcore.1.2.1.nupkg'
$dest = 'C:\Temp\vnc_pkg_extract'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Path $dest | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($nupkg, $dest)
Get-ChildItem $dest -Recurse | Select-Object FullName
