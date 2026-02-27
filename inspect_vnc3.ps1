# Use ildasm or ilspycmd to inspect VncSharpCore
# First check available tools
$tools = @('ilspycmd', 'dotnet-ildasm', 'ildasm')
foreach ($tool in $tools) {
    $loc = Get-Command $tool -ErrorAction SilentlyContinue
    if ($loc) { Write-Host "Found: $tool at $($loc.Source)" }
}

# Try dotnet global tools
$globalTools = dotnet tool list -g 2>&1
Write-Host "Global dotnet tools:"
$globalTools
