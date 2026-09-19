---
description: Manage which Spotify playlists the swift-code hype-music plugin picks songs from. Use when the user asks to add/track a Spotify playlist, list their hype-music playlists, or remove/stop using a playlist.
---

# Playlist manager

This plugin loops a random song from the user's tracked Spotify playlists in the background while a prompt runs. Tracked playlists live in `${CLAUDE_PLUGIN_ROOT}/playlists.json`, managed via `${CLAUDE_PLUGIN_ROOT}/scripts/manage-playlists.ps1`.

**Add a playlist** (user gives a Spotify playlist URL, e.g. `https://open.spotify.com/playlist/...` or `spotify:playlist:...`):
```
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/manage-playlists.ps1" add "<url>"
```
Pass a third argument for a custom display name if the user gives one; otherwise the script pulls the real playlist name from Spotify.

**List tracked playlists:**
```
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/manage-playlists.ps1" list
```
Show the result to the user as a tree of name + URL.

**Remove a playlist** (match by name, id, or URL — whatever the user gave):
```
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/manage-playlists.ps1" remove "<name-or-url>"
```

Report the script's own output back to the user plainly. Don't claim success if it printed "No playlist matching" or an error — relay that instead.
