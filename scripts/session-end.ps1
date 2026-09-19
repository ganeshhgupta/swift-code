# session-end.ps1 (SessionEnd hook)
# Stops any currently looping song and turns hype music back OFF, so the
# next new Claude Code session starts deactivated and needs /swift-code:on again.
& "$PSScriptRoot/stop-music.ps1"
$pluginRoot = Split-Path -Parent $PSScriptRoot
Remove-Item (Join-Path $pluginRoot 'enabled.flag') -Force -ErrorAction SilentlyContinue
