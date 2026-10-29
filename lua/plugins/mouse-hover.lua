return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- VS Code shows documentation when the mouse rests over a symbol.
      -- Neovim only does it on `K`, so this wires the mouse up to the same
      -- LSP hover request, debounced so it fires once the mouse settles.
      vim.o.mousemoveevent = true

      local DELAY_MS = 350
      local timer = vim.uv.new_timer()
      local float_win = nil
      local last = { row = -1, col = -1 }

      local function close_float()
        if float_win and vim.api.nvim_win_is_valid(float_win) then
          vim.api.nvim_win_close(float_win, true)
        end
        float_win = nil
      end

      local function show_hover()
        local pos = vim.fn.getmousepos()
        if pos.winid == 0 or pos.line == 0 then
          return close_float()
        end
        -- Never hover over our own float, or the mouse can never leave it.
        if float_win and pos.winid == float_win then
          return
        end

        local buf = vim.api.nvim_win_get_buf(pos.winid)
        if not vim.api.nvim_buf_is_loaded(buf) then
          return close_float()
        end
        if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/hover" }) == 0 then
          return close_float()
        end

        local params = {
          textDocument = vim.lsp.util.make_text_document_params(buf),
          position = { line = pos.line - 1, character = pos.column - 1 },
        }

        vim.lsp.buf_request(buf, "textDocument/hover", params, function(err, result)
          if err or not result or not result.contents then
            return close_float()
          end
          local md = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
          if vim.tbl_isempty(md) then
            return close_float()
          end
          close_float()
          local _, win = vim.lsp.util.open_floating_preview(md, "markdown", {
            border = "rounded",
            focusable = false,
            max_width = 80,
            max_height = 20,
            relative = "mouse",
          })
          float_win = win
        end)
      end

      vim.keymap.set({ "n", "i" }, "<MouseMove>", function()
        local pos = vim.fn.getmousepos()
        -- Only restart the clock when the mouse actually changed cell.
        if pos.line ~= last.row or pos.column ~= last.col then
          last.row, last.col = pos.line, pos.column
          close_float()
          timer:stop()
          timer:start(DELAY_MS, 0, vim.schedule_wrap(show_hover))
        end
        return "<MouseMove>"
      end, { expr = true, desc = "Hover documentation under the mouse" })

      vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
        group = vim.api.nvim_create_augroup("MouseHoverClose", { clear = true }),
        callback = function()
          timer:stop()
          close_float()
        end,
      })
    end,
  },
}
