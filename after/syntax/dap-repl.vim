" The Dart adapter streams the running app's output into this buffer as plain
" text. flutter-tools' Dev Log used to colorize it; this restores the same cues
" now that the duplicate log pane is gone.
"
" This is .vim rather than .lua on purpose: Vim's syntax loader only sources
" syntax/<ft>.vim, so a .lua file here is silently ignored.

" Severity prefixes Flutter and the engine emit.
syntax match DiagnosticError /^\s*\%(E\/\|SEVERE\|FATAL\|\[ERROR\]\).*/
syntax match DiagnosticError /\c\<\%(exception\|error\|failed\|failure\)\>/
syntax match DiagnosticWarn  /^\s*\%(W\/\|WARNING\|\[WARN\]\).*/
syntax match DiagnosticWarn  /\c\<\%(warning\|deprecated\|outdated\)\>/
syntax match DiagnosticInfo  /^\s*\%(I\/flutter\|INFO\)/

" Bracketed tags like [IMPORTANT:...] or [GoRouter].
syntax match Special /\[[^]]\+\]/

" URLs, including the VM Service websocket.
syntax match Underlined /\<\%(https\?\|wss\?\):\/\/[^ ,;'"]\+/

" Numbers, durations and timings: 4.4s, 0.000077s, 200.
syntax match Number /\<\d\+\%(\.\d\+\)\?\%(ms\|s\)\?\>/

" Dart and Flutter source references.
syntax match Directory /\<\%(package\|dart\|file\):[^ )]\+/

" The repl's own prompt.
syntax match Title /^dap>/
