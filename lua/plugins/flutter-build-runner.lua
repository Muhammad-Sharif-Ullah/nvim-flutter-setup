-- build_runner codegen (go_router_builder, envied, json_serializable...).
-- flutter-tools has no binding for it, and `watch` is a long-lived process
-- that must be stoppable, so this runs it as a tracked job into its own
-- bottom panel instead of a throwaway terminal.

local BUF_NAME = "Build Runner"
local FILETYPE = "buildrunner"

local job = nil -- the running `watch` (or `build`) handle, if any

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
  if vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "" then
    vim.notify("Build Runner is empty - run <leader>Fbb or <leader>Fbw first", vim.log.levels.INFO)
    return
  end
  show(buf)
end

-- The project root, not the cwd: build_runner must run beside pubspec.yaml.
local function project_root()
  local found = vim.fs.find("pubspec.yaml", {
    upward = true,
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
  })[1]
  return found and vim.fs.dirname(found) or vim.fn.getcwd()
end

local function dart_bin()
  for _, p in ipairs({
    project_root() .. "/.fvm/flutter_sdk/bin/dart",
    vim.fn.exepath("dart"),
    vim.fn.expand("~/flutter/bin/dart"),
    "/opt/homebrew/bin/dart",
  }) do
    if p ~= "" and vim.fn.executable(p) == 1 then return p end
  end
  return "dart"
end

local function stop()
  if not job then
    vim.notify("No build_runner job running", vim.log.levels.INFO)
    return false
  end
  job:kill("sigterm")
  job = nil
  return true
end

-- `args` is what follows `dart run build_runner`.
-- Note: --delete-conflicting-outputs was removed in build_runner 2.16, so it
-- is deliberately not passed; `clean` covers the stale-output case instead.
local function run(args, label, opts)
  opts = opts or {}
  return function()
    if job then
      vim.notify("build_runner already running - <leader>Fbk to stop it", vim.log.levels.WARN)
      return
    end

    local buf = get_buf()
    show(buf)

    if not opts.keep then
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      vim.bo[buf].modifiable = false
    end

    local root = project_root()
    local started = vim.loop.hrtime()
    append(buf, { "$ dart run build_runner " .. table.concat(args, " ") .. "  (" .. root .. ")", "" })

    local function stream(_, data)
      if not data then return end
      local lines = vim.split(data, "\n", { trimempty = true })
      if #lines > 0 then vim.schedule(function() append(buf, lines) end) end
    end

    job = vim.system(
      vim.list_extend({ dart_bin(), "run", "build_runner" }, args),
      { cwd = root, stdout = stream, stderr = stream },
      function(res)
        job = nil
        vim.schedule(function()
          local secs = (vim.loop.hrtime() - started) / 1e9
          append(buf, {
            "",
            string.format("%s %s in %.1fs (exit %d)",
              res.code == 0 and "Finished" or "STOPPED/FAILED",
              label, secs, res.code),
          })
        end)
      end
    )
  end
end

-- clean wipes generated outputs, then build regenerates from scratch; the
-- second step is chained so it only starts once clean has released the job.
local function clean_build()
  local buf = get_buf()
  show(buf)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.bo[buf].modifiable = false

  local root = project_root()
  append(buf, { "$ dart run build_runner clean  (" .. root .. ")" })
  vim.system({ dart_bin(), "run", "build_runner", "clean" }, { cwd = root }, function()
    vim.schedule(run({ "build" }, "build", { keep = true }))
  end)
end

return {
  {
    "nvim-flutter/flutter-tools.nvim",
    keys = {
      { "<leader>Fbb", run({ "build" }, "build"), desc = "build_runner build" },
      { "<leader>Fbw", run({ "watch" }, "watch"), desc = "build_runner watch (start)" },
      { "<leader>Fbk", stop, desc = "build_runner stop" },
      { "<leader>Fbc", clean_build, desc = "build_runner clean + build" },
      { "<leader>FbO", toggle, desc = "Toggle Build Runner panel" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>Fb", group = "build_runner", icon = "" },
      },
    },
  },
  {
    "folke/edgy.nvim",
    opts = function(_, opts)
      opts.bottom = opts.bottom or {}
      table.insert(opts.bottom, {
        ft = FILETYPE,
        title = "Build Runner",
        size = { height = 0.3 },
      })
      return opts
    end,
  },
}
