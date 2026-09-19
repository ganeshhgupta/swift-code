# spotify-auth.ps1
# ONE-TIME SETUP. Run this yourself (not via Claude): `powershell -File .\scripts\spotify-auth.ps1`
# Opens your browser for Spotify login/consent, captures the redirect locally (PKCE, no client secret),
# and saves tokens.json next to this plugin.
$ErrorActionPreference = 'Stop'

$pluginRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $pluginRoot 'config.json'
$tokensPath = Join-Path $pluginRoot 'tokens.json'

if (-not (Test-Path $configPath)) {
    throw "config.json not found. Copy config.example.json to config.json and set your client_id first."
}
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$redirectUri = $config.redirect_uri
$scopes = 'user-modify-playback-state user-read-playback-state user-read-currently-playing playlist-read-private playlist-read-collaborative'

function New-CodeVerifier {
    $bytes = New-Object byte[] 64
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    ([Convert]::ToBase64String($bytes) -replace '\+', '-' -replace '/', '_' -replace '=', '')
}
function Get-CodeChallenge([string]$verifier) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($verifier))
    ([Convert]::ToBase64String($hash) -replace '\+', '-' -replace '/', '_' -replace '=', '')
}

$verifier = New-CodeVerifier
$challenge = Get-CodeChallenge $verifier

$authUrl = "https://accounts.spotify.com/authorize?" +
    "client_id=$($config.client_id)" +
    "&response_type=code" +
    "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
    "&code_challenge_method=S256" +
    "&code_challenge=$challenge" +
    "&scope=$([uri]::EscapeDataString($scopes))"

$prefix = $redirectUri.TrimEnd('/') + '/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Opening browser for Spotify login..."
# Start-Process opens a URL in the default browser on Windows, but not on
# macOS or Linux, where it tries to run the string as a program. $IsMacOS and
# $IsLinux are PowerShell 6+ automatics, so on Windows PowerShell 5.1 they are
# simply unset and this falls through to the original behaviour.
if ($IsMacOS)     { & '/usr/bin/open' $authUrl }
elseif ($IsLinux) { & 'xdg-open' $authUrl }
else              { Start-Process $authUrl }
if (-not $?) {
    Write-Host "Could not open a browser automatically. Open this URL yourself:"
    Write-Host $authUrl
}

Write-Host "Waiting for you to approve access in the browser..."
$context = $listener.GetContext()
$req = $context.Request
$code = $req.QueryString['code']
$errorParam = $req.QueryString['error']

$respHtml = if ($code) { "<html><body>Spotify auth complete. You can close this tab and return to the terminal.</body></html>" } else { "<html><body>Auth failed: $errorParam</body></html>" }
$buffer = [System.Text.Encoding]::UTF8.GetBytes($respHtml)
$context.Response.ContentLength64 = $buffer.Length
$context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
$context.Response.OutputStream.Close()
$listener.Stop()

if (-not $code) { throw "Spotify auth failed: $errorParam" }

$tokenBody = @{
    grant_type    = 'authorization_code'
    code          = $code
    redirect_uri  = $redirectUri
    client_id     = $config.client_id
    code_verifier = $verifier
}
$tokenResp = Invoke-RestMethod -Uri 'https://accounts.spotify.com/api/token' -Method Post -Body $tokenBody -ContentType 'application/x-www-form-urlencoded'

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$tokens = [ordered]@{
    access_token  = $tokenResp.access_token
    refresh_token = $tokenResp.refresh_token
    expires_at    = $now + $tokenResp.expires_in
}
($tokens | ConvertTo-Json) | Out-File $tokensPath -Force -Encoding utf8

Write-Host "Saved tokens to $tokensPath. Setup complete, the plugin hooks will use this from now on."
