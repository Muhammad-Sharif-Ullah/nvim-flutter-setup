-- Project-local launch configurations -- the `.vscode/launch.json` idea,
-- without VS Code.
--
-- Drop a `.nvim/launch.json` in a Flutter project and `:FlutterRun` /
-- `:FlutterDebug` offer its entries in a picker: entrypoint, flavor, mode,
-- device, dart-defines, extra args. Provide nothing and nothing changes --
-- the app runs exactly as it does today, straight off `lib/main.dart`.
--
-- Files are searched upwards from the current buffer, first hit wins:
--
--   .nvim/launch.json    preferred -- ours
--   .nvim.json           single-file variant, same contents
--   .vscode/launch.json  read as-is, so a mixed team shares one source
--
-- The schema is VS Code's, so an existing launch.json can simply be copied:
--
--   { "version": "0.2.0",
--     "configurations": [
--       { "name": "Dose Care (dev) -debug",
--         "request": "launch", "type": "dart",
--         "program": "lib/app_dev.dart",
--         "flutterMode": "debug",
--         "flavor": "dev",
--         "deviceId": "macos",
--         "toolArgs": ["--dart-define=FOO=bar"] } ] }
--
-- Comments and trailing commas are tolerated, as in VS Code.

local M = {}

M.filenames = { ".nvim/launch.json", ".nvim.json", ".vscode/launch.json" }

---Strip // and /* */ comments and trailing commas: JSON with the slack that
---VS Code allows, which is what people actually write in these files.
---Quoted strings are copied through untouched so a "http://x" survives.
---@param text string
---@return string
local function strip_jsonc(text)
  local out, i, n = {}, 1, #text
  while i <= n do
    local c = text:sub(i, i)
    if c == '"' then
      local j = i + 1
      while j <= n do
        local ch = text:sub(j, j)
        if ch == "\\" then
          j = j + 2
        elseif ch == '"' then
          break
        else
          j = j + 1
        end
      end
      out[#out + 1] = text:sub(i, j)
      i = j + 1
    elseif c == "/" and text:sub(i + 1, i + 1) == "/" then
      i = (text:find("\n", i) or n + 1)
    elseif c == "/" and text:sub(i + 1, i + 1) == "*" then
      local close = text:find("*/", i + 2, true)
      i = close and close + 2 or n + 1
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return (table.concat(out):gsub(",%s*([}%]])", "%1"))
end

---@param dir string directory to start from, searched upwards
---@return string? path, string? err
local function find_file(dir)
  for _, name in ipairs(M.filenames) do
    local found = vim.fs.find(name, { upward = true, path = dir, type = "file" })[1]
    if found then return found end
  end
end

---Map one VS Code launch entry onto a flutter-tools project config.
---@param c table
---@return flutter.ProjectConfig?
local function to_project_config(c)
  if type(c) ~= "table" or c.request == "attach" then return nil end
  if c.type and c.type ~= "dart" and c.type ~= "flutter" then return nil end

  local additional = {}
  -- `toolArgs` go to the flutter tool (--dart-define, --web-renderer, ...),
  -- `args` go to the app itself after a `--` separator. flutter-tools appends
  -- additional_args verbatim to `flutter run`, so toolArgs map across
  -- directly and args need their separator put back.
  vim.list_extend(additional, c.toolArgs or {})
  vim.list_extend(additional, c.additionalArgs or {})
  if c.args and #c.args > 0 then
    additional[#additional + 1] = "--"
    vim.list_extend(additional, c.args)
  end

  return {
    name = c.name,
    target = c.program,
    flavor = c.flavor,
    flutter_mode = c.flutterMode,
    device = c.deviceId or c.device,
    cwd = c.cwd,
    web_port = c.webPort and tostring(c.webPort) or nil,
    dart_define = c.dartDefines or c.env,
    dart_define_from_file = c.dartDefineFromFile,
    additional_args = #additional > 0 and additional or nil,
  }
end

---Read the launch file nearest to `dir`.
---@param dir? string defaults to the current file's directory
---@return flutter.ProjectConfig[] configs, string? path
function M.read(dir)
  dir = dir or vim.fn.expand("%:p:h")
  if dir == "" then dir = vim.fn.getcwd() end

  local file = find_file(dir)
  if not file then return {} end

  local ok, text = pcall(function() return table.concat(vim.fn.readfile(file), "\n") end)
  if not ok or not text or text:match("^%s*$") then return {}, file end

  local decoded
  ok, decoded = pcall(vim.json.decode, strip_jsonc(text), { luanil = { object = true, array = true } })
  if not ok then
    vim.notify(
      ("flutter: could not parse %s -- running with defaults\n%s"):format(file, decoded),
      vim.log.levels.WARN
    )
    return {}, file
  end

  -- Accept the full VS Code envelope or a bare array of configurations.
  local raw = decoded.configurations or decoded
  if type(raw) ~= "table" then return {}, file end

  local configs = {}
  for _, c in ipairs(raw) do
    local mapped = to_project_config(c)
    if mapped then configs[#configs + 1] = mapped end
  end
  return configs, file
end

---Read the nearest launch file and hand it to flutter-tools.
---
---With no file, or an unusable one, flutter-tools is left with no project
---config at all, which is the untouched default behaviour -- `:FlutterRun`
---shows no picker and runs lib/main.dart.
---@param dir? string
---@return flutter.ProjectConfig[]
function M.apply(dir)
  local configs, file = M.read(dir)
  require("flutter-tools").setup_project(configs)
  M.loaded = { file = file, count = #configs }
  return configs
end

---`:FlutterLaunchInfo` -- what was picked up, and from where.
function M.info()
  local configs, file = M.read()
  if not file then
    vim.notify("flutter: no launch file found (" .. table.concat(M.filenames, ", ") .. ")")
    return
  end
  local names = vim.tbl_map(function(c) return "  - " .. (c.name or "<unnamed>") end, configs)
  vim.notify(("flutter: %d configuration(s) from %s\n%s"):format(#configs, file, table.concat(names, "\n")))
end

---Wire up loading: now, and again whenever the project changes underfoot.
function M.setup()
  M.apply()

  vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("FlutterLaunchConfig", { clear = true }),
    pattern = { "*.dart", "pubspec.yaml", "*" },
    callback = function(args)
      -- Only on events that can mean a different project: a cwd change, or
      -- entering a Dart buffer from somewhere else.
      if args.event == "BufEnter" and vim.bo[args.buf].filetype ~= "dart" then return end
      M.apply()
    end,
  })

  vim.api.nvim_create_user_command("FlutterLaunchInfo", M.info, {
    desc = "Show the project launch configurations in use",
  })
end

return M
