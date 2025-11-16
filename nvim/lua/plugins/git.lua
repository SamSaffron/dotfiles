return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gwrite", "Gcommit", "Gread" },
    keys = {
      { "<leader>g", "<cmd>Git gui<CR>", desc = "Git GUI" },
    },
  },
  {
    "tpope/vim-rhubarb",
    dependencies = { "tpope/vim-fugitive" },
  },
  {
    "rhysd/git-messenger.vim",
    keys = {
      { "<leader>m", "<Plug>(git-messenger)", desc = "Git Messenger" },
    },
    init = function()
      vim.g.git_messenger_no_default_mappings = true
      vim.g.git_messenger_always_into_popup = true
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  }
}
