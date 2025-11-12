return {
  -- {
  -- 	{
  -- 		"codota/tabnine-nvim",
  -- 		build = "./dl_binaries.sh",
  -- 		init = function()
  -- 			require("tabnine").setup({
  -- 				disable_auto_comment = true,
  -- 				accept_keymap = "<Tab>",
  -- 				dismiss_keymap = "<C-]>",
  -- 				debounce_ms = 800,
  -- 				suggestion_color = { gui = "#808080", cterm = 244 },
  -- 				exclude_filetypes = { "TelescopePrompt", "NvimTree" },
  -- 				log_file_path = nil, -- absolute path to Tabnine log file
  -- 				ignore_certificate_errors = false,
  -- 				-- workspace_folders = {
  -- 				--   paths = { "/your/project" },
  -- 				--   get_paths = function()
  -- 				--       return { "/your/project" }
  -- 				--   end,
  -- 				-- },
  -- 			})
  -- 		end,
  -- 	},
  -- },
  -- {
  --   "CopilotC-Nvim/CopilotChat.nvim",
  --   -- dir = "/home/sam/Source/CopilotChat.nvim",
  --   -- name = "ccchat",
  --   dependencies = {
  --     { "github/copilot.vim" },
  --     { "nvim-lua/plenary.nvim" }, -- for curl, log and async functions
  --   },
  --   build = "make tiktoken",       -- Only on MacOS or Linux
  --   init = function()
  --     -- copilot is annoying in copilot chat
  --     vim.api.nvim_create_autocmd("BufEnter", {
  --       pattern = "copilot-*",
  --       callback = function()
  --         vim.b.copilot_enabled = false
  --       end,
  --     })
  --     -- errors are also super annoying
  --     vim.api.nvim_create_autocmd("FileType", {
  --       pattern = "copilot-chat",
  --       callback = function()
  --         vim.cmd("highlight Error NONE")
  --       end,
  --     })
  --   end,
  --   opts = {
  --     model = "claude-sonnet-4.5",
  --     -- model = "gpt-4.1",
  --     -- model = "gpt-5",
  --     debug = false,
  --     auto_insert_mode = true,
  --     insert_at_end = false,
  --     chat_autocomplete = false, -- this is very annoying just lean on Tab
  --     highlight_selection = false,
  --     highlight_headers = true,
  --     headers = {
  --       user = "Sam ",
  --     },
  --     seperator = "---",
  --     error_header = "> [!ERROR] Error",
  --     mappings = {
  --       complete = {
  --         insert = "<Tab>",
  --       },
  --     },
  --     functions = {
  --       file = {
  --         group = "copilot",
  --         uri = "file://{path}",
  --         description = "Reads content from a specified file path",
  --         schema = {
  --           type = "object",
  --           required = { "path" },
  --           properties = {
  --             path = {
  --               type = "string",
  --               description = "Path to file to include in chat context.",
  --               enum = function(source)
  --                 local chat_winid = vim.api.nvim_get_current_win()
  --                 local async = require("plenary.async")
  --                 local fn = async.wrap(function(callback)
  --                   local telescope = require("telescope.builtin")
  --                   local actions = require("telescope.actions")
  --                   local action_state = require("telescope.actions.state")

  --                   telescope.find_files({
  --                     cwd = source.cwd(), -- Use source working directory
  --                     attach_mappings = function(prompt_bufnr)
  --                       actions.select_default:replace(function()
  --                         actions.close(prompt_bufnr)
  --                         local selection = action_state.get_selected_entry()

  --                         -- Return focus to the chat window
  --                         if vim.api.nvim_win_is_valid(chat_winid) then
  --                           vim.api.nvim_set_current_win(chat_winid)
  --                           vim.cmd("normal! a")
  --                         end

  --                         vim.schedule(function()
  --                           callback(selection)
  --                         end)
  --                       end)
  --                       return true
  --                     end,
  --                   })
  --                 end, 1)

  --                 return fn()
  --               end,
  --             },
  --           },
  --         },
  --         resolve = function(input, source)
  --           local utils = require("CopilotChat.utils")
  --           local resources = require("CopilotChat.resources")

  --           -- Handle relative path - make it absolute for reading
  --           local full_path = input.path
  --           if not vim.startswith(full_path, "/") then
  --             full_path = source.cwd() .. "/" .. input.path
  --           end

  --           utils.schedule_main()
  --           local data, mimetype = resources.get_file(full_path)
  --           if not data then
  --             error("File not found: " .. input.path)
  --           end

  --           return {
  --             {
  --               uri = "file://" .. input.path, -- Keep relative path in URI
  --               mimetype = mimetype,
  --               data = data,
  --             },
  --           }
  --         end,
  --       },
  --       gitmain = {
  --         group = "copilot",
  --         description = "Get diff against main branch",
  --         uri = "gitmain://diff",
  --         schema = {
  --           type = "object",
  --           required = {},
  --           properties = {},
  --         },
  --         resolve = function()
  --           local utils = require("CopilotChat.utils")
  --           utils.schedule_main()
  --           -- Get diff against main branch including staged and unstaged changes
  --           local cmd = "git diff main HEAD && git diff"
  --           local output = vim.fn.system(cmd)
  --           return {
  --             {
  --               uri = "gitmain://diff",
  --               mimetype = "text/x-diff",
  --               data = output,
  --             },
  --           }
  --         end,
  --       },
  --     },
  --   },
  --   keys = {
  --     {
  --       "<leader>p",
  --       "<cmd>CopilotChatToggle<cr>",
  --       desc = "Toggle Copilot Chat",
  --       mode = { "n", "v" },
  --     },
  --     {
  --       "<leader>c",
  --       function()
  --         local visualmode = vim.fn.mode()
  --         local input = vim.fn.input("Quick Chat: ")
  --         if input ~= "" then
  --           local chat = require("CopilotChat")
  --           local select = require("CopilotChat.select")

  --           local selection
  --           -- if we have a line in visual mode then select it
  --           if visualmode == "V" or visualmode == "v" or visualmode == "\22" then
  --             selection = select.visual
  --           else
  --             selection = select.buffer
  --           end

  --           chat.ask(input, { selection = selection })
  --         end
  --       end,
  --       mode = { "n", "v" },
  --       desc = "Start Copilot Chat",
  --     },
  --   },
  -- },
  { "nvim-treesitter-textobjects", branch = "main", lazy = true },
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.cmd("Copilot")
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap("i", "<Tab>", 'copilot#Accept("<Tab>")', { silent = true, expr = true })
      vim.api.nvim_set_keymap("i", "<C-e>", "copilot#Dismiss()", { silent = true, expr = true })
    end,
  },
  {
    "folke/sidekick.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
    },
    keys = {
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-.>",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function() require("sidekick.cli").toggle() end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function() require("sidekick.cli").select() end,
        -- Or to select only installed tools:
        -- require("sidekick.cli").select({ filter = { installed = true } })
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function() require("sidekick.cli").close() end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function() require("sidekick.cli").send({ msg = "{this}" }) end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function() require("sidekick.cli").send({ msg = "{file}" }) end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function() require("sidekick.cli").send({ msg = "{selection}" }) end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function() require("sidekick.cli").prompt() end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<leader>ac",
        function() require("sidekick.cli").toggle({ name = "cursor", focus = true }) end,
        desc = "Sidekick Toggle Cursor",
      },
    },
  }
  -- {
  -- 	"olimorris/codecompanion.nvim",
  -- 	-- dir = "/home/sam/Source/codecompanion.nvim",
  -- 	init = function()
  -- 		-- copilot is annoying in copilot chat
  -- 		vim.api.nvim_create_autocmd("BufEnter", {
  -- 			pattern = "*\\[CodeCompanion\\]*",
  -- 			callback = function()
  -- 				vim.b.copilot_enabled = false
  -- 			end,
  -- 		})
  -- 		-- errors are also super annoying
  -- 		vim.api.nvim_create_autocmd("FileType", {
  -- 			pattern = "*\\[CodeCompanion\\]*",
  -- 			callback = function()
  -- 				vim.cmd("highlight Error NONE")
  -- 			end,
  -- 		})
  -- 	end,

  -- 	keys = {
  -- 		{
  -- 			"<leader>p",
  -- 			"<cmd>CodeCompanionChat toggle<cr>",
  -- 			desc = "Toggle Copilot Chat",
  -- 			mode = { "n", "v" },
  -- 		},
  -- 	},
  -- 	config = function()
  -- 		require("codecompanion").setup({
  -- 			opts = {
  -- 				system_prompt = function(opts)
  -- 					local language = opts.language or "English"
  -- 					return string.format(
  -- 						[[
  -- You are a technical advisor to an experienced software engineer working in Neovim.

  -- Assume advanced programming knowledge and familiarity with software engineering principles.

  -- When responding:
  -- - Prioritize technical depth and architectural implications
  -- - Focus on edge cases, performance considerations, and scalability
  -- - Discuss trade-offs between different approaches when relevant
  -- - Skip explanations of standard patterns or basic concepts unless requested
  -- - Reference advanced patterns, algorithms, or design principles when applicable
  -- - Prefer showing code over explaining it unless analysis is specifically requested
  -- - All non-code responses in %s

  -- For code improvement:
  -- - Focus on optimizations beyond obvious refactorings
  -- - Highlight potential concurrency issues, memory management concerns, or runtime complexity
  -- - Consider backwards compatibility, maintainability, and testing implications
  -- - Suggest modern idioms and language features when appropriate

  -- For architecture discussions:
  -- - Consider system boundaries, coupling concerns, and dependency management
  -- - Address long-term maintenance and extensibility implications
  -- - Discuss relevant architectural patterns without overexplaining them

  -- Deliver responses with professional brevity. Skip preamble and unnecessary context.
  -- ]],
  -- 						language
  -- 					)
  -- 				end,
  -- 			},
  -- 			display = {
  -- 				chat = {
  -- 					intro_message = "Press ? for options",
  -- 					show_token_count = true, -- Show the token count for each response?
  -- 					start_in_insert_mode = true, -- Open the chat buffer in insert mode?
  -- 					window = {
  -- 						layout = "vertical",
  -- 						position = "right",
  -- 						relative = "editor",
  -- 						full_height = true,
  -- 					},
  -- 				},
  -- 			},
  -- 			strategies = {
  -- 				chat = {
  -- 					roles = {
  -- 						llm = function(adapter)
  -- 							local model_name = ""
  -- 							-- Try to get the model name from the adapter
  -- 							if adapter.schema and adapter.schema.model and adapter.schema.model.default then
  -- 								local model = adapter.schema.model.default
  -- 								if type(model) == "function" then
  -- 									model = model(adapter)
  -- 								end
  -- 								model_name = " - " .. model
  -- 							end

  -- 							return "Model (" .. adapter.formatted_name .. model_name .. ")"
  -- 						end,
  -- 					},
  -- 					slash_commands = {
  -- 						["file"] = {
  -- 							-- Location to the slash command in CodeCompanion
  -- 							callback = "strategies.chat.slash_commands.file",
  -- 							description = "Select a file using Telescope",
  -- 							opts = {
  -- 								provider = "telescope", -- Other options include 'default', 'mini_pick', 'fzf_lua', snacks
  -- 								contains_code = true,
  -- 							},
  -- 						},
  -- 					},
  -- 				},
  -- 			},
  -- 		})
  -- 	end,
  -- 	dependencies = {
  -- 		"nvim-lua/plenary.nvim",
  -- 		"nvim-treesitter/nvim-treesitter",
  -- 	},
  -- },
  -- {
  -- 	"GeorgesAlkhouri/nvim-aider",
  -- 	cmd = {
  -- 		"AiderTerminalToggle",
  -- 		"AiderHealth",
  -- 	},
  -- 	keys = {
  -- 		{ "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
  -- 		{ "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
  -- 		{ "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
  -- 		{ "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
  -- 		{ "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
  -- 		{ "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
  -- 		{ "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
  -- 	},
  -- 	dependencies = {
  -- 		"folke/snacks.nvim",
  -- 		"nvim-telescope/telescope.nvim",
  -- 	},
  -- 	config = true,
  -- },
  -- {
  -- 	"yetone/avante.nvim",
  -- 	event = "VeryLazy",
  -- 	lazy = false,
  -- 	version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  -- 	opts = {
  -- 		-- add any opts here
  -- 	},
  -- 	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- 	build = "make",
  -- 	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  -- 	dependencies = {
  -- 		"stevearc/dressing.nvim",
  -- 		"nvim-lua/plenary.nvim",
  -- 		"MunifTanjim/nui.nvim",
  -- 		--- The below dependencies are optional,
  -- 		"echasnovski/mini.pick", -- for file_selector provider mini.pick
  -- 		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
  -- 		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
  -- 		"ibhagwan/fzf-lua", -- for file_selector provider fzf
  -- 		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  -- 		"zbirenbaum/copilot.lua", -- for providers='copilot'
  -- 		{
  -- 			-- support for image pasting
  -- 			"HakonHarnes/img-clip.nvim",
  -- 			event = "VeryLazy",
  -- 			opts = {
  -- 				-- recommended settings
  -- 				default = {
  -- 					embed_image_as_base64 = false,
  -- 					prompt_for_file_name = false,
  -- 					drag_and_drop = {
  -- 						insert_mode = true,
  -- 					},
  -- 					-- required for Windows users
  -- 					use_absolute_path = true,
  -- 				},
  -- 			},
  -- 		},
  -- 	},
  -- },
}
