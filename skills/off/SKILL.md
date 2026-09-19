---
description: Turn off hype music for this Claude Code session (swift-code plugin), stopping any currently looping song immediately and preventing it from starting again this session. Use when the user types /swift-code:off, or asks to turn off/deactivate/stop hype music.
---

Run this to stop whatever's currently playing right now:

```
powershell -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/stop-music.ps1"
```

Then delete the flag file so it doesn't restart on the next prompt:

```
powershell -NoProfile -Command "Remove-Item -Force '${CLAUDE_PLUGIN_ROOT}/enabled.flag' -ErrorAction SilentlyContinue"
```

Confirm to the user that hype music is now OFF for this session.
