return {
  {
    "L3MON4D3/LuaSnip",
    -- The set lives outside ~/.config/nvim/snippets on purpose: LazyVim
    -- auto-scans that directory and would register every trigger twice.
    config = function(_, opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").load({
        paths = { vim.fn.stdpath("config") .. "/flutter-snippets" },
      })
    end,
  },
}
