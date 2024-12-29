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
    "lambdalisue/gina.vim",
    cmd = "Gina",
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
}
