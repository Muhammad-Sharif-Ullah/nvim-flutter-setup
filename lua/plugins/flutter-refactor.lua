-- "Wrap with ..." and the extract refactors come from the Dart analyzer as
-- ordinary LSP code actions. <leader>ca already lists them, mixed in with
-- Sort Members, Organize Imports and the rest; these keys filter straight to
-- the widget refactors so the common ones are a single press.

local function code_action(pattern, apply)
  return function()
    vim.lsp.buf.code_action({
      apply = apply,
      filter = function(action)
        return action.title and action.title:match(pattern) ~= nil
      end,
    })
  end
end

-- Applies immediately when exactly one action matches the exact title.
local function wrap(widget)
  return code_action("^Wrap with " .. widget .. "$", true)
end

return {
  {
    "nvim-flutter/flutter-tools.nvim",
    keys = {
      -- The menu: every "Wrap with ..." the analyzer offers here, including
      -- "Wrap with widget..." which prompts for any widget name.
      { "<leader>Fww", code_action("^Wrap with", false), mode = { "n", "v" }, desc = "Wrap with ... (menu)" },

      { "<leader>Fwc", wrap("Column"),    mode = { "n", "v" }, desc = "Wrap with Column" },
      { "<leader>Fwr", wrap("Row"),       mode = { "n", "v" }, desc = "Wrap with Row" },
      { "<leader>Fwp", wrap("Padding"),   mode = { "n", "v" }, desc = "Wrap with Padding" },
      { "<leader>Fwn", wrap("Center"),    mode = { "n", "v" }, desc = "Wrap with Center" },
      { "<leader>Fws", wrap("SizedBox"),  mode = { "n", "v" }, desc = "Wrap with SizedBox" },
      { "<leader>FwC", wrap("Container"), mode = { "n", "v" }, desc = "Wrap with Container" },
      { "<leader>Fwb", wrap("Builder"),   mode = { "n", "v" }, desc = "Wrap with Builder" },

      -- The other refactors from the same menu.
      { "<leader>Fx", code_action("^Extract Widget$", true), mode = { "n", "v" }, desc = "Extract Widget" },
      { "<leader>Fm", code_action("^Extract Method$", true), mode = { "n", "v" }, desc = "Extract Method" },
      { "<leader>Fv", code_action("^Extract Local Variable$", true), mode = { "n", "v" }, desc = "Extract Variable" },

      -- Removing a wrapper is a different action name.
      { "<leader>Fwd", code_action("^Remove widget", true), mode = { "n", "v" }, desc = "Remove this widget" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>Fw", group = "wrap with", mode = { "n", "v" } },
      },
    },
  },
}
