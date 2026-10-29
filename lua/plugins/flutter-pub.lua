-- flutter-tools pushes `pub get` output through a single ui.notify popup
-- (commands.lua:453). Long output overflows it and there is no way to scroll,
-- so this runs the same commands into a real buffer docked at the bottom.

local BUF_NAME = "Flutter Output"
local FILETYPE = "flutteroutput"

local function get_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t") == BUF_NAME then
      return b
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, BUF_NAME)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = FILETYPE
  return buf
end

local function win_for(buf)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then return w end
  end
  return nil
end

local function show(buf)
  if win_for(buf) then return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("botright 12split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.wrap = false
  vim.api.nvim_set_current_win(cur)
end

local function append(buf, lines)
  vim.bo[buf].modifiable = true
  local count = vim.api.nvim_buf_line_count(buf)
  local empty = count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
  vim.api.nvim_buf_set_lines(buf, empty and 0 or count, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Follow the tail only while the cursor is already at the bottom, so a
  -- scrolled-back reader is not yanked away mid-line.
  local w = win_for(buf)
  if w and vim.api.nvim_win_is_valid(w) then
    local pos = vim.api.nvim_win_get_cursor(w)
    if pos[1] >= count - 1 then
      vim.api.nvim_win_set_cursor(w, { vim.api.nvim_buf_line_count(buf), 0 })
    end
  end
end

-- Close the panel without having to jump into it first.
local function hide()
  local buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b)
      and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t") == BUF_NAME then
      buf = b
    end
  end
  if not buf then return false end
  local w = win_for(buf)
  if not w then return false end
  vim.api.nvim_win_close(w, true)
  return true
end

local function toggle()
  if hide() then return end
  local buf = get_buf()
  -- Nothing has been run yet: say so rather than opening an empty pane.
  if vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    vim.notify("Flutter Output is empty - run <leader>Fp, <leader>FU or <leader>Fc first", vim.log.levels.INFO)
    return
  end
  show(buf)
end

local function run(args, label)
  return function()
    local buf = get_buf()
    show(buf)

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.bo[buf].modifiable = false

    local started = vim.loop.hrtime()
    append(buf, { "$ flutter " .. table.concat(args, " "), "" })

    local function stream(_, data)
      if not data then return end
      local lines = vim.split(data, "\n", { trimempty = true })
      if #lines > 0 then vim.schedule(function() append(buf, lines) end) end
    end

    vim.system(
      vim.list_extend({ vim.fn.expand("~/flutter/bin/flutter") }, args),
      { cwd = vim.fn.getcwd(), stdout = stream, stderr = stream },
      function(res)
        vim.schedule(function()
          local secs = (vim.loop.hrtime() - started) / 1e9
          append(buf, {
            "",
            string.format("%s %s in %.1fs (exit %d)",
              res.code == 0 and "Finished" or "FAILED",
              label, secs, res.code),
          })
        end)
      end
    )
  end
end

return {
  {
    "nvim-flutter/flutter-tools.nvim",
    keys = {
      { "<leader>Fp", run({ "pub", "get" }, "pub get"), desc = "Pub get (output panel)" },
      { "<leader>FU", run({ "pub", "upgrade" }, "pub upgrade"), desc = "Pub upgrade (output panel)" },
      { "<leader>Fc", run({ "clean" }, "clean"), desc = "Flutter clean (output panel)" },
      { "<leader>FO", toggle, desc = "Toggle Flutter Output panel" },
    },
  },
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      opts.bottom = opts.bottom or {}
      table.insert(opts.bottom, {
        ft = FILETYPE,
        title = "Flutter Output",
        size = { height = 0.3 },
      })
      return opts
    end,
  },
}
