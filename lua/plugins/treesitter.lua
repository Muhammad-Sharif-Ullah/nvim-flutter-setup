return {
  -- LazyVim's default parser list has no Dart in it, so .dart files fall back
  -- to Vim's old regex syntax: no accurate highlighting, and none of the
  -- treesitter-based features (incremental selection, structural textobjects)
  -- work properly. Adding the parsers this setup actually needs.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "dart",
        "yaml", -- pubspec.yaml and analysis_options.yaml
        "xml",  -- AndroidManifest.xml
      })
      return opts
    end,
  },
}
