param(
    [switch]$SelfContained,
    [switch]$Portable,     # Self-contained + PORTABLE flag (settings in app folder, embeds .NET runtime)
    [switch]$Rebuild,
    [switch]$NoRestore,    # Skip dotnet restore (use for fast incremental builds)
    [string]$Configuration = "Release",
    [ValidateSet("x64", "x86", "ARM64")]
    [string]$Arch = "x64"
)

# Map arch to MSBuild Platform and .NET RuntimeIdentifier
$platform = $Arch
$rid = switch ($Arch) {
    "x64"   { "win-x64" }
    "x86"   { "win-x86" }
    "ARM64" { "win-arm64" }
}

# Find the newest VS BuildTools installation (VS2026 > VS2022 > etc.)
$vsBasePaths = @(
    "C:\Program Files\Microsoft Visual Studio",
    "C:\Program Files (x86)\Microsoft Visual Studio"
)

$devShell = $null
foreach ($base in $vsBasePaths) {
    if (Test-Path $base) {
        $versions = Get-ChildItem $base -Directory | Sort-Object Name -Descending
        foreach ($ver in $versions) {
            $editions = @("Enterprise", "Professional", "Community", "BuildTools")
            foreach ($ed in $editions) {
                $candidate = Join-Path $ver.FullName "$ed\Common7\Tools\Launch-VsDevShell.ps1"
                if (Test-Path $candidate) {
                    $devShell = $candidate
                    break
                }
            }
            if ($devShell) { break }
        }
    }
    if ($devShell) { break }
}

if (-not $devShell) {
    throw "No Visual Studio installation found. Install VS2026 or VS2022 BuildTools."
}

Write-Host "Using: $devShell"
& $devShell -Arch amd64

$sln = "$PSScriptRoot\mRemoteNG.sln"
$timer = [System.Diagnostics.Stopwatch]::StartNew()

if ($Portable) {
    Write-Host "Building portable edition ($Arch, self-contained + PORTABLE flag)..."
    if (-not $NoRestore) {
        dotnet restore $sln --runtime $rid
    }
    # PublishReadyToRun=false avoids NETSDK1094 crossgen2 issue; startup impact is negligible.
    msbuild $sln -m "-verbosity:minimal" "-p:Configuration=Release" "-p:Platform=$platform" "-p:DefineConstants=PORTABLE" "-p:SelfContained=true" "-p:RuntimeIdentifier=$rid" "-p:PublishReadyToRun=false" "-p:SignAssembly=false" "-p:PublishDir=bin\$platform\Portable\" -t:Publish
    Write-Host "Portable output: mRemoteNG\bin\$platform\Portable\" -ForegroundColor Green
} elseif ($SelfContained) {
    Write-Host "Building self-contained $Arch (embedded .NET runtime)..."
    if (-not $NoRestore) {
        dotnet restore $sln --runtime $rid /p:PublishReadyToRun=true
    }
    msbuild $sln -m "-verbosity:minimal" "-p:Configuration=Release" "-p:Platform=$platform" "-p:SelfContained=true" "-p:RuntimeIdentifier=$rid" "-p:PublishReadyToRun=false" "-p:PublishDir=bin\$platform\Release\publish\" -t:Publish
} else {
    Write-Host "Building framework-dependent $Arch..."
    if (-not $NoRestore) {
        dotnet restore $sln
    }
    $msbuildArgs = @('-m', '-verbosity:minimal', "-p:Configuration=$Configuration", "-p:Platform=$platform", '-p:SignAssembly=false')
    if ($Rebuild) { $msbuildArgs += '-t:Rebuild' }
    if ($NoRestore) { $msbuildArgs += '-p:RestorePackages=false' }
    msbuild $sln @msbuildArgs
}

$timer.Stop()
Write-Host "Build completed in $($timer.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Cyan
