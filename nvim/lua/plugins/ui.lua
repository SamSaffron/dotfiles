return {
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- very annoying but copilot will not find gjs files without this
      require("plenary.filetype").add_file("gjs")

      local log = require("plenary.log")
      local original_new = log.new

      log.new = function(config, standalone)
        local merged_config = vim.tbl_deep_extend("force", { use_console = false }, config or {})
        return original_new(merged_config, standalone)
      end
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      words = { enabled = true },
      notifier = { enabled = true },
      bigfile = { enabled = true },
      debug = { enabled = true },
      picker = {
        enabled = true,
        sources = {
          grep = {
            cmd = "rg", -- Explicitly use ripgrep
            args = {
              "--color=never",
              "--no-heading",
              "--with-filename",
              "--line-number",
              "--column",
              "--smart-case",
              "--hidden",      -- Include hidden files
              "--glob=!.git/", -- Exclude .git directory
              -- Add any other ripgrep flags you prefer
            },
            live = true, -- Disable live search for the quickfix workflow
          },
        },
        layouts = {
          quickfix_modal = {
            -- preview = false, -- No preview
            layout = {
              backdrop = false,
              width = 0.5,  -- Half screen width
              height = 0.1, -- Just enough for input
              border = "rounded",
              box = "vertical",
              { win = "input", height = 1, border = "none" },
            },
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>un", function() Snacks.notifier.hide() end,         desc = "Dismiss All Notifications" },
      {
        "<leader>fj",
        function()
          Snacks.picker.pick({
            source = "grep",
            live = true,
            focus = "input",
            layout = "quickfix_modal", -- Use our custom minimal layout
            confirm = function(picker, item)
              require("snacks.picker.actions").qflist(picker)
              picker:close()
            end,
          })
        end,
        desc = "Grep to Quickfix"
      },
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      require("gruvbox").setup({
        contrast = "hard",
        italic = {
          strings = false,
          comments = false,
          emphasis = false,
        },
      })
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "uga-rosa/ccc.nvim",
    config = function()
      require("ccc").setup({
        highlighter = {
          auto_enable = true,
          lsp = true,
        },
      })
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      require("nvim-web-devicons").setup({
        color_icons = true,
        default = true,
        strict = true,
        variant = "dark",
        override = (function()
          -- technically we need to also fix the name, so
          -- rake is now white, but Rb is red
          local files = { "rb", "rakefile", "Gemfile", "Brewfile" }
          local result = {}
          for _, ext in ipairs(files) do
            result[ext] = {
              icon = "",
              color = "#bb2222",
              cterm_color = "52",
              name = "Rb",
            }
          end
          return result
        end)(),
      })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false,
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    opts = {
      filesystem = {
        filtered_items = {
          hide_gitignored = true,
          always_show_by_pattern = {
            "*plugins*",
          },
        },
      },
    },
    keys = {
      {
        "<leader>f",
        function()
          require("neo-tree.command").execute({
            action = "show",
            reveal = true,
          })
        end,
        desc = "Find current file",
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
  {
    "cuducos/yaml.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim", -- optional
      "folke/snacks.nvim",             -- optional
    },
    keys = {
      {
        "<leader>fy",
        function()
          require("yaml_nvim").snacks()
        end,
        desc = "Find YAML Key",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local old_position
      local old_result

      local function get_yaml_key()
        if vim.bo.filetype ~= "yaml" then
          return ""
        end

        local position = vim.api.nvim_win_get_cursor(0)

        if old_position and old_position[1] == position[1] and old_position[2] == position[2] then
          return old_result
        end

        local result = require("yaml_nvim").get_yaml_key()

        old_position = position
        old_result = result

        return result or ""
      end
      require("lualine").setup({
        sections = {
          lualine_x = { get_yaml_key, "encoding", "fileformat", "filetype" },
        },
      })
    end,
  },
  {
    "b0o/incline.nvim",
    config = function()
      require("incline").setup()
    end,
    -- Optional: Lazy load Incline
    event = "VeryLazy",
  },
}
