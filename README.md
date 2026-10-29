# Neovim for Flutter

A LazyVim setup for Flutter development that behaves like VS Code: run and
debug on a device, hot reload, widget inspector, DevTools, snippets, a
bottom terminal, and hover docs on mouse-over.

One command sets it up on a machine that has none of it.

## Install

```sh
git clone https://github.com/Muhammad-Sharif-Ullah/nvim-flutter-setup.git ~/nvim-flutter
bash ~/nvim-flutter/install.sh
```

Or, once pushed to GitHub, without cloning first:

```sh
CONFIG_REPO=https://github.com/Muhammad-Sharif-Ullah/nvim-flutter-setup.git \
  bash <(curl -fsSL https://raw.githubusercontent.com/Muhammad-Sharif-Ullah/nvim-flutter-setup/main/install.sh)
```

Works on **macOS** and **Linux** (apt, dnf, pacman, zypper, apk).
It takes a few minutes, most of it downloading plugins.

### Options

| Flag | What it does |
|---|---|
| `--dry-run` | Print every step without changing anything. Run this first if unsure. |
| `--no-flutter` | Don't install the Flutter SDK (you already have one). |
| `--uninstall` | Put your previous config back. |
| `--help` | Show usage. |

### What it installs

- **Neovim** 0.10+ (on Debian/Ubuntu, from the official tarball — the
  packaged version is too old)
- **git, curl, unzip, ripgrep, fd, lazygit, node, a C compiler** — what
  LazyVim's search, picker and treesitter need
- **tree-sitter CLI** — compiles the syntax parsers, including Dart's
- **JetBrainsMono Nerd Font** — the icons
- **Flutter SDK**, if absent (Homebrew cask on macOS, a stable clone to
  `~/development/flutter` on Linux, with PATH wired into your shell rc)
- This config, plus its ~40 plugins

Anything already present is left alone, so it is safe to run twice.

### It will not delete your setup

An existing `~/.config/nvim` is **moved** to `~/.config/nvim.backup-<timestamp>`,
along with the plugin, state and cache directories. Nothing is removed.
`bash install.sh --uninstall` moves the most recent backup back.

## After installing

1. **Set your terminal font to JetBrainsMono Nerd Font.** Without this the
   icons render as empty boxes. This is the single most common complaint and
   it is a terminal setting, not a Neovim one.
2. Open a **new terminal window** so PATH changes take effect.
3. Run `flutter doctor` and fix what it reports — that part is about
   Android Studio and Xcode, not about Neovim.
4. `cd` into a Flutter project and run `nvim .`

The first launch in a Dart project takes a few seconds while the Dart
analyser indexes. That is normal and only happens once per project.

## Terminal (Ghostty)

The colourscheme is transparent, so it leans on the terminal for the glass
look. [`ghostty/config`](ghostty/config) is the matching Ghostty setup:
Catppuccin Mocha, 82% opacity with blur, JetBrainsMono Nerd Font at 15pt.

Copy it to Ghostty's config path and restart Ghostty:

```sh
# macOS
mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
cp ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config

# Linux
mkdir -p ~/.config/ghostty
cp ghostty/config ~/.config/ghostty/config
```

Any other terminal works too — set the font to JetBrainsMono Nerd Font and,
if you want the same look, turn on background transparency. Without
transparency the Neovim theme still renders fine, just on the terminal's own
background.

## Using it

`<leader>` is the **spacebar**. Press it and wait — a menu appears showing
what every next key does. You never need to memorise anything.

| Key | Does |
|---|---|
| `<leader>F?` | **The cheatsheet** — every key, with the VS Code equivalent |
| `<leader>Fd` | Pick a device |
| `<leader>Fr` | Run the app |
| `<leader>Fh` / `<leader>FR` | Hot reload / hot restart |
| `<leader>Fii` | Widget inspector |
| `<leader><space>` | Find a file (`Cmd+P`) |
| `<leader>/` | Search the project (`Cmd+Shift+F`) |
| `gd` | Go to definition (`F12`), `<C-o>` to come back |
| `<leader>xx` | Problems panel |

Full reference: [`CHEATSHEET.md`](CHEATSHEET.md), or `<leader>F?` inside Neovim.

## Troubleshooting

**Icons are boxes or question marks.** Terminal font is not the Nerd Font.
See step 1 above.

**A key does nothing.** Keys register at startup. Quit with `:qa` and reopen.

**Flutter commands fail.** Check `flutter doctor` and that `which flutter`
finds the SDK. The config looks for it on PATH, then in `.fvm/flutter_sdk`,
`~/flutter`, `~/development/flutter` and the Homebrew prefixes.

**A plugin looks broken.** Run `:Lazy` to see status, `:checkhealth` for a
full diagnosis.

**Dart code is not coloured properly.** The parser failed to compile. Check
that `tree-sitter --version` works, then run `:TSInstall dart` inside Neovim.
