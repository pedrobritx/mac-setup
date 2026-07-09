# Troubleshooting

First moves for any problem:

1. **Re-run it.** `./install.sh` is idempotent; transient failures (network,
   App Store hiccups) usually clear on a second pass.
2. **Read the log.** `ls -t ~/.local/state/mac-setup/logs/ | head -1` — every
   command and error is recorded there.
3. **Isolate the module.** `./install.sh --only <module> --verbose`.
4. **Preview before poking.** `./install.sh --only <module> --dry-run`.

---

## Homebrew

**`brew: command not found` right after install**
The shell hasn't loaded Homebrew's environment yet. Run
`eval "$(/opt/homebrew/bin/brew shellenv)"` (Intel: `/usr/local/bin/brew`)
or just open a new terminal — `.zprofile` handles it permanently.

**`brew bundle` fails on one cask**
Run `brew install --cask <name>` alone to see the real error. Typical causes:
the cask needs a password (privileged installer), the app is already in
`/Applications` from a manual install (`brew install --cask --force <name>`
adopts it), or the cask was renamed — check <https://formulae.brew.sh>.

**Cask SHA mismatch / download failure**
Vendor updated the artifact before the cask caught up. `brew update` and
retry; if it persists, wait a day — never bypass the checksum.

## Mac App Store (mas)

**Every `mas install` fails**
You're not signed in. Sign in via the App Store *app* (mas cannot do it
programmatically on modern macOS), then `./install.sh --only mas`.

**`mas install` fails for one paid app (Final Cut Pro, Compressor…)**
The app must be purchased/redeemed on your Apple ID first. Buy it once in
the App Store UI; from then on automation works.

## Xcode

**CLT dialog never appears / install hangs**
Run `softwareupdate --list` to see if a "Command Line Tools" entry exists,
then `softwareupdate -i "<label>"`. Worst case: download from
<https://developer.apple.com/download/all/>.

**`xcodebuild: error: license`**
`sudo xcodebuild -license accept` (the xcode module does this, but it needs
sudo).

## Docker

**`docker: command not found` after install**
Docker Desktop is installed but deliberately never auto-launched (an idle
daemon costs battery and RAM). Open Docker Desktop once, accept the
subscription agreement, and it will symlink the CLI. Keep "Start Docker
Desktop when you sign in" off.

**Image pulls fail on a corporate network**
Registry access may be proxied/blocked. Configure proxies in Docker Desktop
→ Settings → Resources → Proxies.

## Terminal

**Prompt shows boxes/question marks**
Your terminal font isn't the Nerd Font. Set it to *JetBrainsMono Nerd Font*
in Terminal/iTerm2 preferences.

**Shell startup feels slow**
Measure: `time zsh -i -c exit` (target < 150 ms). The usual culprit is a
stale completion dump — `rm ~/.zcompdump*` and open a new shell.

**`compinit: insecure directories` warning**
`chmod go-w "$(brew --prefix)/share"` — a known Homebrew permissions quirk.

## Dotfiles

**"Where did my old .zshrc go?"**
It was backed up, never deleted:
`ls ~/.local/state/mac-setup/backups/<run-id>/`. Restore any file by copying
it back (or run `./uninstall.sh`, which restores automatically).

**I edited ~/.zshrc and my edits vanished after re-running install**
`~/.zshrc` is a symlink into the repo — edit
`~/Developer/mac-setup/dotfiles/.zshrc` instead (same file), and commit it.

## macOS defaults

**A setting didn't take effect**
Some keyboard/trackpad settings need logout/login. Others need the target
app restarted — the macos module restarts Finder/Dock automatically but only
when something changed.

**Mission Control / full-screen / window animations feel glitchy**
Almost always caused by leftover `defaults` overrides (from old setup
scripts or "speed up your Mac" guides). Run `./install.sh --only macos` —
it deletes every known window-management and animation override and
restores stock behavior. Log out and back in afterwards.

**Safari settings fail to apply**
Sandboxed Safari preferences may require Full Disk Access for your terminal:
System Settings → Privacy & Security → Full Disk Access → add Terminal.

## SSH / Git

**`Permission denied (publickey)` with GitHub**
The key isn't on your account. `gh auth login --git-protocol ssh --web`
uploads it, or paste `~/.ssh/id_ed25519.pub` at
<https://github.com/settings/keys>. Test: `ssh -T git@github.com`.

**Commit signing errors (`gpg failed to sign`)**
Run `./install.sh --only ssh,git` — the signing config depends on the SSH
key existing. To disable: set `MAC_SETUP_GIT_SSH_SIGNING=0` in
`config/settings.sh` and re-run the git module.

## Still stuck?

Open an issue with the failing module, the relevant log excerpt, and
`sw_vers` output. The logs contain no secrets — but skim before pasting.
