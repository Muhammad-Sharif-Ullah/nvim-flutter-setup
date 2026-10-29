# Neovim for a Flutter developer coming from VS Code

`<leader>` is the **spacebar**. `<leader>Fr` means: press space, then capital F, then r.

Press space on its own and wait — a menu pops up showing what every next key does.
That menu (which-key) is the fastest way to explore; you never need to memorise this file.

---

## The big idea: modes

VS Code has one mode — you type and letters appear. Neovim has several.

| Mode | How you get there | What it is |
|---|---|---|
| **Normal** | `Esc` | The home base. Letters are *commands*, not text. You start here. |
| **Insert** | `i` | Typing text, like VS Code always is. `Esc` to leave. |
| **Visual** | `v` | Selecting text. |
| **Command** | `:` | Typing a command at the bottom, like `:w`. |

The status bar bottom-left always tells you which mode you're in.

**If you are ever lost, press `Esc` twice.** That returns you to Normal mode.

---

## Flutter

| What you want | Key | Command |
|---|---|---|
| Pick a device | `<leader>Fd` | `:FlutterDevices` |
| Pick an emulator | `<leader>Fe` | `:FlutterEmulators` |
| Run the app | `<leader>Fr` | `:FlutterRun` |
| Hot reload | `<leader>Fh` | `:FlutterReload` |
| Hot restart | `<leader>FR` | `:FlutterRestart` |
| Stop the app | `<leader>Fq` | `:FlutterQuit` |
| Widget tree | `<leader>Fo` | `:FlutterOutlineToggle` |
| Open DevTools | `<leader>FD` | `:FlutterDevTools` |
| `flutter pub get` | `<leader>Fp` | — |
| `flutter pub upgrade` | `<leader>FU` | — |
| `flutter clean` | `<leader>Fc` | — |
| Hide / show the output panel | `<leader>FO` | — |
| Restart the Dart analyser | `<leader>Fs` | `:FlutterLspRestart` |
| Toggle debug panels | `<leader>Fl` | — |

`<leader>Fp`, `<leader>FU` and `<leader>Fc` write into a **Flutter Output**
panel at the bottom instead of a popup, so you can scroll through all of it.
`<leader>FO` hides and reopens that panel (the output is kept, so reopening
shows the last run again). Jump into it with `<C-w>j`, scroll with `<C-d>` /
`<C-u>`, `G` jumps to the end.

**Hot reload runs automatically every time you save a `.dart` file.** You rarely need `<leader>Fh`.

Normal workflow: `<leader>Fd` to pick the device, `<leader>Fr` to run, then just edit and save.

Other commands that exist but have no key bound (type them with `:`):
`:FlutterDebug`, `:FlutterAttach`, `:FlutterDetach`, `:FlutterCommands` (a menu of everything),
`:FlutterVisualDebug`, `:FlutterToggleBrightness`, `:FlutterChangeTargetPlatform`,
`:FlutterCopyProfilerUrl`, `:FlutterInspectWidget`, `:FlutterPubUpgrade`, `:FlutterLogClear`,
`:FlutterRename`, `:FlutterReanalyze`, `:FlutterSuper`, `:FlutterFvm`.

---

## Wrapping and extracting widgets

Put the cursor anywhere on a widget, then:

| What you want | Key |
|---|---|
| Menu of every "Wrap with ..." | `<leader>Fww` |
| Wrap with Column | `<leader>Fwc` |
| Wrap with Row | `<leader>Fwr` |
| Wrap with Padding | `<leader>Fwp` |
| Wrap with Center | `<leader>Fwn` |
| Wrap with SizedBox | `<leader>Fws` |
| Wrap with Container | `<leader>FwC` |
| Wrap with Builder | `<leader>Fwb` |
| Remove this widget (unwrap) | `<leader>Fwd` |
| Extract Widget | `<leader>Fx` |
| Extract Method | `<leader>Fm` |
| Extract Local Variable | `<leader>Fv` |

`<leader>Fww` also offers "Wrap with widget...", which asks for any widget name.

These all work in Visual mode too — select the lines first.

They are LSP code actions, so `<leader>ca` still shows them alongside
Sort Members, Organize Imports and the quick fixes.

---

## DevTools and the widget inspector

The app must be running (`<leader>Fr`) for any of these to do anything.

| What you want | Key |
|---|---|
| Open DevTools in the browser | `<leader>Fib` |
| Start the DevTools server | `<leader>FD` |
| Inspect widget - tap one on the device | `<leader>Fii` |
| Copy the VM service URL | `<leader>Fiu` |
| Install or update DevTools | `<leader>FiI` |

Overlays drawn on the device itself:

| Overlay | Key |
|---|---|
| Debug paint (layout bounds) | `<leader>Fid` |
| Performance overlay (FPS graph) | `<leader>Fip` |
| Repaint rainbow | `<leader>Fir` |
| Slow animations | `<leader>Fis` |
| Text baselines | `<leader>Fil` |
| Light / dark mode | `<leader>Fit` |

The DevTools server starts automatically with your app, but the browser only
opens when you ask with `<leader>Fib`.

**Honest limitation:** DevTools opens in a browser, not inside Neovim. There is
no terminal equivalent of VS Code's embedded inspector panel. `<leader>Fo`
(widget tree) is the closest thing that stays in the editor.

---

## Debugging

| What you want | Key |
|---|---|
| Toggle a breakpoint | `<leader>db` |
| Start / continue | `<leader>dc` |
| Step over (next line) | `<leader>dO` |
| Step into (go inside the call) | `<leader>di` |
| Step out (finish this function) | `<leader>do` |
| Stop debugging | `<leader>dt` |
| Show / hide the sidebar | `<leader>dS` |
| Show / hide the console | `<leader>dC` |
| Show / hide both | `<leader>du` |

The sidebar (variables, call stack, breakpoints) is **empty while the app is running**.
It only fills in when execution *pauses* at a breakpoint.

---

## Terminal

| What you want | Key |
|---|---|
| Open / close terminal at the bottom | `<leader>tt` or `<C-/>` |
| Terminal in the project root | `<leader>ft` |
| Terminal in the current folder | `<leader>fT` |
| Leave the terminal (back to Normal mode) | `<Esc>` |

Inside the terminal you are typing into a real shell. To get back to editing, press `Esc`.

---

## The VS Code things you do without thinking

### Editing

| VS Code | Neovim |
|---|---|
| `Cmd+C` copy | `y` (with text selected in Visual mode) |
| Copy the current line | `yy` |
| `Cmd+X` cut | `d` (selected) — `dd` cuts the whole line |
| `Cmd+V` paste | `p` (after cursor) or `P` (before) |
| `Cmd+Z` undo | `u` |
| `Cmd+Shift+Z` redo | `<C-r>` |
| `Cmd+A` select all | `ggVG` |
| `Cmd+S` save | `:w` then Enter |
| `Cmd+D` select next occurrence | `*` jumps to the next one |
| `Cmd+/` toggle comment | `gcc` (one line), `gc` (selection) |
| `Tab` / `Shift+Tab` indent | `>>` / `<<`, or `>` / `<` on a selection |
| `Alt+Up/Down` move line | `<A-j>` / `<A-k>` |
| Duplicate a line | `yyp` |
| Delete a line | `dd` |

**Copying to the system clipboard** (to paste into Chrome, Slack, etc.): LazyVim shares
your system clipboard by default, so plain `y` and `p` already work across apps.

### Selecting

| VS Code | Neovim |
|---|---|
| Drag to select | `v` then move with `h j k l` or arrows |
| Select whole lines | `V` then move up/down |
| Column / box select | `<C-v>` |
| Select a word | `viw` |
| Select inside quotes | `vi"` |
| Select inside brackets | `vi(` or `vi{` |
| Select a whole function body | `vi{` with the cursor inside it |

### Moving around

| VS Code | Neovim |
|---|---|
| `Home` / `End` | `0` / `$` |
| `Cmd+Up` / `Cmd+Down` top & bottom | `gg` / `G` |
| `Cmd+G` go to line 42 | `:42` then Enter |
| Next/previous word | `w` / `b` |
| Scroll half a page | `<C-d>` / `<C-u>` |
| Back to where I just was | `<C-o>` (and `<C-i>` to go forward again) |

### Find and replace

| VS Code | Neovim |
|---|---|
| `Cmd+F` find in file | `/` then type, Enter. `n` = next, `N` = previous |
| `Cmd+Shift+F` find in project | `<leader>/` |
| `Cmd+H` replace in file | `:%s/old/new/g` then Enter |
| Replace with confirmation | `:%s/old/new/gc` |
| Replace across the project | `<leader>sr` |
| Clear the yellow search highlight | `<Esc>` |

### Files and navigation

| VS Code | Neovim |
|---|---|
| `Cmd+P` go to file | `<leader><space>` |
| `Cmd+Shift+E` explorer | `<leader>e` |
| `Cmd+B` hide the sidebar | `<leader>e` again |
| `Ctrl+Tab` switch file | `<leader>,` (open buffers) |
| Close the current file | `<leader>bd` |
| Recent files | `<leader>fr` |
| `Cmd+Shift+P` command palette | `<leader>sc` (or `:` for real commands) |

### Code intelligence (the Dart analyser)

| VS Code | Neovim |
|---|---|
| `F12` go to definition | `gd` |
| `Shift+F12` find references | `gr` |
| Hover for type info | `K` |
| `F2` rename symbol | `<leader>cr` |
| `Cmd+.` quick fix | `<leader>ca` |
| Format the file | `<leader>cf` |
| Next / previous error | `]d` / `[d` |
| List all problems | `<leader>xx` |
| Outline of this file | `<leader>cs` |

### Windows and splits

| VS Code | Neovim |
|---|---|
| Split right | `<leader>\|` |
| Split below | `<leader>-` |
| Move between splits | `<C-h>` `<C-j>` `<C-k>` `<C-l>` |
| Close this split | `<C-w>q` |
| Maximise this split | `<leader>wm` |

---

## Hiding and showing panels

Every panel has its own toggle.

| Panel | Toggle |
|---|---|
| File explorer | `<leader>e` |
| Terminal | `<leader>tt` |
| Flutter Output (pub get, clean) | `<leader>FO` |
| Widget tree | `<leader>Fo` |
| Debug sidebar (variables, stack) | `<leader>dS` |
| Debug console | `<leader>dC` |
| All debug panels at once | `<leader>du` or `<leader>Fl` |

From inside any panel, `<C-w>q` closes it, and `<C-w>j` / `<C-w>k` / `<C-w>h` /
`<C-w>l` move between it and your code.

`<leader>wm` zooms the current window to fill the screen, and again to restore
it -- the quickest way to get everything else out of the way.

---

## Snippets

Type the trigger in a `.dart` file and press `Tab`.

| Trigger | Gives you |
|---|---|
| `stless` | StatelessWidget |
| `stful` | StatefulWidget |
| `build` | `build` method |
| `initS` | `initState` |
| `disp` | `dispose` |
| `sets` | `setState` |
| `blocb` | BlocBuilder |
| `blocp` | BlocProvider |
| `blocl` | BlocListener |
| `lvb` | `ListView.builder` |
| `strb` | StreamBuilder |
| `futb` | FutureBuilder |

After expanding, `Tab` jumps to the next placeholder.

---

## Colors and themes

| What you want | How |
|---|---|
| Try themes with live preview | `<leader>uC` |
| Make a theme permanent | edit `lua/plugins/colorscheme.lua`, section 1 |
| Find what colors a piece of text | put the cursor on it, run `:Inspect` |
| Browse every highlight group | `:lua Snacks.picker.highlights()` |
| Change one syntax color | `on_highlights` in `colorscheme.lua`, section 2 |
| Install another theme | uncomment one in section 3 |

`<leader>uC` only lasts for the session. To keep a theme, put its name in
section 1 of `lua/plugins/colorscheme.lua`.

---

## Saving and quitting

| What | Command |
|---|---|
| Save | `:w` |
| Save and quit | `:wq` or `:x` |
| Quit | `:q` |
| Quit, throwing away changes | `:q!` |
| Quit everything | `:qa` |

---

## When something breaks

| Problem | Fix |
|---|---|
| Keys do nothing / strange things happen | Press `Esc` twice |
| `:FlutterRun` is "not an editor command" | You're not in a Flutter project — `cd` to the folder with `pubspec.yaml` |
| Autocomplete stopped working | `<leader>Fs` restarts the Dart analyser |
| A plugin looks broken | `:Lazy` to inspect, `:checkhealth` for a full report |
| I want to see every key that exists | Press space and wait |
| I want this cheatsheet again | `<leader>F?` |

---

## Learning Vim motions

Run `:Tutor` in Neovim. It is a 30-minute interactive lesson and it is genuinely the
fastest way to get comfortable. Do it once and most of this file becomes unnecessary.
