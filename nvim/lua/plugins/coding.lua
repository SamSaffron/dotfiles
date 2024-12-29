return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
  },
  {
    "dense-analysis/ale",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.g.ale_linters = {
        ruby = { 'ruby', 'rubocop' },
        javascript = { 'eslint', 'embertemplatelint' },
        handlebars = { 'embertemplatelint', 'prettier' },
        glimmer = { 'eslint', 'embertemplatelint' },
      }
      vim.g.ale_fixers = {
        ruby = { 'syntax_tree' },
        ['javascript.glimmer'] = { 'eslint', 'prettier' },
        handlebars = { 'prettier' },
        ['html.handlebars'] = { 'prettier' },
        scss = { 'prettier' },
        javascript = { 'eslint', 'prettier' },
      }
      vim.g.ale_fix_on_save = 0
      vim.g.ale_lint_on_text_changed = 'never'
      vim.g.ale_lint_on_insert_leave = 0
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
}
