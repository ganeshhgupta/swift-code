# stop-music.ps1 (Stop / SessionEnd hook)
# Pauses playback and restores whatever repeat/shuffle state the user had before start-music.ps1 ran.
$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot\spotify-common.ps1"

$pluginRoot = Split-Path -Parent $PSScriptRoot
$stateFile = Join-Path $env:TEMP 'claude-spotify-state.json'
$logPath = Join-Path $pluginRoot 'hook-debug.txt'

function Write-HookLog([string]$msg) {
    "$(Get-Date -Format o) [stop] $msg" | Out-File $logPath -Append -Encoding utf8
}

$deviceId = $null
$priorRepeat = 'off'
$priorShuffle = $false
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $deviceId = $state.deviceId
    if ($state.priorRepeat) { $priorRepeat = $state.priorRepeat }
    if ($null -ne $state.priorShuffle) { $priorShuffle = [bool]$state.priorShuffle }
} else {
    Write-HookLog "no state file - start-music.ps1 didn't leave anything playing, nothing to stop"
}

try {
    if ($deviceId) {
        $shuffleStr = if ($priorShuffle) { 'true' } else { 'false' }
        Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/pause' -QueryString "device_id=$deviceId" | Out-Null
        Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/repeat' -QueryString "state=$priorRepeat&device_id=$deviceId" | Out-Null
        Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/shuffle' -QueryString "state=$shuffleStr&device_id=$deviceId" | Out-Null
        Write-HookLog "paused device $deviceId, restored repeat=$priorRepeat shuffle=$priorShuffle"
    }
} catch {
    Write-HookLog "ERROR: $($_.Exception.Message)"
}

Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
