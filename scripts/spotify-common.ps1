# spotify-common.ps1
# Dot-sourced helper: token refresh + a thin Spotify Web API wrapper.
$Script:PluginRoot = Split-Path -Parent $PSScriptRoot
$Script:ConfigPath = Join-Path $PluginRoot 'config.json'
$Script:TokensPath = Join-Path $PluginRoot 'tokens.json'

function Get-SpotifyConfig {
    if (-not (Test-Path $Script:ConfigPath)) { throw "config.json missing. Copy config.example.json to config.json and fill in client_id." }
    Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
}

function Get-SpotifyAccessToken {
    if (-not (Test-Path $Script:TokensPath)) { throw "tokens.json missing. Run scripts\spotify-auth.ps1 once to log in." }
    $tokens = Get-Content $Script:TokensPath -Raw | ConvertFrom-Json
    $config = Get-SpotifyConfig

    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($tokens.expires_at -gt ($now + 60)) {
        return $tokens.access_token
    }

    $body = @{
        grant_type    = 'refresh_token'
        refresh_token = $tokens.refresh_token
        client_id     = $config.client_id
    }
    $resp = Invoke-RestMethod -Uri 'https://accounts.spotify.com/api/token' -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'

    $newTokens = [ordered]@{
        access_token  = $resp.access_token
        refresh_token = if ($resp.refresh_token) { $resp.refresh_token } else { $tokens.refresh_token }
        expires_at    = $now + $resp.expires_in
    }
    ($newTokens | ConvertTo-Json) | Out-File $Script:TokensPath -Force -Encoding utf8

    return $newTokens.access_token
}

function Invoke-SpotifyApi {
    param(
        [string]$Method = 'GET',
        [string]$Path,
        [hashtable]$Body = $null,
        [string]$QueryString = $null
    )
    $token = Get-SpotifyAccessToken
    $uri = "https://api.spotify.com/v1$Path"
    if ($QueryString) { $uri += "?$QueryString" }
    $headers = @{ Authorization = "Bearer $token" }
    try {
        if ($Body) {
            return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body ($Body | ConvertTo-Json -Depth 5) -ContentType 'application/json'
        } else {
            return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
    } catch {
        # PUT/POST endpoints like play/pause/seek return 204 No Content, which
        # some PS5.1 builds raise as a non-terminating parse error. Ignore those.
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 204) { return $null }
        throw
    }
}
