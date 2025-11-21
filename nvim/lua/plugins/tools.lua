return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = {
      { "<C-p>",      "<cmd>Telescope find_files theme=ivy disable_devicons=true<CR>", desc = "Find files (ivy)" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>",                                 desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>",                                  desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>",                                    desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>",                                  desc = "Help tags" },
      { "<leader>fo", "<cmd>Telescope oldfiles<CR>",                                   desc = "Recent files" },
      {
        "<leader>fm",
        function()
          local previewers = require("telescope.previewers")
          local pickers = require("telescope.pickers")
          local sorters = require("telescope.sorters")
          local finders = require("telescope.finders")

          local branch = "main"
          if vim.fn.system("git rev-parse --verify main 2>/dev/null") == "" then
            branch = "master"
          end

          local merge_base = vim.fn.system("git merge-base " .. branch .. " HEAD"):gsub("\n", "")
          if merge_base == "" then
            merge_base = branch
          end

          pickers.new({}, {
            prompt_title = "Modified (vs " .. branch .. " base)",
            -- Use separate command calls and combine, avoiding && which stops on empty
            finder = finders.new_oneshot_job({
              "sh", "-c",
              "(git diff --name-only --relative " ..
              merge_base .. "; git ls-files --others --exclude-standard) | sort -u"
            }, {}),
            sorter = sorters.get_fuzzy_file(),
            previewer = previewers.new_termopen_previewer({
              get_command = function(entry)
                if vim.fn.system("git ls-files --error-unmatch " .. vim.fn.shellescape(entry.value) .. " 2>/dev/null") ~= "" then
                  return { "git", "diff", merge_base, "--", entry.value }
                else
                  return { "git", "diff", "--no-index", "/dev/null", entry.value }
                end
              end
            })
          }):find()
        end,
        desc = "Changed files (main)"
      },
      { "<leader>fw", "<cmd>Telescope git_status<CR>", desc = "Git changed files" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules/", "tmp/", "log/" },
          -- path_display = { "smart" },
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },
}
