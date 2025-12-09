-- Simple test runner: opens a right panel and runs tests
-- Supports: bin/rspec (Ruby), with dv container detection

local M = {}

-- dv path constants
local DV_LOCAL_PREFIX = "/home/sam/.local/share/dv/discourse_src"
local DV_CONTAINER_PREFIX = "/var/www/discourse"

-- Check if current file is in a dv-managed directory
local function is_dv_path(filepath)
  return filepath:match("/%.local/share/dv/") ~= nil
end

-- Convert local dv path to container-relative path
local function to_container_path(filepath)
  -- /home/sam/.local/share/dv/discourse_src/plugins/foo/spec/bar.rb
  -- becomes: ./plugins/foo/spec/bar.rb
  local relative = filepath:gsub("^" .. DV_LOCAL_PREFIX, ".")
  return relative
end

-- Build the rspec command based on file location
local function build_rspec_cmd(filepath, line)
  local target
  local use_dv = is_dv_path(filepath)

  if use_dv then
    target = to_container_path(filepath)
  else
    target = filepath
  end

  if line then
    target = target .. ":" .. line
  end

  if use_dv then
    return string.format("dv run -- bin/rspec %s", target)
  else
    return string.format("bin/rspec %s", target)
  end
end

-- Track the test runner buffer and window
local test_buf = nil
local test_win = nil

-- Open a vertical split on the right and run the command
local function run_in_panel(cmd)
  local current_win = vim.api.nvim_get_current_win()

  -- Kill old buffer first if it exists
  if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
    pcall(function()
      local job_id = vim.b[test_buf].terminal_job_id
      if job_id then vim.fn.jobstop(job_id) end
    end)
    vim.api.nvim_buf_delete(test_buf, { force = true })
    test_buf = nil
  end

  -- Check if test window still exists (buffer delete may have closed it)
  local win_valid = test_win and vim.api.nvim_win_is_valid(test_win)

  if win_valid then
    vim.api.nvim_set_current_win(test_win)
  else
    vim.cmd("botright vnew")
    vim.cmd("vertical resize 80")
    test_win = vim.api.nvim_get_current_win()
  end

  -- Create fresh buffer for terminal
  test_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(test_win, test_buf)

  -- Run the command
  vim.fn.termopen(cmd, {
    on_exit = function(_, _, _)
      -- Delay to let nvim add the "[Process exited]" message
      vim.defer_fn(function()
        if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
          vim.bo[test_buf].modifiable = true
          -- Find and delete the line containing "[Process exited"
          local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
          for i = #lines, 1, -1 do
            if lines[i]:match("%[Process exited") then
              vim.api.nvim_buf_set_lines(test_buf, i - 1, i, false, {})
              break
            end
          end
          vim.bo[test_buf].modifiable = false
          vim.bo[test_buf].modified = false
        end
      end, 10)
    end,
  })

  -- Return focus to original window
  vim.api.nvim_set_current_win(current_win)
end

-- Build the qunit command for javascript
local function build_qunit_cmd(filepath)
  local target
  if is_dv_path(filepath) then
    target = to_container_path(filepath)
    return string.format("dv run -- bin/qunit %s", target)
  else
    return string.format("bin/qunit %s", filepath)
  end
end

-- Run all tests in current file
function M.run_file()
  local filepath = vim.fn.expand("%:p")
  local ft = vim.bo.filetype

  if ft == "ruby" then
    run_in_panel(build_rspec_cmd(filepath, nil))
  elseif ft == "javascript" then
    run_in_panel(build_qunit_cmd(filepath))
  else
    vim.notify("No test runner for filetype: " .. ft, vim.log.levels.WARN)
  end
end

-- Run test nearest to current line
function M.run_nearest()
  local filepath = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local ft = vim.bo.filetype

  if ft == "ruby" then
    run_in_panel(build_rspec_cmd(filepath, line))
  elseif ft == "javascript" then
    -- qunit doesn't support line numbers, just run file
    run_in_panel(build_qunit_cmd(filepath))
  else
    vim.notify("No test runner for filetype: " .. ft, vim.log.levels.WARN)
  end
end

-- Close the test buffer and window
function M.close()
  if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
    pcall(function()
      local job_id = vim.b[test_buf].terminal_job_id
      if job_id then vim.fn.jobstop(job_id) end
    end)
    vim.api.nvim_buf_delete(test_buf, { force = true })
    test_buf = nil
    test_win = nil
  end
end

-- Setup keymaps
function M.setup()
  vim.keymap.set("n", "<leader>tt", M.run_file, { desc = "Run tests in file" })
  vim.keymap.set("n", "<leader>tr", M.run_nearest, { desc = "Run test near cursor" })
  vim.keymap.set("n", "<leader>tx", M.close, { desc = "Close test buffer" })
end

return M
