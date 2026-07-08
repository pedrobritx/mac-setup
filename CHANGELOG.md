# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-07-08

### Added

- Initial release: full Infrastructure-as-Code macOS bootstrap.
- `bootstrap.sh` — curl-able zero-to-workstation entry point.
- `install.sh` — module orchestrator with `--dry-run`, `--verbose`,
  `--only`, `--skip`, `--list`.
- Shared library (`lib/`) — logging, dry-run execution wrapper, idempotency
  checks, backups, symlink manifest, report rendering.
- `Brewfile` — single source of truth for taps, formulae, casks, fonts, and
  Mac App Store apps.
- 20 modules under `scripts/` covering Xcode, Homebrew, apps, MAS, fonts,
  git, SSH, terminal, Node (fnm), Python (uv), Swift, Docker, VS Code,
  macOS/Finder/Dock defaults, security, directories, downloads, and
  verification.
- Version-controlled dotfiles (zsh, Starship, git, VS Code) linked with
  automatic backups of pre-existing files.
- `update.sh`, `cleanup.sh`, `verify.sh`, `uninstall.sh` maintenance
  commands.
- Markdown reports: install report, verification report, manual-actions
  report; plain-text logs per run.
- Documentation: README, INSTALL, POST_INSTALL, TROUBLESHOOTING,
  ARCHITECTURE, CONTRIBUTING.
- CI: ShellCheck + shfmt + bash syntax check + dry-run smoke test.
