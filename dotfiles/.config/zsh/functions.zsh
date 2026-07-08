# functions.zsh — small shell functions (managed by mac-setup).

# mkcd <dir> — create a directory and cd into it.
mkcd() {
  mkdir -p "$1" && cd "$1" || return
}

# extract <archive> — extract any common archive format.
extract() {
  if [[ ! -f "$1" ]]; then
    echo "extract: '$1' is not a file" >&2
    return 1
  fi
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz) tar xzf "$1" ;;
    *.tar.xz) tar xJf "$1" ;;
    *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;;
    *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.gz) gunzip "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.7z) 7z x "$1" ;;
    *.rar) unar "$1" ;;
    *) echo "extract: unknown archive format: $1" >&2; return 1 ;;
  esac
}

# killport <port> — kill whatever is listening on a TCP port.
killport() {
  local pid
  pid="$(lsof -ti tcp:"$1")"
  if [[ -z "${pid}" ]]; then
    echo "killport: nothing listening on port $1"
    return 1
  fi
  kill -9 ${=pid} && echo "killed process(es) on port $1"
}

# gclone <repo> — clone into ~/Developer and cd in. Accepts URLs or owner/repo.
gclone() {
  local url="$1" name
  [[ "${url}" != *"://"* && "${url}" != git@* ]] && url="git@github.com:${url}.git"
  name="$(basename "${url}" .git)"
  git clone "${url}" "${HOME}/Developer/${name}" && cd "${HOME}/Developer/${name}" || return
}

# up [n] — go up n directories (default 1).
up() {
  local levels="${1:-1}" path=""
  for _ in $(seq 1 "${levels}"); do path="../${path}"; done
  cd "${path}" || return
}

# weather [city] — quick forecast in the terminal.
weather() {
  curl -s "wttr.in/${1:-}?format=3"
}

# zshtime — measure shell startup time (10 runs).
zshtime() {
  for _ in $(seq 1 10); do
    time zsh -i -c exit
  done
}
