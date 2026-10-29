return {
  -- All three of these duplicated something LazyVim already ships, and each
  -- one cost startup time for behaviour that was already there:
  --   toggleterm   -> snacks.terminal
  --   Comment.nvim -> ts-comments (gcc / gc still work)
  --   autopairs    -> mini.pairs
  { "akinsho/toggleterm.nvim", enabled = false },
  { "numToStr/Comment.nvim", enabled = false },
  { "windwp/nvim-autopairs", enabled = false },
}
