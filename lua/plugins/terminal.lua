return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "bottom",
          height = 0.3,
        },
      },
    },
    -- <C-/> toggles the one terminal, keyed on cmd + cwd, so it never
    -- gives you a second. open() always makes a fresh instance.
    keys = {
      {
        "<leader>tn",
        function()
          Snacks.terminal.open()
        end,
        desc = "New Terminal",
      },
    },
  },
}
