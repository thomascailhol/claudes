# claudes

Run **multiple isolated Claude Desktop instances** on macOS — each with its own
account, skills, and MCP config — side by side, with **no logout/login**.

<p align="center"><img src="assets/examples/dock.png" width="512" alt="Four Claude instances with color-coded Dock icons"></p>

> **Unofficial.** `claudes` is an independent community tool, not affiliated with
> or endorsed by Anthropic. Claude and the Claude logo are trademarks of
> Anthropic, PBC.

Each instance is a cloned `Claude.app` with:

- its own **bundle identifier** (so macOS treats it as a distinct app in the Dock,
  Spotlight, and Notification Center),
- its own **color-coded Dock icon** (white Claude star on a colored squircle) so
  you can tell instances apart at a glance,
- its own **`--user-data-dir`**, so accounts, skills, and MCP servers stay fully
  separate.

Clones are **self-healing** against Claude's auto-update, which periodically
overwrites the cloned bundle and breaks the isolation — `doctor` detects that and
`repair` (or `doctor --fix`) restores it.

## Why this exists

I'm a freelance developer, and I work with several companies at once. Sometimes
I use my own Claude account, but scoped to that client's tools: their Linear,
their database, their MCP connectors, and nobody else's. Sometimes the client
puts me on their own Claude Team plan, so it's a different account altogether.
And then there are my own projects, like [The Buoy](https://thebuoy.app), which
need their own little environment too.

Claude Desktop only does one account at a time, so switching contexts meant
logging out, logging back in, re-authorizing connectors, and hoping nothing
leaked from one client into another.

So I started cloning the app by hand: a new bundle ID, a separate data dir, an
ad-hoc re-sign. It worked until the next Claude auto-update quietly overwrote the
clone and broke the isolation. `claudes` is that hack turned into a tool. It
makes the clones, repairs them after updates, and keeps them on the current
version.

The colored icons came next. With five identical orange stars in the Dock, I kept
typing into the wrong client's workspace. Each instance gets its own color now,
and for The Buoy I wanted the icon in the app's own colors, which is where the
two-tone star came from.

**Need a hand with your product?** I'm available for freelance work:
[get in touch on LinkedIn](https://www.linkedin.com/in/thomascailhol/).

## Requirements

- macOS (Apple Silicon or Intel)
- Claude Desktop installed at `/Applications/Claude.app`
- Standard command-line tools: `ditto`, `plutil`, `codesign`, `xattr`, `file`
  (all ship with macOS / Xcode Command Line Tools)

## Install

### Homebrew (recommended)

```bash
brew install thomascailhol/tap/claudes
```

Handles PATH, updates (`brew upgrade`), and pulls in `librsvg` for crisp icons.

### From source

```bash
git clone https://github.com/thomascailhol/claudes.git
cd claudes
chmod +x claudes

# Optional: symlink it onto your PATH so you can run it as `claudes` anywhere
./claudes install                 # → ~/.local/bin/claudes (best-practice default)
./claudes install cc              # ...or pick your own command name
./claudes install --dir /opt/homebrew/bin   # ...or a specific dir
```

After installing you can drop the `./` and just run:

```bash
claudes add work
claudes list
claudes rename lacap "La Capitainerie"
```

`install` symlinks the script (so `git pull` updates stay live) into `~/.local/bin`
by default; if that's not on your PATH it prints the one line to add. Use `--dir`
for another location. `uninstall [name]` removes the symlink (only if it points
back to this script). The rest of this README writes `./claudes`, but once
installed `claudes` works the same everywhere.

## Usage

```bash
./claudes update <name>... | --all [--force] [--no-backup]
./claudes add <name> [--from <instance>|original] [--color <hex>] [--logo-color <spec>] [--no-icon] [--disable-gpu]
./claudes icon <name> [--color <hex>] [--logo-color <spec>]
./claudes repair <name> [--disable-gpu]
./claudes rename <old> <new>
./claudes transfer <from>|original <to>
./claudes routines <instance>|original
./claudes remove <name> [--keep-data] [-y]
./claudes list
./claudes doctor [--fix]
./claudes help
```

### Create an instance

```bash
./claudes add work
./claudes add client-x
```

This clones the app to `/Applications/Claude work.app` with data in
`~/Library/Application Support/Claude-work`. Launch it like any app (Spotlight:
“Claude work”). Re-running `add` on an existing instance is a safe no-op that
also re-applies isolation (idempotent).

**Multi-word names** are fine — just quote them so the shell passes them as one
argument:

```bash
./claudes add "La Capitainerie"
./claudes rename lacap "La Capitainerie"
```

Seed a new instance's **local preferences + MCP config** from another (never
tokens, and see the note below on what is *not* local):

```bash
./claudes add work --from original      # copy from the default install
./claudes add staging --from work       # copy from another clone
```

Already created the instance? Transfer the same local config afterward:

```bash
./claudes transfer original "La Capitainerie"   # <from> <to>
./claudes transfer work staging
```

> **What actually transfers.** Only `claude_desktop_config.json` is copied — UI
> preferences plus any *local (stdio) MCP servers*. **Skills, routines
> (scheduled tasks) and account MCP connectors are not local files — they live
> on your Claude account (server-side).** The way to "transfer" those is to sign
> the target instance into the **same account**; then it already has them. There
> is nothing on disk to copy for a *different* account. `config.json` (which
> holds auth tokens) is never copied.

### Color-coded icons

Every instance gets a distinct Dock icon by default: the white Claude star on a
colored squircle. Without `--color`, a stable color is chosen from a built-in
palette based on the name; pass `--color` to set your own:

```bash
./claudes add work --color '#059669'   # green
./claudes icon client-x --color '#0891B2'   # recolor an existing instance
./claudes add scratch --no-icon         # keep the stock Claude icon
```

#### Match your brand

Working on a project with its own brand? Color the star too. `--logo-color`
takes a single hex, or a two-tone split `TOP/BOTTOM[:PCT[:ANGLE]]` — `TOP` covers
the top `PCT`% of the star (default 50), with the dividing line tilted `ANGLE`
degrees (default 0).

<img src="assets/examples/the-buoy.png" width="128" align="right" alt="The Buoy instance icon: a purple and yellow star on black">

This is the instance for [The Buoy](https://thebuoy.app) — the reason the
feature exists:

```bash
./claudes add "The Buoy" --color '#000000' --logo-color '#6B55F6/#FFF869:40:12'
```

A single color works too: `--logo-color '#FFF869'`. Names can include accents
(`"Équipe"`); the bundle id is transliterated (`…claudefordesktop.equipe`).

The chosen color is stored in the instance's data dir, so `repair` / `doctor
--fix` **regenerate the icon automatically** after an auto-update wipes the
bundle. The Claude star glyph is **embedded in the script** (no external file
needed); drop an `assets/claude-logo.svg` next to the script to override it. Icon
generation needs an SVG rasterizer (`rsvg-convert`, ImageMagick, or macOS's
built-in `qlmanage`); if none is available the icon step is skipped and isolation
still works.

### After Claude auto-updates (the important part)

An auto-update can overwrite a clone's bundle and break isolation. Check and fix:

```bash
./claudes doctor        # report health of every instance
./claudes doctor --fix  # auto-repair any broken instances
# or repair one:
./claudes repair work
```

### Bring clones up to the original's version

Clones don't reliably auto-update (their ad-hoc signature isn't Anthropic's), so
they fall behind `/Applications/Claude.app`. `list` marks outdated ones with `*`
and `doctor` names them. Update them — quit them first:

```bash
./claudes update "La Capitainerie"   # one (or several) instances
./claudes update --all               # every outdated instance (running ones are skipped)
```

The data dir (login, local sessions, routines, connector tokens, color) is never
touched: the new bundle is cloned, isolated and signed in a staging dir, then
swapped in. Before the swap, the data dir is snapshotted and the old bundle
moved to `~/Library/Application Support/claudes-backups/<name>/<timestamp>/`
(the old bundle is renamed `.app.old` so macOS ignores it); `update` prints a
one-line rollback. `--no-backup` skips the data snapshot, `--force` re-clones
even when versions match. On first launch, click **Always Allow** on the
keychain prompt.

### List / rename / remove

```bash
./claudes list
./claudes rename work client           # rename an instance (quit it first)
./claudes remove client-x              # deletes bundle + data (asks first)
./claudes remove client-x --keep-data
```

`rename` moves the bundle **and** its data dir, then rebuilds the wrapper, bundle
id, display name, and icon — your color and settings carry over. It refuses if
the target name already exists or the instance is still running. If the old app
was pinned in the Dock, remove the broken item and re-add the renamed app.

## Same account vs separate accounts

You can sign into **different accounts** per instance, or the **same account** in
several instances — both work. Each instance has its own `--user-data-dir` and
therefore its own independent session, so Claude treats them like any other
concurrent sessions (web + desktop + mobile). Signing into one does not log you
out of another.

What's local to each instance vs bound to the account:

| Local to each instance (in the data dir) | Bound to the account (server-side) |
| --- | --- |
| UI preferences (`claude_desktop_config.json`) | **Skills** (sync down on login) |
| Local (stdio) MCP servers, if you use any | Conversation history |
| **Local routines** + their connector auth (encrypted) | Account settings / subscription |
| Caches, window state, the session token itself | Usage / rate limits |

*(MCP **connectors** are authorized per-instance — each instance runs its own
OAuth and stores the token encrypted locally — but the underlying access is your
account's. Skills sync down from the account on login.)*

The practical upshot: **skills and connectors follow the account** — sign an
instance in and they sync down automatically, at any scale. **Local routines are
the exception: they're per-instance.**

### Local routines are per-instance (and that's by design)

A "local routine" (a scheduled task marked as local in the app) runs on your machine
from the instance that created it, and it depends on that instance's **connector
auth** (e.g. a specific Linear workspace). Both the routine's schedule and the
connector token are stored **encrypted with that instance's Safe Storage keychain
key** — and every clone is ad-hoc signed with a *different* key, so that encrypted
state cannot be decrypted (or copied) into another instance. That's the same
mechanism that makes the instances isolated in the first place.

So routines can't be transferred by file copy. The clean model is **author in
place**: in the instance connected to a given workspace, connect the connector
once, then create that workspace's routines there. To move routines from another
instance, list them and recreate them:

```bash
./claudes routines original          # print each routine's title, working dir, prompt
# then recreate them as new routines in the target instance,
# and delete/pause them in the source so they don't run twice.
```

`routines` is read-only and can't export the *schedule* (that's in the encrypted
store) — re-enter the timing when you recreate each one.

> ⚠️ Still sign in **one instance at a time** (see the OAuth note below), whether
> the accounts are the same or different.

## First-launch notes

- **Keychain prompt.** On first launch each instance shows *“Claude Safe Storage
  wants to access the keychain.”* This is expected — the clone has a new local
  (ad-hoc) signature. Click **Always Allow**.
- **Black screen?** A known Electron GPU-rendering quirk on cloned bundles. Fix:
  ```bash
  ./claudes repair <name> --disable-gpu
  ```
- **⚠️ OAuth: one instance at a time.** When signing in (the `claude://` link) or
  connecting an OAuth MCP connector (e.g. Linear), do it on **one instance at a
  time**. Two concurrent logins can deliver the token to the wrong instance.

## How it works

For an instance `<name>`, `add` performs:

1. `ditto /Applications/Claude.app "/Applications/Claude <name>.app"`
2. `plutil -replace CFBundleIdentifier` → `com.anthropic.claudefordesktop.<slug>`
   (and a distinct `CFBundleDisplayName`)
3. Rename the real binary `Contents/MacOS/Claude` → `Claude Bin`, and put a small
   wrapper in its place that execs it with
   `--user-data-dir="$HOME/Library/Application Support/Claude-<name>"`
4. Render the colored `.icns`, install it, and drop `CFBundleIconName` so the
   custom icon wins over the bundle's asset-catalog icon
5. `xattr -cr` (clear quarantine), then `codesign --force --deep --sign -`
   (ad-hoc re-sign — **mandatory**, or macOS silently kills the process)

`repair` re-applies steps 2–5, auto-detecting the case where an update restored
the original single-binary layout.

## Safety

This tool modifies app bundles under `/Applications` and re-signs them ad-hoc, so
it's worth knowing what it does before you run it:

- `remove` refuses to touch the original `/Applications/Claude.app` or
  `~/Library/Application Support/Claude`.
- The tool makes **no network calls** and never copies session cookies or tokens.
- It's a single, readable script with **no hard dependencies** — everything it
  uses (`ditto`, `plutil`, `codesign`, `xattr`, `iconutil`, `qlmanage`…) ships
  with macOS. `librsvg`/ImageMagick are optional, only for nicer icons.
- Read it first. There is deliberately **no `curl | bash` installer**.

## Releasing (maintainers)

1. Bump `VERSION` in `claudes`, commit, then `git tag vX.Y.Z && git push --tags`
   and `gh release create vX.Y.Z`.
2. `curl -sL https://github.com/thomascailhol/claudes/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256`
   and update `url` + `sha256` in [`Formula/claudes.rb`](Formula/claudes.rb).
3. Copy the formula to [`thomascailhol/homebrew-tap`](https://github.com/thomascailhol/homebrew-tap)
   (`Formula/claudes.rb`) and push — `brew upgrade claudes` picks it up.

CI runs `shellcheck` on every push (`.github/workflows/shellcheck.yml`).

## License

MIT — see [LICENSE](LICENSE).
