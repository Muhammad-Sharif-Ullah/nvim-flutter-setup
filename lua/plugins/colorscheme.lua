return {
  -- 1. WHICH THEME IS ACTIVE
  -- Change the name below, save, restart. tokyonight and catppuccin are
  -- already installed; for anything else add its plugin first (see section 3).
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- 2. THEME SETTINGS
  -- Each theme has its own options. tokyonight ships four variants:
  -- "storm" (default), "night" (darker), "moon", and "day" (light).
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "storm",
      -- Stop painting a background, so the terminal's own transparency shows
      -- through. Needs background-opacity set in ~/.config/ghostty/config too.
      transparent = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
        -- The file explorer and floating windows keep their own background
        -- unless told otherwise, which looks like opaque panels on glass.
        sidebars = "transparent",
        floats = "transparent",
      },
      -- Change individual colors of the theme itself.
      on_colors = function(colors)
        -- Default #565f89 is too dim against a transparent background.
        colors.comment = "#8b95bd"
      end,
      -- Change how specific pieces of syntax are drawn. The names on the left
      -- are highlight groups; see section 4 for how to find the one you want.
      on_highlights = function(hl, colors)
        hl.Comment = { fg = colors.comment, italic = true }
        hl["@comment"] = { fg = colors.comment, italic = true }
        hl["@comment.documentation"] = { fg = colors.comment, italic = true }
        -- Function parameters were nearly the same grey as comments.
        hl["@variable.parameter"] = { fg = "#b7c5f0" }
        hl["@lsp.type.parameter"] = { fg = "#b7c5f0" }
        -- Line numbers: dim ones readable, current line clearly marked.
        hl.LineNr = { fg = "#6c769c" }
        hl.CursorLineNr = { fg = colors.orange, bold = true }
      end,
    },
  },

  -- 3. MORE THEMES
  -- Uncomment a block to install it, then put its name in section 1.
  -- { "ellisonleao/gruvbox.nvim", lazy = true },
  -- { "rebelot/kanagawa.nvim", lazy = true },
  -- { "rose-pine/neovim", name = "rose-pine", lazy = true },
  -- { "EdenEast/nightfox.nvim", lazy = true },
  -- { "sainnhe/everforest", lazy = true },

  -- 4. FINDING THE RIGHT NAME
  -- Put the cursor on any text and run :Inspect — Neovim prints the exact
  -- highlight groups colouring that character. Use the one it names in
  -- on_highlights above.
  --
  -- :lua Snacks.picker.highlights() lists every group with a live preview.
  -- <leader>uC previews themes live without editing this file.
}
