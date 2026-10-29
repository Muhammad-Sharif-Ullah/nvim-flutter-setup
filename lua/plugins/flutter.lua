return {
  {
    "nvim-flutter/flutter-tools.nvim",
    -- Loaded on demand rather than at startup (which cost ~25ms). `ft` is the
    -- important one: lazy.nvim re-fires FileType after loading, so the Dart
    -- analyzer still attaches to a .dart file opened directly from the shell.
    -- VeryLazy would not -- by then FileType has already passed and the LSP
    -- never starts.
    ft = { "dart" },
    cmd = {
      "FlutterRun", "FlutterDebug", "FlutterDevices", "FlutterEmulators",
      "FlutterReload", "FlutterRestart", "FlutterQuit", "FlutterAttach",
      "FlutterDetach", "FlutterOutlineToggle", "FlutterDevTools",
      "FlutterPubGet", "FlutterPubUpgrade", "FlutterLspRestart",
      "FlutterCommands", "FlutterLogToggle", "FlutterInspectWidget",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
      "mfussenegger/nvim-dap",
    },
    keys = {
      { "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "Run app" },
      { "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Select device" },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Select emulator" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Quit app" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Hot restart" },
      { "<leader>Fh", "<cmd>FlutterReload<cr>", desc = "Hot reload" },
      { "<leader>Fl", function() require("dapui").toggle() end, desc = "Toggle debug panels" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Widget outline" },
      { "<leader>Fs", "<cmd>FlutterLspRestart<cr>", desc = "Restart Dart LSP" },
      { "<leader>Fp", "<cmd>FlutterPubGet<cr>", desc = "Pub get" },
      { "<leader>FD", "<cmd>FlutterDevTools<cr>", desc = "DevTools" },
    },
    config = function()
      -- Find the Flutter SDK wherever this machine happens to keep it, rather
      -- than hardcoding one path: PATH first (covers Homebrew, asdf and a
      -- manual clone that was added to PATH), then the usual manual-install
      -- locations. FVM is checked before the rest so a project pinned to a
      -- specific SDK version wins. nil means "let flutter-tools look".
      local function flutter_path()
        local candidates = {
          vim.fn.getcwd() .. "/.fvm/flutter_sdk/bin/flutter",
          vim.fn.exepath("flutter"),
          vim.fn.expand("~/flutter/bin/flutter"),
          vim.fn.expand("~/development/flutter/bin/flutter"),
          vim.fn.expand("~/fvm/default/bin/flutter"),
          "/opt/homebrew/bin/flutter",
          "/usr/local/bin/flutter",
          "/snap/bin/flutter",
        }
        for _, path in ipairs(candidates) do
          if path ~= "" and vim.fn.executable(path) == 1 then
            return path
          end
        end
        return nil
      end

      require("flutter-tools").setup({
        flutter_path = flutter_path(),

        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = true,
          },
        },

        widget_guides = { enabled = true },

        -- Start the DevTools server alongside the app so the widget inspector
        -- is ready when wanted. The browser is not opened automatically;
        -- <leader>Fib does that. This has to live here rather than in another
        -- spec's `opts`, because setup() is called explicitly below.
        dev_tools = {
          autostart = true,
          auto_open_browser = false,
        },

        closing_tags = {
          highlight = "Comment",
          prefix = "// ",
          enabled = true,
        },

        -- Off on purpose: run_via_dap already streams the app's output into
        -- the Debug Console, so this would be a second copy of the same log.
        dev_log = {
          enabled = false,
          notify_errors = true,
        },

        -- Launch the app under the Dart debug adapter so breakpoints,
        -- step/over/into and the variable scopes panel all work.
        debugger = {
          enabled = true,
          run_via_dap = true,
          exception_breakpoints = {},
          evaluate_to_string_in_debug_views = true,
          register_configurations = function(_)
            require("dap").configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch Flutter",
                dartSdkPath = vim.fn.expand("~/flutter/bin/cache/dart-sdk/"),
                flutterSdkPath = vim.fn.expand("~/flutter/"),
                program = "${workspaceFolder}/lib/main.dart",
                cwd = "${workspaceFolder}",
              },
            }
          end,
        },

        lsp = {
          -- No `color` block here: on Neovim 0.12+ the plugin deprecates it in
          -- favour of vim.lsp.document_color, which is on by default. Setting
          -- it produced a "lsp.color is deprecated" warning on every start.
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            enableSnippets = true,
            updateImportsOnRename = true,
            analysisExcludedFolders = {
              vim.fn.expand("~/flutter/.pub-cache"),
              vim.fn.expand("~/.pub-cache"),
              vim.fn.expand("~/flutter/packages"),
            },
          },
        },
      })

      -- flutter-tools registers its commands only on entering a .dart file or
      -- pubspec.yaml. Trigger that now, so the commands exist as soon as this
      -- plugin loads -- including when it was loaded by a <leader>F key from a
      -- buffer that is not Dart. Run inline, not on VimEnter: by the time a
      -- lazy-loaded plugin gets here, VimEnter has already fired.
      local function init_if_flutter_project()
        if vim.fn.findfile("pubspec.yaml", ".;") ~= "" then
          vim.api.nvim_exec_autocmds("BufEnter", { pattern = "pubspec.yaml" })
        end
      end

      init_if_flutter_project()

      vim.api.nvim_create_autocmd("DirChanged", {
        group = vim.api.nvim_create_augroup("FlutterToolsEagerInit", { clear = true }),
        callback = init_if_flutter_project,
      })
    end,
  },
}
