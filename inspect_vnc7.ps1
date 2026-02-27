$resp = gh api "repos/mRemoteNG/VncSharp/contents/VncSharp" 2>&1
$items = $resp | ConvertFrom-Json -ErrorAction SilentlyContinue
$items | ForEach-Object { Write-Output ($_.name + " " + $_.type) }
