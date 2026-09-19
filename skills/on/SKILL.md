---
description: Turn on hype music for this Claude Code session (swift-code plugin) so a random song from a tracked playlist starts looping on every subsequent prompt until turned off or the session ends. Use when the user types /swift-code:on, or asks to turn on/activate/enable hype music.
---

Create an empty flag file at `${CLAUDE_PLUGIN_ROOT}/enabled.flag`, for example on Windows:

```
powershell -NoProfile -Command "New-Item -ItemType File -Force '${CLAUDE_PLUGIN_ROOT}/enabled.flag' | Out-Null"
```

Then tell the user hype music is now ON for this session: a random song will start on their next prompt, and every prompt after that, looping until they say `/swift-code:off` or the session ends.
