# manage-playlists.ps1
# Usage:
#   manage-playlists.ps1 add <spotify-playlist-url> [display-name]
#   manage-playlists.ps1 list
#   manage-playlists.ps1 remove <name-or-id-or-url>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('add', 'list', 'remove')]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Target,

    [Parameter(Position = 2)]
    [string]$DisplayName
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\spotify-common.ps1"

$playlistsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'playlists.json'

function Get-TrackedPlaylists {
    if (-not (Test-Path $playlistsPath)) { return @() }
    $raw = Get-Content $playlistsPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $data = $raw | ConvertFrom-Json
    if ($null -eq $data) { return @() }
    if ($data -isnot [System.Array]) { return @($data) }
    return $data
}

function Save-TrackedPlaylists([array]$list) {
    # -InputObject (not pipeline) is required so a single-element array
    # still serializes as a JSON array instead of unwrapping to one object.
    (ConvertTo-Json -InputObject $list -Depth 5) | Out-File $playlistsPath -Force -Encoding utf8
}

function Get-PlaylistIdFromUrl([string]$url) {
    if ($url -match 'playlist[:/]([A-Za-z0-9]{22})') { return $Matches[1] }
    throw "Could not find a playlist ID in '$url'. Expected https://open.spotify.com/playlist/<id> or spotify:playlist:<id>."
}

switch ($Action) {
    'add' {
        if (-not $Target) { throw "Usage: manage-playlists.ps1 add <playlist-url> [display-name]" }
        $id = Get-PlaylistIdFromUrl $Target
        $list = Get-TrackedPlaylists
        $existing = $list | Where-Object { $_.id -eq $id }
        if ($existing) {
            Write-Host "Already tracked: $($existing.name)"
            break
        }
        $info = Invoke-SpotifyApi -Path "/playlists/$id" -QueryString 'fields=name'
        $name = if ($DisplayName) { $DisplayName } else { $info.name }
        $entry = [ordered]@{
            name = $name
            id   = $id
            url  = "https://open.spotify.com/playlist/$id"
        }
        $list = @($list) + $entry
        Save-TrackedPlaylists $list
        Write-Host "Added '$name' ($id)"
    }
    'list' {
        $list = Get-TrackedPlaylists
        if ($list.Count -eq 0) { Write-Host "No playlists tracked yet."; break }
        foreach ($p in $list) { Write-Host "- $($p.name)  [$($p.id)]  $($p.url)" }
    }
    'remove' {
        if (-not $Target) { throw "Usage: manage-playlists.ps1 remove <name-or-id-or-url>" }
        $list = Get-TrackedPlaylists
        $match = @($list | Where-Object { $_.name -eq $Target -or $_.id -eq $Target -or $_.url -eq $Target -or $_.name -like "*$Target*" })
        if ($match.Count -eq 0) { Write-Host "No playlist matching '$Target' found."; break }
        $remaining = @($list | Where-Object { $_ -notin $match })
        Save-TrackedPlaylists $remaining
        foreach ($m in $match) { Write-Host "Removed '$($m.name)'" }
    }
}
