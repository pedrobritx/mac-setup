# Post-Install Checklist

The automation gets you ~95% of the way. This is the remaining 5% — things
Apple and vendors gate behind interactive sign-ins or GUI-only flows.
Your personalized list is generated at
`~/.local/state/mac-setup/reports/manual-actions.md`.

## Accounts & sign-ins

- [ ] **App Store** — sign in, then `./install.sh --only mas` to pick up any
      apps that were skipped.
- [ ] **GitHub** — if not done during install: `gh auth login --git-protocol ssh --web`
      (uploads your SSH key automatically). Add the key as a **signing key**
      too: <https://github.com/settings/keys>.
- [ ] **iCloud** — System Settings → Apple ID (Drive, Photos, Find My).
- [ ] Sign in to: Notion, Obsidian (vault sync), Discord, WhatsApp, Teams,
      Google Drive, Figma, Steam, ChatGPT, Claude.

## Licensed / org software

- [ ] **Cisco Secure Client** — download from your organization's VPN portal
      (no public installer exists). Install the `.pkg`, add your VPN profile.
- [ ] **Final Cut Pro / Compressor** — must be *purchased* on your Apple ID
      before `mas` can install them; then `./install.sh --only mas`.
- [ ] **VMware Fusion** — sign in / register on first launch.
- [ ] **DaisyDisk** — enter license if you own the direct version.

## First-launch approvals (macOS security prompts)

- [ ] **Docker Desktop** — accept the service agreement, wait for
      "Engine running", then `./verify.sh` (runs `hello-world`).
- [ ] **Logi Options+** — grant Accessibility/Input Monitoring permissions.
- [ ] **Google Drive** — grant Finder integration when prompted.
- [ ] **OnyX** — grant Full Disk Access if you plan to use it.

## System decisions (deliberately not automated)

- [ ] **FileVault** — System Settings → Privacy & Security → FileVault →
      Turn On. Store the recovery key off-device (password manager).
- [ ] **Time Machine** — pick a backup disk.
- [ ] **Dock layout** — pin the apps you actually use (automation of Dock
      contents is destructive to personal muscle memory; we only set behavior).
- [ ] **Wallpaper** — anything in `assets/wallpapers/` you like.

## Terminal finishing touches

- [ ] Restart the terminal; confirm the Starship prompt renders (the Nerd
      Font glyphs need the terminal's font set to *JetBrainsMono Nerd Font*).
- [ ] `atuin register` / `atuin login` if you want history sync across machines.
- [ ] Terminal.app/iTerm2: set font to JetBrainsMono Nerd Font 13pt.

## Sanity check

```bash
cd ~/Developer/mac-setup && ./verify.sh
```

Everything green? You're done. Anything red tells you which module to re-run.
