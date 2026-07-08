#!/usr/bin/env bash
#
# scripts/git.sh — Git identity, defaults, LFS, signing, GitHub auth.
#
#   * Links the shared git config (aliases, sensible defaults) from
#     dotfiles/.config/git/ — machine-independent settings live there.
#   * Writes identity + signing into ~/.config/git/local (generated,
#     git-ignored by the dotfiles) so no personal data is hardcoded twice.
#   * Enables SSH commit signing with the key from scripts/ssh.sh.
#   * Installs Git LFS hooks.
#   * Guides GitHub CLI authentication.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="git"
readonly GIT_LOCAL_CONFIG="${HOME}/.config/git/local"

# ---------------------------------------------------------------------------
# link_git_config — symlink the shared config and global ignore file.
# ---------------------------------------------------------------------------
link_git_config() {
  link_file "${MAC_SETUP_DOTFILES_DIR}/.config/git/config" \
    "${HOME}/.config/git/config"
  link_file "${MAC_SETUP_DOTFILES_DIR}/.config/git/ignore" \
    "${HOME}/.config/git/ignore"
  report_ok "${MODULE}" "git config" "shared config + global ignore linked"
}

# ---------------------------------------------------------------------------
# set_local <key> <value> — idempotently set a key in the generated local
# config file (identity, signing — anything machine/person specific).
# ---------------------------------------------------------------------------
set_local() {
  local key="$1" value="$2" current
  current="$(git config --file "${GIT_LOCAL_CONFIG}" --get "${key}" 2>/dev/null || true)"
  if [[ "${current}" == "${value}" ]]; then
    log_debug "git ${key} already '${value}'"
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "git config --file ${GIT_LOCAL_CONFIG} ${key} '${value}'"
    return 0
  fi
  mkdir -p "$(dirname "${GIT_LOCAL_CONFIG}")"
  git config --file "${GIT_LOCAL_CONFIG}" "${key}" "${value}"
  log_success "git ${key} = ${value}"
}

# ---------------------------------------------------------------------------
# configure_identity — user.name / user.email, prompting when unset.
# ---------------------------------------------------------------------------
configure_identity() {
  local name="${MAC_SETUP_GIT_NAME}" email="${MAC_SETUP_GIT_EMAIL}"

  if [[ -z "${name}" && -t 0 ]]; then
    printf 'Git user.name: '
    read -r name
  fi
  if [[ -z "${email}" && -t 0 ]]; then
    printf 'Git user.email: '
    read -r email
  fi

  if [[ -z "${name}" || -z "${email}" ]]; then
    report_manual "${MODULE}" "Git identity" \
      "https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup" \
      "no identity configured and no TTY to prompt" \
      "Set MAC_SETUP_GIT_NAME/MAC_SETUP_GIT_EMAIL in config/settings.sh and re-run: ./install.sh --only git"
    return 0
  fi

  set_local user.name "${name}"
  set_local user.email "${email}"
  report_ok "${MODULE}" "identity" "${name} <${email}>"
}

# ---------------------------------------------------------------------------
# configure_defaults — default branch and credential helper (per-machine,
# so they live in the local file rather than the shared dotfile).
# ---------------------------------------------------------------------------
configure_defaults() {
  set_local init.defaultBranch "${MAC_SETUP_GIT_DEFAULT_BRANCH}"
  set_local credential.helper "osxkeychain"
  report_ok "${MODULE}" "defaults" "default branch '${MAC_SETUP_GIT_DEFAULT_BRANCH}', osxkeychain helper"
}

# ---------------------------------------------------------------------------
# configure_ssh_signing — sign commits/tags with the SSH key.
# ---------------------------------------------------------------------------
configure_ssh_signing() {
  if [[ "${MAC_SETUP_GIT_SSH_SIGNING}" != "1" ]]; then
    log_skip "SSH commit signing disabled in settings."
    report_skip "${MODULE}" "SSH signing" "disabled in config/settings.sh"
    return 0
  fi

  local pubkey="${MAC_SETUP_SSH_KEY_FILE}.pub"
  if [[ ! -f "${pubkey}" && "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "SSH signing" "public key missing (${pubkey}); run the ssh module first"
    return 0
  fi

  set_local gpg.format "ssh"
  set_local user.signingkey "${pubkey}"
  set_local commit.gpgsign "true"
  set_local tag.gpgsign "true"

  # Allowed-signers file lets `git log --show-signature` verify locally.
  local signers="${HOME}/.config/git/allowed_signers"
  if [[ "${DRY_RUN}" != "1" && -f "${pubkey}" ]]; then
    local entry
    entry="${MAC_SETUP_GIT_EMAIL} $(cut -d' ' -f1,2 "${pubkey}")"
    if [[ ! -f "${signers}" ]] || ! grep -qF "${entry}" "${signers}"; then
      mkdir -p "$(dirname "${signers}")"
      echo "${entry}" >>"${signers}"
    fi
  fi
  set_local gpg.ssh.allowedSignersFile "${signers}"

  log_success "SSH commit signing configured."
  report_ok "${MODULE}" "SSH signing" "signing with ${pubkey/#${HOME}/~}"
  log_info "Add the key as a *signing key* on GitHub too: https://github.com/settings/keys"
}

# ---------------------------------------------------------------------------
# configure_lfs — install Git LFS hooks globally.
# ---------------------------------------------------------------------------
configure_lfs() {
  if ! has_command git-lfs && [[ "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "Git LFS" "git-lfs not installed — run the brew module first"
    return 0
  fi

  if git config --global --get filter.lfs.required >/dev/null 2>&1; then
    log_skip "Git LFS already initialized."
    report_skip "${MODULE}" "Git LFS" "already initialized"
    return 0
  fi

  if run git lfs install --skip-repo; then
    report_ok "${MODULE}" "Git LFS" "hooks installed"
  else
    report_fail "${MODULE}" "Git LFS" "git lfs install failed"
  fi
}

# ---------------------------------------------------------------------------
# configure_github_auth — GitHub CLI authentication status / guidance.
# gh auth login is interactive (browser), so it cannot be fully automated.
# ---------------------------------------------------------------------------
configure_github_auth() {
  if ! has_command gh && [[ "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "GitHub CLI" "gh not installed — run the brew module first"
    return 0
  fi

  if [[ "${DRY_RUN}" != "1" ]] && gh auth status >/dev/null 2>&1; then
    log_success "GitHub CLI already authenticated."
    report_skip "${MODULE}" "GitHub auth" "already authenticated"
    return 0
  fi

  if [[ -t 0 && "${DRY_RUN}" != "1" ]]; then
    log_info "Launching GitHub authentication (browser flow)..."
    if gh auth login --hostname github.com --git-protocol ssh --web; then
      report_ok "${MODULE}" "GitHub auth" "authenticated via gh"
      return 0
    fi
  fi

  report_manual "${MODULE}" "GitHub authentication" \
    "https://cli.github.com/manual/gh_auth_login" \
    "requires an interactive browser session" \
    "Run: gh auth login --git-protocol ssh --web (uploads your SSH key too)"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  link_git_config
  configure_identity
  configure_defaults
  configure_ssh_signing
  configure_lfs
  configure_github_auth
}

main "$@"
