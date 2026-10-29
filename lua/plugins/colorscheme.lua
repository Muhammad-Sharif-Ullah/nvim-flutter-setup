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
      transparent = false,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
      -- Change individual colors of the theme itself.
      on_colors = function(colors)
        -- colors.comment = "#7f87a3"  -- brighter comments
        -- colors.bg = "#16161e"       -- darker background
      end,
      -- Change how specific pieces of syntax are drawn. The names on the left
      -- are highlight groups; see section 4 for how to find the one you want.
      on_highlights = function(hl, colors)
        -- hl.Comment       = { fg = colors.comment, italic = true }
        -- hl["@string"]    = { fg = colors.green }
        -- hl["@keyword"]   = { fg = colors.purple, bold = true }
        -- hl["@type"]      = { fg = colors.yellow }
        -- hl["@function"]  = { fg = colors.blue }
        -- hl.LineNr        = { fg = colors.dark3 }
        -- hl.CursorLineNr  = { fg = colors.orange, bold = true }
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
