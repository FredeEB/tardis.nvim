local util = require('tardis-nvim.util')
local git = require('tardis-nvim.git')
local core = require('tardis-nvim.core')

local config = {
    keymap = {
        next = '<C-j>',
        prev = '<C-k>',
        quit = 'q',
        commit_message = '<C-m>',
    },
    commits = 256,
}

local function tardis()
    local git_root = git.get_git_root()

    if not git_root then
        vim.notify('Unable to determine git root', vim.log.levels.WARN)
        return
    end

    local path = vim.fn.expand('%:p')
    local log = git.get_git_commits_for_current_file(path, git_root, config.commits)

    if vim.tbl_isempty(log) then
        vim.notify('No previous revisions of this file were found', vim.log.levels.WARN)
        return
    end

    local buffers = {}
    local filename = vim.fn.expand('%')
    local filetype = vim.bo.filetype
    local origin = vim.api.nvim_get_current_buf()

    for _, commit in ipairs(log) do
        local buffer = vim.api.nvim_create_buf(false, true)
        local file_at_commit = git.get_file_at_rev(commit, path, git_root)
        local name = util.build_buffer_name(filename, commit)

        table.insert(buffers, {
            fd = buffer,
            commit = commit
        })

        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, file_at_commit)
        vim.api.nvim_buf_set_option(buffer, 'filetype', filetype)
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_name(buffer, name)
    end

    core.setup_autocmds(buffers)
    core.setup_keymap(git_root, origin, buffers, config.keymap)
    util.goto_buffer(1, buffers)()
end

local function setup(user_config)
    user_config = user_config or {}
    config = vim.tbl_deep_extend('keep', user_config, config)

    vim.api.nvim_create_user_command("Tardis", tardis, {})
end

return {
    setup = setup,
    tardis = tardis,
}

