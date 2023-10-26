local Job = require('plenary.job')
local util = require('tardis-nvim.util')

local M = {}

function M.get_git_root()
    return Job:new({
        command = 'git',
        args = { 'rev-parse', '--show-toplevel' },
    }):sync()[1]
end

function M.get_file_at_rev(revision, path, root)
    local relative = util.trim_root_path(path, root)

    return Job:new {
        command = 'git',
        args = { 'show', string.format('%s:%s', revision, relative)}
    }:sync()
end

function M.get_git_commits_for_current_file(file, root, commits)
    return Job:new({
        command = 'git',
        args = { '-C', root, 'log', '-n', commits, '--pretty=format:%h', '--', file },
    }):sync()
end

function M.get_commit_message(commit, root, keymap)
    return function ()
        local message = Job:new({
            command = 'git',
            args = { '-C', root, 'show', '--compact-summary', commit }
        }):sync()

        local buffer = vim.api.nvim_create_buf(false, true)
        vim.keymap.set('n', keymap.quit, util.force_delete_buffer(0), { buffer = buffer })
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, message)
        vim.api.nvim_buf_set_option(buffer, 'filetype', 'gitcommit')
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_name(buffer, util.build_commit_buffer_name(commit))

        local current_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_open_win(buffer, true, { relative = 'win', width = 100, height = #message, bufpos = current_pos })
    end
end

return M
