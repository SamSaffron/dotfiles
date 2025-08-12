local function ensure_d_rspec()
  local script = [=[
#!/bin/bash

args=()
for arg in "$@"; do
  if [[ "$arg" == ./* ]]; then
    args+=("$(realpath "$arg")")
  else
    args+=("$arg")
  fi
done

(
  cd /home/sam/Source/discourse || exit 1
  if [[ "${args[*]}" == *"plugins"* ]]; then
    export LOAD_PLUGINS=1
  fi
  ./bin/rspec "${args[@]}"

  # Find the output file from arguments
  output_file=""
  for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ "${args[i]}" == "-o" ]]; then
      output_file="${args[i + 1]}"
      break
    fi
  done

  # If we found an output file, process it
  if [[ -n "$output_file" && -f "$output_file" ]]; then
    plugin_id=$(jq -r '.examples[0].id'        "$output_file")
    test_file=$(jq -r '.examples[0].file_path' "$output_file")

    skip_remap=false
    if [[ "$plugin_id" =~ ^\./plugins/[^/]+/ ]]; then
      plugin_abs=$(realpath "${plugin_id#./}")
      test_abs=$(realpath "$test_file")

      plugin_root=$(git -C "$(dirname "$plugin_abs")" rev-parse --show-toplevel 2>/dev/null || true)
      test_root=$(git  -C "$(dirname "$test_abs")"  rev-parse --show-toplevel 2>/dev/null || true)

      if [[ -n "$plugin_root" && "$plugin_root" == "$test_root" ]]; then
        skip_remap=true
      fi
    fi

    if [[ "$skip_remap" == false ]]; then
      temp_file=$(mktemp)
      jq '(.examples[] | select(.id != null) | .id) |= sub("\\./plugins/[^/]+/"; "./")' \
        "$output_file" >"$temp_file"
      mv "$temp_file" "$output_file"
    fi
  fi
)
]=]
  local script_path = "/tmp/d-rspec"
  local f = io.open(script_path, "w")
  if f then
    f:write(script)
    f:close()
    os.execute("chmod +x " .. script_path)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  {
    "mason-org/mason-lspconfig.nvim",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    opts = { ensure_installed = { "erb-formatter", "erb-lint" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
      servers = {
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
                return
              end
            end

            local runtime_files = vim.api.nvim_get_runtime_file("", true)
            for k, v in ipairs(runtime_files) do
              if v == "/home/sam/.config/nvim/after" or v == "/home/sam/.config/nvim" then
                table.remove(runtime_files, k)
              end
            end

            table.insert(runtime_files, "${3rd}/luv/library")

            local function get_all_plugin_paths()
              local paths = {}
              -- Get all plugin specs from lazy
              for _, plugin in pairs(require("lazy.core.config").plugins) do
                if type(plugin.dir) == "string" then
                  table.insert(paths, plugin.dir)
                end
              end
              return paths
            end

            -- add all missing runtime paths
            for _, path in ipairs(get_all_plugin_paths()) do
              if not vim.tbl_contains(runtime_files, path) then
                table.insert(runtime_files, path)
              end
            end

            client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
              runtime = {
                -- Tell the language server which version of Lua you're using
                -- (most likely LuaJIT in the case of Neovim)
                version = "LuaJIT",
              },
              workspace = {
                checkThirdParty = false,
                library = runtime_files,
              },
            })
          end,
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = "Replace",
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
        ruby_lsp = {},
        rubocop = {},
        -- glint = {}, not working at the moment
        ember = {},
        stylelint_lsp = {},
        eslint = {
          filetypes = {
            "javascript",
            "typescript",
            "typescript.glimmer",
            "javascript.glimmer",
            "json",
            "markdown",
          },
        },
        ts_ls = {},
        cssls = {},
      },
    },
    config = function(_, opts)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      for server, config in pairs(opts.servers) do
        vim.lsp.config(server, config)
      end

      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_enable = true,
        ensure_installed = vim.tbl_keys(opts.servers),
        automatic_installation = true,
        handlers = {
          function(server)
            local options = opts.servers[server] or {}
            options.capabilities = capabilities
            vim.lsp.config(server, options)
          end,
        },
      })

      vim.diagnostic.config(opts.diagnostics)

      -- vim.lsp.handlers["textDocument/publishDiagnostics"] =
      -- 	vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      -- 		underline = true,
      -- 		virtual_text = false,
      -- 		signs = true,
      -- 		update_in_insert = false,
      -- 	})
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      local cmp = require("cmp")

      local has_copilot_suggestion = function()
        local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
        return suggestion.item ~= nil and not vim.tbl_isempty(suggestion.item)
      end

      -- has its own version of completions, not super polished but go with it
      cmp.setup.filetype("copilot-chat", {
        enabled = false,
        sources = {},
        mapping = {},
      })

      cmp.setup({
        completion = {
          autocomplete = false,
        },
        mapping = {
          ["<Tab>"] = cmp.mapping({
            i = function(fallback)
              local col = vim.fn.col(".") - 1
              local line = vim.api.nvim_get_current_line()
              local char_before = col > 0 and line:sub(col, col)
              local trigger_chars = char_before and string.match(char_before, "[%a%.<]")

              if cmp.visible() then
                cmp.select_next_item()
              elseif has_copilot_suggestion() then
                fallback()
              elseif trigger_chars then
                cmp.complete()
              else
                fallback()
              end
            end,
          }),
          ["<C-i>"] = cmp.mapping({
            i = function()
              -- Ctrl Tab is very annoying and flaky to map
              -- going with ctrl-i instead for the override
              if cmp.visible() then
                cmp.select_next_item()
              else
                cmp.complete()
              end
            end,
          }),
          ["<S-Tab>"] = cmp.mapping({
            i = function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end,
          }),
          ["<Down>"] = cmp.mapping({
            i = function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              else
                fallback()
              end
            end,
          }),
          ["<Up>"] = cmp.mapping({
            i = function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end,
          }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
          { name = "cmdline" },
        },
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    ft = { "markdown", "Avante", "codecompanion" },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>b",
        function()
          require("conform").format({ async = true })
        end,
        desc = "Format buffer",
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      local util = require("conform.util")

      local function create_stree_formatter()
        -- Check if Gemfile.lock exists and contains syntax_tree using grep
        local has_stree_in_bundle = function()
          local gemfile_lock = vim.fn.findfile("Gemfile.lock", ".;")
          if gemfile_lock ~= "" then
            local grep_result = vim.fn.system("grep -q syntax_tree " .. vim.fn.shellescape(gemfile_lock))
            return vim.v.shell_error == 0
          end
          return false
        end

        return {
          command = function()
            if has_stree_in_bundle() then
              return "bundle"
            else
              return "stree"
            end
          end,
          args = function()
            if has_stree_in_bundle() then
              return { "exec", "stree", "write", "$FILENAME" }
            else
              return { "write", "$FILENAME" }
            end
          end,
          stdin = false,
          cwd = util.root_file({ ".streerc" }),
        }
      end

      -- eslint_d is simply a daemon that actually runs eslint
      -- from current directory
      -- it is required cause eslint has no fix to console
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          javascript = { "eslint_d", "prettier" },
          ruby = { "syntax_tree" },
          handlebars = { "prettier" },
          hbs = { "prettier" },
          css = { "prettier", "stylelint" },
          scss = { "prettier", "stylelint" },
        },
        default_format_opts = {
          lsp_format = "fallback",
        },
        format_after_save = {
          lsp_format = "fallback",
        },
        formatters = {
          shfmt = {
            prepend_args = { "-i", "2" },
          },
          syntax_tree = create_stree_formatter(),
        },
      })
    end,
  },
  {
    "vim-ruby/vim-ruby",
    ft = "ruby",
  },
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby", "haml", "slim" },
    config = function()
      -- disable autocmd set filetype=eruby.yaml, this breaks syntax highlighting
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
        pattern = { "*.yml" },
        callback = function()
          vim.bo.filetype = "yaml"
        end,
      })
    end,
  },
  {
    "tpope/vim-endwise",
    event = "InsertEnter",
  },
  {
    "tpope/vim-commentary",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "tpope/vim-surround",
    event = { "BufReadPre", "BufNewFile" },
  },
  {
    "nvim-neotest/neotest",
    commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c",
    lazy = true,
    dependencies = {
      "olimorris/neotest-rspec",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
      "antoinemadec/FixCursorHold.nvim",
    },
    -- stylua: ignore
    keys = {
      { "<leader>t",  "",                                                                                 desc = "+test" },
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end,                      desc = "Run File (Neotest)" },
      { "<leader>tT", function() require("neotest").run.run(vim.fn.getcwd()) end,                         desc = "Run All Test Files (Neotest)" },
      { "<leader>tr", function() require("neotest").run.run() end,                                        desc = "Run Nearest (Neotest)" },
      { "<leader>tl", function() require("neotest").run.run_last() end,                                   desc = "Run Last (Neotest)" },
      { "<leader>ts", function() require("neotest").summary.toggle() end,                                 desc = "Toggle Summary (Neotest)" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end,                            desc = "Toggle Output Panel (Neotest)" },
      { "<leader>tS", function() require("neotest").run.stop() end,                                       desc = "Stop (Neotest)" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end,                 desc = "Toggle Watch (Neotest)" },
    },
    config = function()
      local neotest_rspec = require("neotest-rspec")
      require("neotest").setup({
        adapters = {
          neotest_rspec({
            rspec_cmd = "/tmp/d-rspec",
          }),
        },
        output_panel = {
          open = "botright vsplit | vertical resize 80",
        },
      })
      ensure_d_rspec()
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "suketa/nvim-dap-ruby",
    },
    config = function()
      require("dap-ruby").setup()
    end,
  },
  {
    "nvim-treesitter/playground",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,             -- last release is way too old and doesn't work on Windows
    build = ":TSUpdate",
    lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>",      desc = "Decrement Selection", mode = "x" },
    },
    config = function()
      local opts = {
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
          "bash",
          "c",
          "diff",
          "html",
          "javascript",
          "glimmer",
          "jsdoc",
          "json",
          "jsonc",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "printf",
          "python",
          "query",
          "regex",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
          "ruby",
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
        textobjects = {
          move = {
            enable = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
              ["]a"] = "@parameter.inner",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
              ["]A"] = "@parameter.inner",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
              ["[a"] = "@parameter.inner",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
              ["[A"] = "@parameter.inner",
            },
          },
        },
      }
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- Automatically add closing tags for HTML and JSX
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },
  {
    "Rawnly/gist.nvim",
    cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
    config = true,
  },
  -- `GistsList` opens the selected gif in a terminal buffer,
  -- nvim-unception uses neovim remote rpc functionality to open the gist in an actual buffer
  -- and prevents neovim buffer inception
  {
    "samjwill/nvim-unception",
    lazy = false,
    init = function()
      vim.g.unception_block_while_host_edits = true
    end,
  },
}
