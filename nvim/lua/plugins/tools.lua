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
      { "<leader>fw", "<cmd>Telescope git_status<CR>",                                 desc = "Git changed files" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", "tmp", "log" },
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },
}
