-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Terminal docked at the bottom. <C-/> (which most terminals send as <C-_>)
-- is LazyVim's default; <leader>tt is the spelling that works everywhere,
-- including emulators that swallow control-punctuation.
vim.keymap.set({ "n", "t" }, "<leader>tt", function()
  Snacks.terminal.toggle()
end, { desc = "Terminal (bottom)" })

-- Open the cheatsheet.
vim.keymap.set("n", "<leader>F?", function()
  vim.cmd.tabnew(vim.fn.stdpath("config") .. "/CHEATSHEET.md")
end, { desc = "Flutter/Neovim cheatsheet" })
