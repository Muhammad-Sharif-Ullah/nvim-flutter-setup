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

-- Ctrl+J and Enter are the same byte, so <C-j> is unreliable in a
-- terminal. <C-w> has no such collision: this makes it leave terminal
-- mode and act as the ordinary window prefix, so <C-w>j, <C-w>k and
-- <C-w>w all work from inside a shell exactly as they do in a buffer.
vim.keymap.set("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window prefix" })

-- Escape to normal mode inside a terminal, for scrolling and copying.
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Normal mode" })
