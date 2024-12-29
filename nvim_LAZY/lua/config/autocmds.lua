-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function notify_file_change()
  local notify = vim.fn.getcwd() .. "/bin/notify_file_change"

  if vim.fn.executable(notify) == 0 then
    -- Assuming you're using a Rails plugin that provides similar functionality
    -- You might need to adjust this part based on your actual Rails setup
    local root = vim.fn.exists("*rails#app") == 1 and vim.fn.rails.app().path() or ""
    notify = root .. "/bin/notify_file_change"
  end

  if vim.fn.executable(notify) == 0 then
    notify = vim.fn.getcwd() .. "../../bin/notify_file_change"
  end

  if vim.fn.executable(notify) == 1 then
    if vim.fn.executable("socat") == 1 then
      local cmd = notify .. " " .. vim.fn.expand("%:p") .. " " .. vim.fn.line(".")
      vim.fn.system(cmd)
    end
  end
end

-- vim.api.nvim_create_autocmd("BufWritePost", {
--   pattern = "*",
--   callback = function()
--     notify_file_change()
--   end,
-- })
--



vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.documentHighlightProvider = false
    end
  end,
})
