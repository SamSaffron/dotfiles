local api = vim.api

-- Create autogroup
local group = api.nvim_create_augroup('VimrcGroup', { clear = true })

api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = group,
    pattern = '*',
    command = 'match ExtraWhitespace /\\s\\+$/',
})

api.nvim_create_autocmd({ 'InsertEnter' }, {
    group = group,
    pattern = '*',
    command = 'match ExtraWhitespace /\\s\\+\\%#\\@<!$/',
})

api.nvim_create_autocmd({ 'InsertLeave' }, {
    group = group,
    pattern = '*',
    command = 'match ExtraWhitespace /\\s\\+$/',
})

api.nvim_create_autocmd({ 'BufWinLeave' }, {
    group = group,
    pattern = '*',
    callback = function()
        vim.fn.clearmatches()
    end,
})

-- Search highlighting behavior
api.nvim_create_autocmd({ 'CmdlineLeave' }, {
    group = group,
    pattern = '[/\\?]',
    command = 'set nohlsearch',
})

api.nvim_create_autocmd({ 'CmdlineEnter' }, {
    group = group,
    pattern = '[/,\\?]',
    command = 'set hlsearch',
})

-- File type specific settings
api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
    pattern = { 'c', 'cpp' },
    callback = function()
        -- MRI Indent settings
        vim.bo.cindent = true
        vim.bo.expandtab = false
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.tabstop = 8
        vim.bo.textwidth = 80
        vim.opt_local.cinoptions = '(0,t0'
    end,
})

api.nvim_create_autocmd({ 'FileType' }, {
    group = group,
    pattern = 'puppet',
    callback = function()
        -- Puppet indent settings
        vim.bo.expandtab = false
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.tabstop = 4
        vim.bo.textwidth = 80
    end,
})

-- Filetype detection
api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = 'Guardfile',
    command = 'set filetype=ruby',
})

api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = '*.pill',
    command = 'set filetype=ruby',
})

api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = '*.es6',
    command = 'set filetype=javascript',
})

api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = '*.es6.erb',
    command = 'set filetype=javascript',
})

api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    group = group,
    pattern = '*.pp',
    command = 'set filetype=puppet',
})

api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*',
    callback = function()
        local function file_exists(path)
            local f = io.open(path, "r")
            if f ~= nil then
                io.close(f)
                return true
            else
                return false
            end
        end

        local notify = vim.fn.getcwd() .. "/bin/notify_file_change"
        
        if not file_exists(notify) then
            -- Try to find it in Rails app path
            if vim.fn.exists('*rails#app') == 1 then
                local root = vim.fn.rails.app().path()
                notify = root .. "/bin/notify_file_change"
            end
        end
        
        if not file_exists(notify) then
            notify = vim.fn.getcwd() .. "../../bin/notify_file_change"
        end
        
        if file_exists(notify) and vim.fn.executable('socat') == 1 then
            vim.fn.system(string.format(
                "%s %s %s",
                notify,
                vim.fn.expand("%:p"),
                vim.fn.line(".")
            ))
        end
    end,
})

