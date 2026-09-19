# swift-code

A Claude Code plugin that plays music while Claude works.

Turn it on, and every time you send Claude Code a prompt, a random song from your Spotify playlists starts playing (right around the chorus, so you don't wait through a slow intro) and loops until Claude finishes responding. Then it stops. Ships with a Taylor Swift playlist by default, but you can point it at any playlist you like.

## What it actually does

- You type `/swift-code:on` once at the start of a session.
- From then on, every prompt you send kicks off a song, looping, in the background.
- The moment Claude finishes replying, the music stops.
- `/swift-code:off` turns it back off whenever you want.

Nothing plays until you turn it on, and it automatically resets to "off" when you close the session, so you're never surprised by music starting in a session you didn't mean to enable it in.

## Install it

Clone it straight into your Claude Code skills folder so it loads automatically, every session, with no flags:

```powershell
git clone https://github.com/ganeshhgupta/swift-code.git "$env:USERPROFILE\.claude\skills\swift-code"
```

That's the whole install. Claude Code picks up anything in `~/.claude/skills/` on startup — if you're already in a session, just start a new one.

## Connect it to your Spotify account

This plays music through the real Spotify app on your account, so it needs its own Spotify credentials. Takes about two minutes, and it's free.

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) and log in.
2. Click **Create app**. Name and description can be anything.
3. For **Redirect URI**, enter this exactly: `http://127.0.0.1:8888/callback`
4. Under "Which API/SDKs are you planning to use?", tick only **Web API**.
5. Save, then open the app and copy the **Client ID**.
6. Copy `config.example.json` to `config.json` in the plugin folder, and paste your Client ID in:

   ```json
   {
     "client_id": "paste-your-client-id-here",
     "redirect_uri": "http://127.0.0.1:8888/callback"
   }
   ```

7. Run the login script once. It opens your browser, asks you to approve access to your own account, and saves a token locally — nothing ever leaves your machine.

   ```powershell
   powershell -File "$env:USERPROFILE\.claude\skills\swift-code\scripts\spotify-auth.ps1"
   ```

That's it — the saved token refreshes itself automatically after this, so you won't need to log in again.

## Turn it on

Open Spotify somewhere — the desktop app, your phone, the web player, even a smart speaker, anywhere you're logged in — then in Claude Code type:

```
/swift-code:on
```

Send a prompt and the music should start. When you're done, either say:

```
/swift-code:off
```

or just close the session — it cleans up after itself either way.

## Add or remove playlists

It comes with one playlist tracked by default (Taylor Swift). To change what it pulls from, just ask in plain English — no command syntax to remember:

- **"add this playlist: https://open.spotify.com/playlist/..."**
- **"what playlists do you have?"**
- **"remove the Taylor Swift playlist"**

Claude handles the rest. Every prompt after that randomly picks a song from whatever's currently tracked.

## Good to know

- You need **Spotify Premium** — free accounts can't be controlled through Spotify's API, only viewed.
- `config.json` and `tokens.json` are gitignored on purpose. Never commit or share those; they're tied to your Spotify account.
- Songs start about 65% of the way through, which usually lands somewhere around the chorus or hook, and loop from there until Claude's done.
