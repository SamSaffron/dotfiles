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
    temp_file=$(mktemp)
    jq '(.examples[] | select(.id != null) | .id) |= sub("\\./plugins/[^/]+/"; "./")' "$output_file" >"$temp_file"
    mv "$temp_file" "$output_file"
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
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
	{
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
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
				severity_sort = true,
			},
			servers = {
				lua_ls = {
					on_init = function(client)
						if client.workspace_folders then
							local path = client.workspace_folders[1].name
							if
								vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc")
							then
								return
							end
						end

						client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
							runtime = {
								-- Tell the language server which version of Lua you're using
								-- (most likely LuaJIT in the case of Neovim)
								version = "LuaJIT",
							},
							-- Make the server aware of Neovim runtime files
							workspace = {
								checkThirdParty = false,
								library = {
									vim.env.VIMRUNTIME,
									-- Depending on the usage, you might want to add additional paths here.
									-- "${3rd}/luv/library"
									-- "${3rd}/busted/library",
								},
								-- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
								-- library = vim.api.nvim_get_runtime_file("", true)
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
				-- Add other language servers you need here
				ruby_lsp = {
					enabled = true,
				},
				rubocop = {
					enabled = true,
				},
				glint = {
					enabled = true,
				},
				eslint = {
					enabled = true,
					on_init = function(client)
						-- TODO figure this out
						-- client.server_capabilities.documentForattingProvider = true
					end,
				},
				ts_ls = {
					enabled = true,
				},
			},
		},
		config = function(_, opts)
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(opts.servers),
				handlers = {
					function(server)
						require("lspconfig")[server].setup(opts.servers[server] or {})
					end,
				},
			})
			-- Configure diagnostics
			vim.diagnostic.config(opts.diagnostics)
		end,
	},
	{
		"github/copilot.vim",
		event = "InsertEnter",
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
			require("cmp").setup({
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
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim" },
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			model = "claude-3.5-sonnet",
		},
		keys = {
			{
				"<leader>c",
				function()
					local visualmode = vim.fn.mode()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						local chat = require("CopilotChat")
						local select = require("CopilotChat.select")

						local selection
						-- if we have a line in visual mode then select it
						if visualmode == "V" or visualmode == "v" or visualmode == "\22" then
							selection = select.visual
						else
							selection = select.buffer
						end

						chat.ask(input, { selection = selection })
					end
				end,
				mode = { "n", "v" },
				desc = "Start Copilot Chat",
			},
		},
	},
	-- {
	--   "dense-analysis/ale",
	--   event = { "BufReadPre", "BufNewFile" },
	--   config = function()
	--     vim.g.ale_linters = {
	--       ruby = { 'ruby', 'rubocop' },
	--       javascript = { 'eslint', 'embertemplatelint' },
	--       handlebars = { 'embertemplatelint', 'prettier' },
	--       glimmer = { 'eslint', 'embertemplatelint' },
	--     }
	--     vim.g.ale_fixers = {
	--       ruby = { 'syntax_tree' },
	--       ['javascript.glimmer'] = { 'eslint', 'prettier' },
	--       handlebars = { 'prettier' },
	--       ['html.handlebars'] = { 'prettier' },
	--       scss = { 'prettier' },
	--       javascript = { 'eslint', 'prettier' },
	--     }
	--     vim.g.ale_fix_on_save = 0
	--     vim.g.ale_lint_on_text_changed = 'never'
	--     vim.g.ale_lint_on_insert_leave = 0
	--   end,
	-- },
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>a",
				function()
					require("conform").format({ async = true })
				end,
				desc = "Format buffer",
			},
		},
		-- This will provide type hinting with LuaLS
		---@module "conform"
		---@type conform.setupOpts
		opts = {
			-- Define your formatters
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettier", "eslint" },
				ruby = { "syntax_tree" },
			},
			-- Set default options
			default_format_opts = {
				lsp_format = "fallback",
			},
			-- Set up format-on-save
			format_on_save = { timeout_ms = 500 },
			-- Customize formatters
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
			},
		},
		init = function()
			-- If you want the formatexpr, here is the place to set it
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
	{
		"vim-ruby/vim-ruby",
		ft = "ruby",
	},
	{
		"tpope/vim-rails",
		ft = { "ruby", "eruby", "haml", "slim" },
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
      {"<leader>t", "", desc = "+test"},
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File (Neotest)" },
      { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files (Neotest)" },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest (Neotest)" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary (Neotest)" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch (Neotest)" },
    },
		config = function()
			ensure_d_rspec()
			require("neotest").setup({
				adapters = {
					require("neotest-rspec")({
						rspec_cmd = "/tmp/d-rspec",
					}),
				},
			})
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
		"nvim-treesitter/nvim-treesitter",
		version = false, -- last release is way too old and doesn't work on Windows
		build = ":TSUpdate",
		lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		keys = {
			{ "<c-space>", desc = "Increment Selection" },
			{ "<bs>", desc = "Decrement Selection", mode = "x" },
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
}
