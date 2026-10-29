return {
  -- The Dart debug adapter comes from flutter-tools, not from mason, so
  -- mason-nvim-dap had nothing to install for this setup and cost ~10ms of
  -- startup resolving that.
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
