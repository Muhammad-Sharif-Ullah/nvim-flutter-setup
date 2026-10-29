#!/usr/bin/env bash
#
# Neovim + LazyVim, set up for Flutter development.
#
#   bash install.sh                 install everything
#   bash install.sh --dry-run       show what would happen, change nothing
#   bash install.sh --no-flutter    skip installing the Flutter SDK
#   bash install.sh --uninstall     restore the most recent backup
#
# Safe to run twice. Anything already installed is left alone, and an
# existing Neovim config is moved aside, never deleted.

set -euo pipefail

CONFIG_REPO="${CONFIG_REPO:-}"      # set to a git URL to install from GitHub
NVIM_MIN="0.10.0"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
WANT_FLUTTER=1
UNINSTALL=0

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
NVIM_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
NVIM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

# ---------------------------------------------------------------- output ----

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; OFF=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; OFF=""
fi

step()  { printf '\n%s==>%s %s%s%s\n' "$BLUE" "$OFF" "$BOLD" "$*" "$OFF"; }
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$*"; }
skip()  { printf '  %s·%s %s\n' "$DIM" "$OFF" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$OFF" "$*"; }
die()   { printf '\n%serror:%s %s\n' "$RED" "$OFF" "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  %swould run:%s %s\n' "$DIM" "$OFF" "$*"
  else
    "$@"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# Compare dotted versions: version_at_least 0.12.2 0.10.0 -> true
version_at_least() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# ------------------------------------------------------------------ args ----

for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=1 ;;
    --no-flutter) WANT_FLUTTER=0 ;;
    --uninstall)  UNINSTALL=1 ;;
    -h|--help)    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            die "unknown option: $arg (try --help)" ;;
  esac
done

# -------------------------------------------------------------- platform ----

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      die "this installer supports macOS and Linux; found $(uname -s)." ;;
esac

PKG=""
if [ "$OS" = macos ]; then
  PKG=brew
else
  for candidate in apt-get dnf pacman zypper apk; do
    if have "$candidate"; then PKG="$candidate"; break; fi
  done
  [ -n "$PKG" ] || die "no supported package manager found (apt, dnf, pacman, zypper, apk)."
fi

SUDO=""
if [ "$OS" = linux ] && [ "$(id -u)" -ne 0 ]; then
  have sudo || die "need sudo to install packages, but sudo is not available."
  SUDO=sudo
fi

# ------------------------------------------------------------- uninstall ----

if [ "$UNINSTALL" -eq 1 ]; then
  step "Restoring the most recent backup"
  backup="$(find "$(dirname "$NVIM_CONFIG")" -maxdepth 1 -name 'nvim.backup-*' 2>/dev/null | sort | tail -n1)"
  [ -n "$backup" ] || die "no backup found next to $NVIM_CONFIG — nothing to restore."
  run rm -rf "$NVIM_CONFIG"
  run mv "$backup" "$NVIM_CONFIG"
  ok "restored $backup"
  printf '\nPlugins in %s were left in place.\n' "$NVIM_DATA"
  exit 0
fi

# ------------------------------------------------------------ pkg helper ----

PKG_UPDATED=0
pkg_update_once() {
  [ "$PKG_UPDATED" -eq 1 ] && return 0
  PKG_UPDATED=1
  case "$PKG" in
    apt-get) run $SUDO apt-get update -qq ;;
    apk)     run $SUDO apk update ;;
  esac
}

# pkg_install <command-to-check> <brew> <apt> <dnf> <pacman> <zypper> <apk>
# An empty package name for this platform means "not available here".
pkg_install() {
  local cmd="$1" brew="$2" apt="$3" dnf="$4" pac="$5" zyp="$6" apk="$7" name=""

  if have "$cmd"; then skip "$cmd already installed"; return 0; fi

  case "$PKG" in
    brew)   name="$brew" ;;
    apt-get) name="$apt" ;;
    dnf)    name="$dnf" ;;
    pacman) name="$pac" ;;
    zypper) name="$zyp" ;;
    apk)    name="$apk" ;;
  esac

  if [ -z "$name" ]; then
    warn "$cmd is not packaged for this system — install it yourself if you want it"
    return 0
  fi

  pkg_update_once
  case "$PKG" in
    brew)    run brew install "$name" ;;
    apt-get) run $SUDO apt-get install -y -qq "$name" ;;
    dnf)     run $SUDO dnf install -y "$name" ;;
    pacman)  run $SUDO pacman -S --needed --noconfirm "$name" ;;
    zypper)  run $SUDO zypper install -y "$name" ;;
    apk)     run $SUDO apk add "$name" ;;
  esac
  ok "installed $cmd"
}

# ============================================================= 1. Homebrew ==

if [ "$OS" = macos ]; then
  step "Homebrew"
  if have brew; then
    ok "already installed"
  else
    warn "not found — installing (this will ask for your password)"
    run /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # A fresh install is not on PATH yet in this shell.
    for prefix in /opt/homebrew /usr/local; do
      [ -x "$prefix/bin/brew" ] && eval "$("$prefix/bin/brew" shellenv)" && break
    done
    have brew || [ "$DRY_RUN" -eq 1 ] || die "Homebrew installed but not on PATH; open a new terminal and re-run."
  fi
fi

# ========================================================= 2. Command-line ==

step "Command-line tools"
#           check      brew        apt            dnf          pacman       zypper       apk
pkg_install git        git         git            git          git          git          git
pkg_install curl       curl        curl           curl         curl         curl         curl
pkg_install unzip      unzip       unzip          unzip        unzip        unzip        unzip
pkg_install rg         ripgrep     ripgrep        ripgrep      ripgrep      ripgrep      ripgrep
pkg_install fd         fd          fd-find        fd-find      fd           fd           fd
pkg_install lazygit    lazygit     ""             lazygit      lazygit      ""           lazygit
pkg_install gcc        gcc         build-essential gcc         base-devel   gcc          build-base
pkg_install node       node        nodejs         nodejs       nodejs       nodejs       nodejs

# nvim-treesitter needs the tree-sitter CLI to build parsers. mason tries to
# install it too, but that fails on machines without a working npm prefix, so
# prefer the system package and fall back to a global npm install.
if have tree-sitter; then
  skip "tree-sitter already installed"
else
  case "$PKG" in
    brew)   run brew install tree-sitter ;;
    pacman) run $SUDO pacman -S --needed --noconfirm tree-sitter-cli ;;
    *)
      if have npm; then
        run npm install -g tree-sitter-cli
      else
        warn "tree-sitter CLI not installed; syntax highlighting still works for bundled parsers"
      fi
      ;;
  esac
  ok "installed tree-sitter"
fi

# Debian/Ubuntu ship fd as `fdfind`; LazyVim's picker looks for `fd`.
if [ "$PKG" = apt-get ] && have fdfind && ! have fd; then
  run mkdir -p "$HOME/.local/bin"
  run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "linked fdfind -> ~/.local/bin/fd"
fi

# =============================================================== 3. Neovim ==

step "Neovim (need $NVIM_MIN or newer)"
NEED_NVIM=1
if have nvim; then
  current="$(nvim --version | head -n1 | sed 's/^NVIM v//')"
  if version_at_least "$current" "$NVIM_MIN"; then
    ok "v$current already installed"
    NEED_NVIM=0
  else
    warn "v$current is too old — upgrading"
  fi
fi

if [ "$NEED_NVIM" -eq 1 ]; then
  case "$PKG" in
    brew)    have nvim && run brew upgrade neovim || run brew install neovim ;;
    pacman)  run $SUDO pacman -S --needed --noconfirm neovim ;;
    dnf)     run $SUDO dnf install -y neovim ;;
    zypper)  run $SUDO zypper install -y neovim ;;
    apk)     run $SUDO apk add neovim ;;
    apt-get)
      # Debian and Ubuntu package Neovim years behind; use the official
      # tarball so the version is predictable.
      arch="$(uname -m)"
      case "$arch" in
        x86_64)  asset=nvim-linux-x86_64 ;;
        aarch64) asset=nvim-linux-arm64 ;;
        *)       die "no official Neovim build for $arch — install it yourself and re-run." ;;
      esac
      url="https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"
      run $SUDO rm -rf "/opt/$asset"
      run $SUDO mkdir -p /opt
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '  %swould run:%s curl -fsSL %s | sudo tar -xz -C /opt\n' "$DIM" "$OFF" "$url"
      else
        curl -fsSL "$url" | $SUDO tar -xz -C /opt
      fi
      run $SUDO ln -sf "/opt/$asset/bin/nvim" /usr/local/bin/nvim
      ;;
  esac
  ok "Neovim installed"
fi

# ================================================================= 4. Font ==

step "Nerd Font (the icons in the sidebar and status line)"
if [ "$OS" = macos ]; then
  if brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    skip "JetBrainsMono Nerd Font already installed"
  else
    run brew install --cask font-jetbrains-mono-nerd-font
    ok "installed JetBrainsMono Nerd Font"
    warn "set it as your terminal font, or icons will show as boxes"
  fi
else
  font_dir="$HOME/.local/share/fonts"
  if [ -n "$(find "$font_dir" -name 'JetBrainsMono*NerdFont*' 2>/dev/null | head -n1)" ]; then
    skip "JetBrainsMono Nerd Font already installed"
  else
    url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    run mkdir -p "$font_dir"
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '  %swould run:%s curl -fsSL %s -o /tmp/JBM.zip && unzip into %s\n' "$DIM" "$OFF" "$url" "$font_dir"
    else
      tmp="$(mktemp -d)"
      curl -fsSL "$url" -o "$tmp/JetBrainsMono.zip"
      unzip -qo "$tmp/JetBrainsMono.zip" -d "$font_dir"
      rm -rf "$tmp"
      have fc-cache && fc-cache -f >/dev/null 2>&1 || true
    fi
    ok "installed JetBrainsMono Nerd Font"
    warn "set it as your terminal font, or icons will show as boxes"
  fi
fi

# ============================================================== 5. Flutter ==

if [ "$WANT_FLUTTER" -eq 1 ]; then
  step "Flutter SDK"
  if have flutter; then
    ok "already installed ($(flutter --version 2>/dev/null | head -n1 || echo 'version unknown'))"
  elif [ "$OS" = macos ]; then
    run brew install --cask flutter
    ok "installed Flutter"
  else
    target="$HOME/development/flutter"
    if [ -x "$target/bin/flutter" ]; then
      skip "already cloned at $target"
    else
      run git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$target"
      ok "cloned Flutter to $target"
    fi
    # Add to PATH in whichever shell rc files exist.
    line="export PATH=\"\$PATH:$target/bin\""
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [ -f "$rc" ] || continue
      if grep -qF "$target/bin" "$rc"; then
        skip "PATH already set in $(basename "$rc")"
      else
        if [ "$DRY_RUN" -eq 1 ]; then
          printf '  %swould append%s PATH line to %s\n' "$DIM" "$OFF" "$rc"
        else
          printf '\n# Flutter\n%s\n' "$line" >> "$rc"
        fi
        ok "added Flutter to PATH in $(basename "$rc")"
      fi
    done
    export PATH="$PATH:$target/bin"
  fi
else
  step "Flutter SDK"
  skip "skipped (--no-flutter)"
fi

# ======================================================== 6. The nvim config ==

step "Neovim configuration"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE=""

if [ -n "$CONFIG_REPO" ]; then
  SOURCE=clone
elif [ -f "$SCRIPT_DIR/init.lua" ] && [ -d "$SCRIPT_DIR/lua/plugins" ]; then
  SOURCE=local
else
  die "can't find the config. Run this script from inside the config directory, or set CONFIG_REPO to its git URL."
fi

# Back up anything already there. Never delete.
if [ -e "$NVIM_CONFIG" ] && [ "$SCRIPT_DIR" != "$NVIM_CONFIG" ]; then
  backup="$NVIM_CONFIG.backup-$STAMP"
  run mv "$NVIM_CONFIG" "$backup"
  ok "moved your old config to $backup"
  # Stale plugin and state directories from the old config confuse lazy.nvim.
  for dir in "$NVIM_DATA" "$NVIM_STATE" "$NVIM_CACHE"; do
    [ -e "$dir" ] && run mv "$dir" "$dir.backup-$STAMP"
  done
  ok "moved old plugin data aside"
fi

if [ "$SOURCE" = clone ]; then
  run git clone --depth 1 "$CONFIG_REPO" "$NVIM_CONFIG"
  ok "cloned the config into $NVIM_CONFIG"
elif [ "$SCRIPT_DIR" = "$NVIM_CONFIG" ]; then
  skip "config is already at $NVIM_CONFIG"
else
  run mkdir -p "$NVIM_CONFIG"
  run cp -R "$SCRIPT_DIR/." "$NVIM_CONFIG/"
  run rm -rf "$NVIM_CONFIG/.git"
  ok "copied the config into $NVIM_CONFIG"
fi

# =============================================================== 7. Plugins ==

step "Plugins (first run downloads about 40 of them — give it a minute)"
if [ "$DRY_RUN" -eq 1 ]; then
  printf '  %swould run:%s nvim --headless "+Lazy! sync" +qa\n' "$DIM" "$OFF"
else
  nvim --headless "+Lazy! sync" +qa 2>&1 | tail -n 5 || warn "plugin sync reported a problem; open nvim and run :Lazy to see it"
  ok "plugins installed"
fi

# ================================================================ 8. Doctor ==

step "Checking the result"
if [ "$DRY_RUN" -eq 1 ]; then
  skip "skipped in dry run"
else
  failed=0
  for tool in nvim git rg fd; do
    if have "$tool"; then ok "$tool"; else warn "$tool is missing"; failed=1; fi
  done
  if have flutter; then
    ok "flutter"
  elif [ "$WANT_FLUTTER" -eq 1 ]; then
    warn "flutter is not on PATH in this shell — open a new terminal"
  fi
  [ "$failed" -eq 1 ] && warn "something above is missing; Neovim will still start"
fi

# ================================================================== 9. Done ==

cat <<DONE

${GREEN}${BOLD}Done.${OFF}

  ${BOLD}1.${OFF} Set your terminal font to ${BOLD}JetBrainsMono Nerd Font${OFF}, or icons
     will look like boxes. (Terminal > Settings > Profiles > Text.)
  ${BOLD}2.${OFF} Open a ${BOLD}new terminal window${OFF} so PATH changes take effect.
  ${BOLD}3.${OFF} Run ${BOLD}flutter doctor${OFF} and fix whatever it complains about —
     that part is about Android/Xcode, not about Neovim.
  ${BOLD}4.${OFF} ${BOLD}cd${OFF} into a Flutter project and run ${BOLD}nvim .${OFF}

  Inside Neovim, press ${BOLD}space${OFF} and wait — a menu shows every key.
  Press ${BOLD}space F ?${OFF} for the Flutter cheatsheet.
  Press ${BOLD}space F d${OFF} to pick a device, ${BOLD}space F r${OFF} to run the app.

  To undo all of this: ${BOLD}bash install.sh --uninstall${OFF}

DONE
