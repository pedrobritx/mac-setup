#!/usr/bin/env bash
#
# scripts/ssh.sh — SSH key and configuration.
#
#   * Generates an Ed25519 key when none exists — NEVER overwrites keys.
#   * Configures ~/.ssh/config to use the macOS keychain.
#   * Loads the key into the agent.
#   * Guides GitHub authentication (gh auth login handles key upload).
#
# Key type/path are configurable in config/settings.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="ssh"

# ---------------------------------------------------------------------------
# generate_key — create an Ed25519 key if (and only if) none exists.
# ---------------------------------------------------------------------------
generate_key() {
  local key="${MAC_SETUP_SSH_KEY_FILE}"

  if [[ -f "${key}" ]]; then
    log_skip "SSH key exists (${key/#${HOME}/~}) — leaving it untouched."
    report_skip "${MODULE}" "SSH key" "existing key preserved"
    return 0
  fi

  local email="${MAC_SETUP_GIT_EMAIL}"
  if [[ -z "${email}" && -t 0 ]]; then
    printf 'Email for the SSH key comment: '
    read -r email
  fi

  log_info "Generating a new ${MAC_SETUP_SSH_KEY_TYPE} SSH key..."
  ensure_dir "${HOME}/.ssh"
  run chmod 700 "${HOME}/.ssh"
  if run ssh-keygen -t "${MAC_SETUP_SSH_KEY_TYPE}" -C "${email:-$(whoami)@$(hostname)}" \
    -f "${key}" -N ""; then
    log_success "SSH key generated at ${key/#${HOME}/~}"
    report_ok "${MODULE}" "SSH key" "generated ${MAC_SETUP_SSH_KEY_TYPE} key"
  else
    report_fail "${MODULE}" "SSH key" "ssh-keygen failed"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# configure_ssh — ensure ~/.ssh/config uses the agent + macOS keychain.
# Appends a managed block only when absent; user content is preserved.
# ---------------------------------------------------------------------------
configure_ssh() {
  local config="${HOME}/.ssh/config"
  local marker="# --- managed by mac-setup ---"

  if [[ -f "${config}" ]] && grep -qF "${marker}" "${config}"; then
    log_skip "~/.ssh/config already contains the mac-setup block."
    report_skip "${MODULE}" "ssh config" "managed block present"
    return 0
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "append managed Host block to ${config}"
    return 0
  fi

  ensure_dir "${HOME}/.ssh"
  {
    echo ""
    echo "${marker}"
    echo "Host *"
    echo "  AddKeysToAgent yes"
    echo "  UseKeychain yes"
    echo "  IdentityFile ${MAC_SETUP_SSH_KEY_FILE}"
    echo "# --- end managed by mac-setup ---"
  } >>"${config}"
  chmod 600 "${config}"
  log_success "Configured ~/.ssh/config (agent + keychain)."
  report_ok "${MODULE}" "ssh config" "managed block appended"
}

# ---------------------------------------------------------------------------
# load_key_into_agent — add the key to ssh-agent with keychain storage.
# ---------------------------------------------------------------------------
load_key_into_agent() {
  [[ -f "${MAC_SETUP_SSH_KEY_FILE}" || "${DRY_RUN}" == "1" ]] || return 0
  run ssh-add --apple-use-keychain "${MAC_SETUP_SSH_KEY_FILE}" 2>/dev/null ||
    log_debug "ssh-add skipped (agent unavailable or key already loaded)"
}

# ---------------------------------------------------------------------------
# guide_github_auth — check GitHub SSH connectivity; guide when missing.
# `gh auth login` (git module) is the automated path for uploading the key.
# ---------------------------------------------------------------------------
guide_github_auth() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "ssh -T git@github.com (connectivity check)"
    return 0
  fi

  local output
  output="$(ssh -T -o BatchMode=yes -o ConnectTimeout=5 git@github.com 2>&1 || true)"
  if grep -q "successfully authenticated" <<<"${output}"; then
    log_success "GitHub SSH authentication works."
    report_ok "${MODULE}" "GitHub SSH" "authenticated"
    return 0
  fi

  report_manual "${MODULE}" "GitHub SSH key" \
    "https://github.com/settings/keys" \
    "adding a key to a GitHub account requires browser authentication" \
    "Run 'gh auth login' (choose SSH — it uploads the key for you), or paste the contents of ${MAC_SETUP_SSH_KEY_FILE}.pub at github.com/settings/keys. Verify with: ssh -T git@github.com"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  generate_key
  configure_ssh
  load_key_into_agent
  guide_github_auth
}

main "$@"
