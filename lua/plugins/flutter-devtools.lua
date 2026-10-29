-- DevTools and the widget inspector. flutter-tools exposes some of these as
-- commands and the rest only through the :FlutterCommands menu, so the
-- menu-only ones are called through the module directly.

local function cmd(name)
  return function()
    local ok, commands = pcall(require, "flutter-tools.commands")
    if not ok then
      return vim.notify("flutter-tools is not loaded yet", vim.log.levels.WARN)
    end
    local fn = commands[name]
    if type(fn) ~= "function" then
      return vim.notify("flutter-tools has no command '" .. name .. "'", vim.log.levels.ERROR)
    end
    fn()
  end
end

return {
  {
    "nvim-flutter/flutter-tools.nvim",
    keys = {
      -- DevTools proper (opens in the browser; there is no in-editor UI).
      { "<leader>FD", "<cmd>FlutterDevTools<cr>", desc = "DevTools: start server" },
      { "<leader>Fib", "<cmd>FlutterOpenDevTools<cr>", desc = "DevTools: open in browser" },
      { "<leader>FiI", "<cmd>FlutterDevToolsActivate<cr>", desc = "DevTools: install/update" },
      { "<leader>Fiu", "<cmd>FlutterCopyProfilerUrl<cr>", desc = "Copy VM service URL" },

      -- Widget inspector: puts the running app into select-widget mode, so
      -- tapping a widget on the device highlights it and reveals its tree.
      { "<leader>Fii", "<cmd>FlutterInspectWidget<cr>", desc = "Inspect widget (tap on device)" },

      -- The visual debugging overlays, drawn on the device itself.
      { "<leader>Fid", "<cmd>FlutterVisualDebug<cr>", desc = "Toggle debug paint (layout bounds)" },
      { "<leader>Fip", cmd("performance_overlay"), desc = "Toggle performance overlay (FPS)" },
      { "<leader>Fir", cmd("repaint_rainbow"), desc = "Toggle repaint rainbow" },
      { "<leader>Fis", cmd("slow_animations"), desc = "Toggle slow animations" },
      { "<leader>Fil", cmd("paint_baselines"), desc = "Toggle text baselines" },
      { "<leader>Fit", "<cmd>FlutterToggleBrightness<cr>", desc = "Toggle light/dark mode" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>Fi", group = "inspect / devtools" },
      },
    },
  },
}
