# start-music.ps1 (UserPromptSubmit hook)
# Spotify's playlist-items endpoint is blocked for Development Mode apps
# (confirmed empirically, not a scope issue), so we can't read a playlist's
# tracks ourselves. Instead: enable shuffle, start playback of the playlist
# CONTEXT (Spotify itself picks a random track), read back whichever track
# it picked via currently-playing, seek that track to ~65% in (chorus/hook),
# then switch to single-track repeat so the whole song loops.
$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot/spotify-common.ps1"

$pluginRoot = Split-Path -Parent $PSScriptRoot
$stateFile = Join-Path ([System.IO.Path]::GetTempPath()) 'claude-spotify-state.json'
$playlistsPath = Join-Path $pluginRoot 'playlists.json'
$logPath = Join-Path $pluginRoot 'hook-debug.txt'

function Write-HookLog([string]$msg) {
    "$(Get-Date -Format o) [start] $msg" | Out-File $logPath -Append -Encoding utf8
}

$enabledFlag = Join-Path $pluginRoot 'enabled.flag'
if (-not (Test-Path $enabledFlag)) { exit 0 }

try {
    if (-not (Test-Path $playlistsPath)) { Write-HookLog "no playlists.json found"; exit 0 }
    $raw = Get-Content $playlistsPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { Write-HookLog "playlists.json empty"; exit 0 }
    $playlists = $raw | ConvertFrom-Json
    if ($playlists -isnot [System.Array]) { $playlists = @($playlists) }
    if ($playlists.Count -eq 0) { Write-HookLog "no playlists tracked yet"; exit 0 }

    $devices = Invoke-SpotifyApi -Path '/me/player/devices'
    if (-not $devices.devices -or $devices.devices.Count -eq 0) { Write-HookLog "no active Spotify device found"; exit 0 }
    $device = $devices.devices | Where-Object { $_.is_active } | Select-Object -First 1
    if (-not $device) { $device = $devices.devices | Select-Object -First 1 }

    $priorRepeat = 'off'
    $priorShuffle = $false
    try {
        $playback = Invoke-SpotifyApi -Path '/me/player'
        if ($playback -and $playback.repeat_state) { $priorRepeat = $playback.repeat_state }
        if ($playback) { $priorShuffle = [bool]$playback.shuffle_state }
    } catch {}

    $playlist = $playlists | Get-Random

    Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/shuffle' -QueryString "state=true&device_id=$($device.id)" | Out-Null
    Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/play' -QueryString "device_id=$($device.id)" -Body @{
        context_uri = "spotify:playlist:$($playlist.id)"
    } | Out-Null

    $current = $null
    for ($i = 0; $i -lt 6 -and -not $current; $i++) {
        Start-Sleep -Milliseconds 500
        $now = Invoke-SpotifyApi -Path '/me/player/currently-playing'
        if ($now -and $now.item) { $current = $now }
    }
    if (-not $current) { Write-HookLog "playback didn't report a track in time for playlist '$($playlist.name)'"; exit 0 }

    $track = $current.item
    $durationMs = [int]$track.duration_ms
    $startMs = [int]($durationMs * 0.65)

    Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/seek' -QueryString "position_ms=$startMs&device_id=$($device.id)" | Out-Null
    Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/shuffle' -QueryString "state=false&device_id=$($device.id)" | Out-Null
    Invoke-SpotifyApi -Method 'PUT' -Path '/me/player/repeat' -QueryString "state=track&device_id=$($device.id)" | Out-Null

    $state = [ordered]@{
        playlist     = $playlist.name
        track        = $track.name
        artist       = ($track.artists | Select-Object -First 1).name
        deviceId     = $device.id
        priorRepeat  = $priorRepeat
        priorShuffle = $priorShuffle
    }
    ($state | ConvertTo-Json) | Out-File $stateFile -Force -Encoding utf8
    Write-HookLog "playing '$($track.name)' by $(($track.artists | Select-Object -First 1).name) from playlist '$($playlist.name)' on device $($device.name)"
} catch {
    Write-HookLog "ERROR: $($_.Exception.Message)"
}
