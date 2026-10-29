" Colours for the Flutter Output panel (pub get / upgrade / clean).
syntax match Title          /^\$ flutter .*/
syntax match DiagnosticOk   /^Finished .*/
syntax match DiagnosticError /^FAILED .*/
syntax match DiagnosticError /\c\<\%(error\|failed\|failure\|not found\|conflict\)\>/
syntax match DiagnosticWarn /\c\<\%(warning\|discontinued\|outdated\|newer versions\)\>/
syntax match Directory      /\<\%(package\|file\):[^ )]\+/
syntax match Underlined     /\<https\?:\/\/[^ ,;'"]\+/
syntax match Number         /\<\d\+\%(\.\d\+\)\+\>/
syntax match Comment        /(.\{-}s)$/
