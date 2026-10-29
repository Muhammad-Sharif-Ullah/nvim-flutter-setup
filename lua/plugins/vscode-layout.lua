return {
  -- LazyVim 16 uses snacks.explorer as the file tree; neo-tree would be a
  -- second, redundant one, so it stays off.
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  {
    "folke/snacks.nvim",
    opts = {
      explorer = { replace_netrw = true },
      picker = {
        sources = {
          explorer = {
            layout = { preset = "sidebar", preview = false },
            win = { list = { keys = { ["<Esc>"] = "close" } } },
            auto_close = false,
            follow_file = true,
            hidden = true,
          },
        },
      },
    },
  },

  -- Docks the side and bottom panels so they keep their place.
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      opts.bottom = opts.bottom or {}
      vim.list_extend(opts.bottom, {
        { ft = "dap-repl", title = "Debug Console", size = { height = 0.3 } },
        {
          ft = "snacks_terminal",
          title = "Terminal",
          size = { height = 0.3 },
          filter = function(_, win) return vim.w[win].snacks_win and vim.w[win].snacks_win.position == "bottom" end,
        },
      })
      opts.right = opts.right or {}
      vim.list_extend(opts.right, {
        { ft = "flutterToolsOutline", title = "Widget Tree", size = { width = 36 } },
      })
      return opts
    end,
  },

  -- Show the selected device and app version in the status bar.
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return vim.g.flutter_tools_decorations and vim.g.flutter_tools_decorations.device
            and vim.g.flutter_tools_decorations.device.name or ""
        end,
        icon = "",
      })
      return opts
    end,
  },

  -- Open the debug panels automatically when a session starts.
  {
    "rcarriga/nvim-dap-ui",
    -- Layout 1 is the variables/stack/breakpoints sidebar, layout 2 is the
    -- bottom console; dap-ui addresses them by index so each can be toggled
    -- on its own.
    keys = {
      {
        "<leader>dS",
        function() require("dapui").toggle({ layout = 1 }) end,
        desc = "Toggle debug sidebar",
      },
      {
        "<leader>dC",
        function() require("dapui").toggle({ layout = 2 }) end,
        desc = "Toggle debug console",
      },
    },
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.5 },
            { id = "stacks", size = 0.3 },
            { id = "breakpoints", size = 0.2 },
          },
          position = "left",
          size = 40,
        },
        -- Console is omitted: the Dart adapter writes everything to the repl,
        -- so it would only ever be an empty pane.
        {
          elements = {
            { id = "repl", size = 1.0 },
          },
          position = "bottom",
          size = 12,
        },
      },
    },
  },
}
