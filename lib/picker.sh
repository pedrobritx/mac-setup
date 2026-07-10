#!/usr/bin/env bash
#
# lib/picker.sh — interactive "tick what you want" selection screen.
#
# Sourced only by install.sh. Flow:
#
#   picker_available          — is there a terminal to draw on?
#   picker_catalog            — parse the Brewfile + setup steps into items
#   picker_run                — full-screen checklist (arrows/space/enter)
#   picker_confirm            — summary + final yes/no
#   picker_write_selection    — filtered "active" Brewfile + module skip list
#
# Everything reads/writes /dev/tty directly so it works when the script
# itself is piped (curl | bash). Written for bash 3.2 (macOS default): no
# associative arrays, no mapfile, integer read timeouts only.
#
# Catalog format — parallel arrays, one entry per selectable item:
#   PICK_TYPE   brew | cask | mas | step
#   PICK_ID     formula/cask token, mas id, or module name
#   PICK_LABEL  human name shown in the list
#   PICK_DESC   one-line explanation (from the Brewfile comment)
#   PICK_GROUP  section heading it appears under
#   PICK_ON     1 selected / 0 not
#   PICK_LOCK   1 = required, cannot be unticked (xcode, Homebrew)

if [[ -n "${_MAC_SETUP_PICKER_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_PICKER_LOADED=1

PICK_TYPE=()
PICK_ID=()
PICK_LABEL=()
PICK_DESC=()
PICK_GROUP=()
PICK_ON=()
PICK_LOCK=()

# Space-separated module names the user unticked; install.sh merges this
# into its --skip list.
PICKER_SKIPPED_MODULES=""

# Items the user unticked last run (so re-runs remember the choice while
# new Brewfile entries still default to ON).
_picker_unselected_file() { echo "${MAC_SETUP_STATE_DIR}/unselected.tsv"; }

# ---------------------------------------------------------------------------
# picker_available — a real terminal we can draw on and read keys from.
# ---------------------------------------------------------------------------
picker_available() {
  [[ -r /dev/tty && -w /dev/tty ]] || return 1
  # A terminal that can't report a size can't host a full-screen UI.
  local rows
  rows="$( (tput lines </dev/tty) 2>/dev/null || echo 0)"
  [[ "${rows}" -ge 15 ]]
}

# ---------------------------------------------------------------------------
# _picker_add <type> <id> <label> <desc> <group> <locked>
# ---------------------------------------------------------------------------
_picker_add() {
  local on=1
  # Previously unticked items stay unticked on re-runs (locked ones can't be).
  if [[ "$6" != "1" && -f "$(_picker_unselected_file)" ]] &&
    grep -qx "$1	$2" "$(_picker_unselected_file)" 2>/dev/null; then
    on=0
  fi
  PICK_TYPE+=("$1")
  PICK_ID+=("$2")
  PICK_LABEL+=("$3")
  PICK_DESC+=("$4")
  PICK_GROUP+=("$5")
  PICK_ON+=("${on}")
  PICK_LOCK+=("$6")
}

# ---------------------------------------------------------------------------
# picker_catalog — build the item list from the Brewfile, then append the
# setup steps. Brewfile section headers ("# 3. Casks — utilities") become
# group headings; the inline comment after each entry becomes its
# explanation.
# ---------------------------------------------------------------------------
picker_catalog() {
  PICK_TYPE=() PICK_ID=() PICK_LABEL=() PICK_DESC=() PICK_GROUP=()
  PICK_ON=() PICK_LOCK=()

  local line group="" id desc label
  while IFS= read -r line; do
    case "${line}" in
      "# "[0-9]". "*)
        # "# 2. Formulae — terminal environment" → "Formulae — terminal environment"
        group="${line#\# [0-9]. }"
        # Prefer the part after the em dash; trim trailing "(...)" notes.
        case "${group}" in
          *" — "*) group="${group#* — }" ;;
        esac
        group="${group%% (*}"
        ;;
      brew\ \"*)
        id="${line#brew \"}"
        id="${id%%\"*}"
        desc="$(_picker_comment "${line}")"
        _picker_add "brew" "${id}" "${id##*/}" "${desc}" "${group}" 0
        ;;
      cask\ \"*)
        id="${line#cask \"}"
        id="${id%%\"*}"
        desc="$(_picker_comment "${line}")"
        label="$(cask_app_name "${id}")"
        [[ -n "${label}" ]] || label="${id}"
        _picker_add "cask" "${id}" "${label}" "${desc}" "${group}" 0
        ;;
      mas\ \"*)
        label="${line#mas \"}"
        label="${label%%\"*}"
        id="${line#*id: }"
        id="${id%%[!0-9]*}"
        desc="$(_picker_comment "${line}")"
        _picker_add "mas" "${id}" "${label}" "${desc}" "${group}" 0
        ;;
    esac
  done <"${MAC_SETUP_ROOT}/Brewfile"

  # Setup steps — configuration modules the user can opt out of.
  local g="Setup steps"
  _picker_add step xcode "Xcode Command Line Tools" \
    "compilers & git — everything depends on this" "${g}" 1
  _picker_add step brew "Homebrew" \
    "the package manager that installs everything above" "${g}" 1
  _picker_add step directories "Folder layout" \
    "creates ~/Developer, ~/Screenshots, ~/Downloads/Installers" "${g}" 0
  _picker_add step ssh "SSH key" \
    "Ed25519 keypair for GitHub — never overwrites an existing key" "${g}" 0
  _picker_add step git "Git setup" \
    "your name/email, sensible defaults, commit signing, GitHub login" "${g}" 0
  _picker_add step terminal "Shell setup" \
    "zsh config + Starship prompt + plugins; existing dotfiles are backed up" "${g}" 0
  _picker_add step node "Node.js toolchain" \
    "Node LTS via fnm, plus pnpm and bun" "${g}" 0
  _picker_add step python "Python toolchain" \
    "Python via uv, plus pipx for CLI tools" "${g}" 0
  _picker_add step swift "Swift extras" \
    "SwiftFormat + SwiftLint checks" "${g}" 0
  _picker_add step vscode "VS Code config" \
    "settings, snippets, and extensions" "${g}" 0
  _picker_add step macos "macOS defaults" \
    "keyboard, tap-to-click, Finder tweaks — stock-first, no animation hacks" "${g}" 0
  _picker_add step security "Security" \
    "firewall on, Touch ID for sudo, immediate screen lock" "${g}" 0
}

# _picker_comment <line> — the text after " # ", or empty.
_picker_comment() {
  case "$1" in
    *" # "*) printf '%s' "${1#* # }" ;;
    *) printf '' ;;
  esac
}

# ---------------------------------------------------------------------------
# Selection queries
# ---------------------------------------------------------------------------

# picker_selected <type> <id> — 0 (true) when the item is ticked.
picker_selected() {
  local i
  for i in "${!PICK_TYPE[@]}"; do
    if [[ "${PICK_TYPE[i]}" == "$1" && "${PICK_ID[i]}" == "$2" ]]; then
      [[ "${PICK_ON[i]}" == "1" ]]
      return
    fi
  done
  return 0 # unknown items default to selected
}

_picker_count_on() {
  local i n=0
  for i in "${!PICK_ON[@]}"; do
    [[ "${PICK_ON[i]}" == "1" ]] && n=$((n + 1))
  done
  echo "${n}"
}

# ---------------------------------------------------------------------------
# Key reading — one keypress from /dev/tty, decoded to a symbolic name.
# Arrow keys arrive as ESC [ A/B; a lone ESC therefore waits 1s (bash 3.2
# only supports integer read timeouts).
# ---------------------------------------------------------------------------
_picker_key() {
  local k rest
  IFS= read -rsn1 k </dev/tty || {
    echo quit
    return
  }
  if [[ "${k}" == $'\033' ]]; then
    rest=""
    IFS= read -rsn2 -t 1 rest </dev/tty || true
    case "${rest}" in
      '[A' | 'OA') echo up ;;
      '[B' | 'OB') echo down ;;
      *) echo quit ;;
    esac
    return
  fi
  case "${k}" in
    "") echo enter ;;
    " ") echo space ;;
    j) echo down ;;
    k) echo up ;;
    a) echo group ;;
    q | Q) echo quit ;;
    *) echo none ;;
  esac
}

# ---------------------------------------------------------------------------
# picker_run — draw the checklist, loop on keys until enter (0) or quit (1).
# ---------------------------------------------------------------------------
picker_run() {
  local rows cols
  rows="$( (tput lines </dev/tty) 2>/dev/null || echo 24)"
  cols="$( (tput cols </dev/tty) 2>/dev/null || echo 80)"
  ((cols > 100)) && cols=100

  # Row map: "H<TAB>group" for headings, "I<TAB>index" for items.
  local rowmap=() last_group="" i
  for i in "${!PICK_TYPE[@]}"; do
    if [[ "${PICK_GROUP[i]}" != "${last_group}" ]]; then
      rowmap+=("H	${PICK_GROUP[i]}")
      last_group="${PICK_GROUP[i]}"
    fi
    rowmap+=("I	${i}")
  done

  # Cursor starts on the first item row.
  local cur=0 r
  for r in "${!rowmap[@]}"; do
    [[ "${rowmap[r]}" == I* ]] && {
      cur="${r}"
      break
    }
  done

  local header_lines=4 footer_lines=2
  local view=$((rows - header_lines - footer_lines))
  ((view < 5)) && view=5
  local top=0 flash="" rc=1

  # Alternate screen, hidden cursor; always restored on exit.
  printf '\033[?1049h\033[?25l' >/dev/tty
  trap 'printf "\033[?25h\033[?1049l" >/dev/tty' RETURN

  while true; do
    # Keep the cursor row inside the viewport.
    ((cur < top)) && top="${cur}"
    ((cur >= top + view)) && top=$((cur - view + 1))

    # ---- compose the frame ------------------------------------------------
    local frame="" idx kind payload line mark ptr
    frame+=$'\033[H'
    frame+="${C_BOLD}${C_MAGENTA}  mac-setup${C_RESET}${C_DIM} — tick what to install, untick what to skip${C_RESET}"$'\033[K\n'
    frame+="  ${C_DIM}↑/↓ move · space tick/untick · a toggles a whole group${C_RESET}"$'\033[K\n'
    frame+="  ${C_DIM}enter continue · q cancel${C_RESET}"$'\033[K\n'
    frame+=$'\033[K\n'

    local end=$((top + view))
    ((end > ${#rowmap[@]})) && end=${#rowmap[@]}
    for ((r = top; r < end; r++)); do
      kind="${rowmap[r]%%	*}"
      payload="${rowmap[r]#*	}"
      if [[ "${kind}" == "H" ]]; then
        frame+="  ${C_CYAN}${C_BOLD}${payload}${C_RESET}"$'\033[K\n'
        continue
      fi
      idx="${payload}"
      if [[ "${PICK_ON[idx]}" == "1" ]]; then
        mark="${C_GREEN}[✓]${C_RESET}"
      else
        mark="${C_DIM}[ ]${C_RESET}"
      fi
      [[ "${PICK_LOCK[idx]}" == "1" ]] && mark="${C_DIM}[✓]${C_RESET}"
      line="$(printf '%-24.24s' "${PICK_LABEL[idx]}")"
      local desc="${PICK_DESC[idx]}"
      local dmax=$((cols - 34))
      ((dmax < 0)) && dmax=0
      desc="${desc:0:dmax}"
      if [[ "${r}" -eq "${cur}" ]]; then
        ptr="${C_CYAN}❯${C_RESET}"
        frame+=" ${ptr} ${mark} ${C_BOLD}${line}${C_RESET} ${C_DIM}${desc}${C_RESET}"$'\033[K\n'
      else
        frame+="   ${mark} ${line} ${C_DIM}${desc}${C_RESET}"$'\033[K\n'
      fi
    done
    for ((r = end - top; r < view; r++)); do
      frame+=$'\033[K\n'
    done

    local on total
    on="$(_picker_count_on)"
    total="${#PICK_TYPE[@]}"
    frame+=$'\033[K\n'
    if [[ -n "${flash}" ]]; then
      frame+="  ${C_YELLOW}${flash}${C_RESET}"$'\033[K'
      flash=""
    else
      frame+="  ${C_BOLD}${on}${C_RESET} of ${total} selected ${C_DIM}· enter to review & confirm${C_RESET}"$'\033[K'
    fi
    frame+=$'\033[J'
    printf '%s' "${frame}" >/dev/tty

    # ---- handle one key ---------------------------------------------------
    case "$(_picker_key)" in
      up)
        r=$((cur - 1))
        while ((r >= 0)); do
          [[ "${rowmap[r]}" == I* ]] && {
            cur="${r}"
            break
          }
          r=$((r - 1))
        done
        ;;
      down)
        r=$((cur + 1))
        while ((r < ${#rowmap[@]})); do
          [[ "${rowmap[r]}" == I* ]] && {
            cur="${r}"
            break
          }
          r=$((r + 1))
        done
        ;;
      space)
        idx="${rowmap[cur]#*	}"
        if [[ "${PICK_LOCK[idx]}" == "1" ]]; then
          flash="'${PICK_LABEL[idx]}' is required — everything else depends on it."
        elif [[ "${PICK_ON[idx]}" == "1" ]]; then
          PICK_ON[idx]=0
        else
          PICK_ON[idx]=1
        fi
        ;;
      group)
        idx="${rowmap[cur]#*	}"
        local g="${PICK_GROUP[idx]}" any_off=0
        for i in "${!PICK_TYPE[@]}"; do
          [[ "${PICK_GROUP[i]}" == "${g}" && "${PICK_LOCK[i]}" != "1" &&
            "${PICK_ON[i]}" == "0" ]] && any_off=1
        done
        for i in "${!PICK_TYPE[@]}"; do
          if [[ "${PICK_GROUP[i]}" == "${g}" && "${PICK_LOCK[i]}" != "1" ]]; then
            PICK_ON[i]="${any_off}"
          fi
        done
        ;;
      enter)
        rc=0
        break
        ;;
      quit)
        rc=1
        break
        ;;
    esac
  done
  return "${rc}"
}

# ---------------------------------------------------------------------------
# picker_confirm — plain-screen summary of the selection + final yes/no.
# Returns 0 to proceed.
# ---------------------------------------------------------------------------
picker_confirm() {
  local i on total skipped=() group="" gsel=0 gtot=0 summary=""

  on="$(_picker_count_on)"
  total="${#PICK_TYPE[@]}"

  log_step "Your selection — ${on} of ${total} items"
  for i in "${!PICK_TYPE[@]}"; do
    if [[ "${PICK_GROUP[i]}" != "${group}" ]]; then
      [[ -n "${group}" ]] && printf '  %-38s %s\n' "${group}" "${gsel}/${gtot}"
      group="${PICK_GROUP[i]}" gsel=0 gtot=0
    fi
    gtot=$((gtot + 1))
    if [[ "${PICK_ON[i]}" == "1" ]]; then
      gsel=$((gsel + 1))
    else
      skipped+=("${PICK_LABEL[i]}")
    fi
  done
  [[ -n "${group}" ]] && printf '  %-38s %s\n' "${group}" "${gsel}/${gtot}"

  if [[ ${#skipped[@]} -gt 0 ]]; then
    summary="${skipped[*]}"
    printf '\n  %bSkipping:%b %s\n' "${C_DIM}" "${C_RESET}" "${summary}"
  fi

  printf '\n%bNext:%b everything ticked installs automatically. You may be asked\n' \
    "${C_BOLD}" "${C_RESET}"
  printf 'for your password (sudo) and App Store sign-in along the way.\n\n'

  local reply
  printf '%b?%b Install the %s selected items now? [y/N] ' \
    "${C_YELLOW}" "${C_RESET}" "${on}"
  IFS= read -r reply </dev/tty
  [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ---------------------------------------------------------------------------
# picker_write_selection <active_brewfile_path>
# Persist the choices:
#   * remembers unticked items for the next run,
#   * writes the filtered Brewfile the modules will install from,
#   * fills PICKER_SKIPPED_MODULES for install.sh.
# ---------------------------------------------------------------------------
picker_write_selection() {
  local active="$1" i line id

  # Remember what was unticked (not what was ticked) so brand-new Brewfile
  # entries still default to ON next time.
  local unsel
  unsel="$(_picker_unselected_file)"
  : >"${unsel}"
  for i in "${!PICK_TYPE[@]}"; do
    [[ "${PICK_ON[i]}" == "0" ]] &&
      printf '%s\t%s\n' "${PICK_TYPE[i]}" "${PICK_ID[i]}" >>"${unsel}"
  done

  # Filtered Brewfile: comments and taps pass through; entries only when
  # ticked. Structure is kept so the generated file stays readable.
  : >"${active}"
  while IFS= read -r line; do
    case "${line}" in
      brew\ \"*)
        id="${line#brew \"}"
        id="${id%%\"*}"
        picker_selected brew "${id}" || continue
        ;;
      cask\ \"*)
        id="${line#cask \"}"
        id="${id%%\"*}"
        picker_selected cask "${id}" || continue
        ;;
      mas\ \"*)
        id="${line#*id: }"
        id="${id%%[!0-9]*}"
        picker_selected mas "${id}" || continue
        ;;
    esac
    printf '%s\n' "${line}" >>"${active}"
  done <"${MAC_SETUP_ROOT}/Brewfile"

  PICKER_SKIPPED_MODULES=""
  for i in "${!PICK_TYPE[@]}"; do
    if [[ "${PICK_TYPE[i]}" == "step" && "${PICK_ON[i]}" == "0" ]]; then
      PICKER_SKIPPED_MODULES="${PICKER_SKIPPED_MODULES} ${PICK_ID[i]}"
    fi
  done
  PICKER_SKIPPED_MODULES="${PICKER_SKIPPED_MODULES# }"
}
