-- Wrap the widget under the cursor (or the visual selection) in a
-- flutter_bloc widget. The Dart analyzer only offers "Wrap with ..." for
-- Flutter's own widgets, so these are built here: the child is carried into
-- a LuaSnip snippet whose type arguments are jumpable placeholders.

local ls_ok, ls = pcall(require, "luasnip")

-- LSP-snippet text: everything the child contributes is literal.
local function escape(text)
  return (text:gsub("\\", "\\\\"):gsub("%$", "\\$"):gsub("}", "\\}"))
end

-- tree-sitter-dart has no single node for `Foo(...)`: it is an `identifier`
-- followed by one or more `selector` siblings. Walk up from the cursor until
-- one of those two shows up, then take the whole run of selectors so that
-- chains (`Foo(...).copyWith(...)`) come along.
local function widget_range()
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "dart")
  if not ok or not parser then return nil end
  local root = parser:parse()[1]:root()

  local pos = vim.api.nvim_win_get_cursor(0)
  local node = root:named_descendant_for_range(pos[1] - 1, pos[2], pos[1] - 1, pos[2])

  while node do
    local ident
    if node:type() == "identifier" then
      local nxt = node:next_named_sibling()
      if nxt and nxt:type() == "selector" then ident = node end
    elseif node:type() == "selector" then
      local prev = node:prev_named_sibling()
      while prev and prev:type() == "selector" do
        prev = prev:prev_named_sibling()
      end
      if prev and prev:type() == "identifier" then ident = prev end
    end

    if ident then
      local last = ident
      local nxt = ident:next_named_sibling()
      while nxt and nxt:type() == "selector" do
        last = nxt
        nxt = nxt:next_named_sibling()
      end
      local sr, sc = ident:start()
      local er, ec = last:end_()
      return sr, sc, er, ec
    end
    node = node:parent()
  end
  return nil
end

local function visual_range()
  local s = vim.fn.getpos("v")
  local e = vim.fn.getpos(".")
  local sr, sc, er, ec = s[2] - 1, s[3] - 1, e[2] - 1, e[3]
  if sr > er or (sr == er and sc > ec) then
    sr, sc, er, ec = er, ec - 1, sr, sc + 1
  end
  -- `$` in visual mode reports v:maxcol, and a multibyte tail can still land
  -- past the real end, so clamp to the line.
  local last = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or ""
  if ec > #last then ec = #last end
  return sr, sc, er, ec
end

-- Re-indent the child relative to its own first line, so it can be dropped
-- at any depth inside the wrapper.
local function dedent(lines, base)
  local out = {}
  for i, l in ipairs(lines) do
    if i == 1 then
      out[i] = l
    else
      out[i] = l:sub(#l:match("^%s*") >= #base and #base + 1 or 1)
    end
  end
  return out
end

-- `template` is a function receiving the child placed at the right depth and
-- returning the snippet body as a list of lines.
local function wrap(template)
  return function()
    if not ls_ok then
      vim.notify("LuaSnip is not available", vim.log.levels.ERROR)
      return
    end

    local mode = vim.fn.mode()
    local sr, sc, er, ec
    if mode == "v" or mode == "V" or mode == "\22" then
      sr, sc, er, ec = visual_range()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
      if mode == "V" then
        sc = 0
        ec = #(vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or "")
      end
    else
      sr, sc, er, ec = widget_range()
      if not sr then
        vim.notify("No widget found under the cursor", vim.log.levels.WARN)
        return
      end
    end

    local child = vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {})
    local base = vim.api.nvim_buf_get_lines(0, sr, sr + 1, false)[1]:match("^%s*")
    child = dedent(child, base)

    local body = template(child)

    -- Replace the target with nothing, then expand at that spot: LuaSnip
    -- indents the snippet to the current line, which is why the child was
    -- dedented first.
    vim.api.nvim_buf_set_text(0, sr, sc, er, ec, { "" })
    -- A linewise selection takes the indent with it; put it back, otherwise
    -- LuaSnip expands the wrapper hard against column 0.
    if sc == 0 and #base > 0 then
      vim.api.nvim_buf_set_text(0, sr, 0, sr, 0, { base })
      sc = #base
    end
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    ls.lsp_expand(table.concat(body, "\n"))
  end
end

-- Indent every child line by `pad`, escaping as it goes; the first line is
-- left bare because it continues the line the wrapper opened.
local function child_at(child, pad)
  local out = {}
  for i, l in ipairs(child) do
    out[i] = (i == 1 and "" or pad) .. escape(l)
  end
  return out
end

-- ${1:Bloc} / ${2:State} are typed once and repeated by LuaSnip.
local B, S = "${1:MyBloc}", "${2:MyState}"

local templates = {
  builder = function(c)
    return {
      "BlocBuilder<" .. B .. ", " .. S .. ">(",
      "  builder: (context, state) {",
      "    return " .. table.concat(child_at(c, "    "), "\n") .. ";",
      "  },",
      ")$0",
    }
  end,

  consumer = function(c)
    return {
      "BlocConsumer<" .. B .. ", " .. S .. ">(",
      "  listener: (context, state) {",
      "    $3",
      "  },",
      "  builder: (context, state) {",
      "    return " .. table.concat(child_at(c, "    "), "\n") .. ";",
      "  },",
      ")$0",
    }
  end,

  selector = function(c)
    return {
      "BlocSelector<" .. B .. ", " .. S .. ", ${3:T}>(",
      "  selector: (state) => ${4:state.value},",
      "  builder: (context, ${5:value}) {",
      "    return " .. table.concat(child_at(c, "    "), "\n") .. ";",
      "  },",
      ")$0",
    }
  end,

  listener = function(c)
    return {
      "BlocListener<" .. B .. ", " .. S .. ">(",
      "  listener: (context, state) {",
      "    $3",
      "  },",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  multi_listener = function(c)
    return {
      "MultiBlocListener(",
      "  listeners: [",
      "    BlocListener<${1:MyBloc}, ${2:MyState}>(",
      "      listener: (context, state) {",
      "        $3",
      "      },",
      "    ),",
      "  ],",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  provider = function(c)
    return {
      "BlocProvider<" .. B .. ">(",
      "  create: (context) => ${3:MyBloc()},",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  provider_value = function(c)
    return {
      "BlocProvider<" .. B .. ">.value(",
      "  value: ${2:bloc},",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  multi_provider = function(c)
    return {
      "MultiBlocProvider(",
      "  providers: [",
      "    BlocProvider<${1:MyBloc}>(",
      "      create: (context) => ${2:MyBloc()},",
      "    ),",
      "  ],",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  repo_provider = function(c)
    return {
      "RepositoryProvider<${1:MyRepository}>(",
      "  create: (context) => ${2:MyRepository()},",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,

  multi_repo_provider = function(c)
    return {
      "MultiRepositoryProvider(",
      "  providers: [",
      "    RepositoryProvider<${1:MyRepository}>(",
      "      create: (context) => ${2:MyRepository()},",
      "    ),",
      "  ],",
      "  child: " .. table.concat(child_at(c, "  "), "\n") .. ",",
      ")$0",
    }
  end,
}

local function key(lhs, name, desc)
  return { lhs, wrap(templates[name]), mode = { "n", "v" }, desc = desc }
end

return {
  {
    "nvim-flutter/flutter-tools.nvim",
    keys = {
      key("<leader>FwBb", "builder", "Wrap with BlocBuilder"),
      key("<leader>FwBc", "consumer", "Wrap with BlocConsumer"),
      key("<leader>FwBs", "selector", "Wrap with BlocSelector"),
      key("<leader>FwBl", "listener", "Wrap with BlocListener"),
      key("<leader>FwBL", "multi_listener", "Wrap with MultiBlocListener"),
      key("<leader>FwBp", "provider", "Wrap with BlocProvider"),
      key("<leader>FwBv", "provider_value", "Wrap with BlocProvider.value"),
      key("<leader>FwBm", "multi_provider", "Wrap with MultiBlocProvider"),
      key("<leader>FwBr", "repo_provider", "Wrap with RepositoryProvider"),
      key("<leader>FwBR", "multi_repo_provider", "Wrap with MultiRepositoryProvider"),
    },
    dependencies = { "L3MON4D3/LuaSnip" },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>FwB", group = "bloc", mode = { "n", "v" } },
      },
    },
  },
}
