$resp = & gh api "repos/mRemoteNG/VncSharp/contents/VncSharp" 2>&1
$items = $resp | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($items) {
    $items | ForEach-Object { Write-Output ($_.name + " " + $_.type) }
} else {
    Write-Output "Raw response:"
    Write-Output $resp
}
