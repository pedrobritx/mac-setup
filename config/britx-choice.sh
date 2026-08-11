#!/usr/bin/env bash
#
# config/britx-choice.sh — "Britx choice": your favourites, one key away.
#
# Applying this profile — press 'b' on the interactive selection screen, or
# run `./install.sh --britx` for a fully unattended install — ticks every
# app, terminal tool, setup step, and macOS/security preference in the
# catalog, then UNTICKS only what's listed below. Today that list is empty
# (the whole Brewfile is your favourites), so 'b'/--britx currently behaves
# like "select everything" — but as your taste changes, prune it here
# instead of touching lib/picker.sh or install.sh. This is the ONE file to
# edit for that, the same way config/settings.sh is the one file for
# identity/directories.
#
# Entry format, one per line: "<type>:<id>"
#   brew:<formula>            e.g. "brew:htop"
#   cask:<token>               e.g. "cask:steam"
#   mas:<id>                   e.g. "mas:424389933"   (Final Cut Pro)
#   step:<module>               e.g. "step:vscode"
#   pref:<module>:<category>   e.g. "pref:macos:safari"
#
# Find the exact <type>:<id> for anything by running `./install.sh --list`
# (setup steps) or reading the Brewfile (brew/cask/mas tokens) — the id is
# always what's between the quotes (or after "id:" for mas). Locked items
# (Xcode CLT, Homebrew) can't be excluded; they're required by everything
# else and stay ticked regardless.

if [[ -n "${_MAC_SETUP_BRITX_CHOICE_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_BRITX_CHOICE_LOADED=1

MAC_SETUP_BRITX_EXCLUDE=(
  # "cask:steam"          # skip the game library on this profile
  # "cask:stremio"        # skip the streaming hub
  # "mas:424389933"       # skip Final Cut Pro (paid)
  # "mas:424390742"       # skip Compressor (paid)
  # "pref:macos:safari"   # skip the Safari Develop menu tweak
)
export MAC_SETUP_BRITX_EXCLUDE
