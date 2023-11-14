local util = require('tardis-nvim.util')
local git = require('tardis-nvim.git')
local core = require('tardis-nvim.core')
local cfg = require('tardis-nvim.user_config')
local sm = require('tardis-nvim.session_manager')

Tardis = {
    session_manager = nil
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
---@param user_config TardisPartialConfig?
function Tardis.setup(user_config)
    if Tardis.session_manager then return end
    local config = cfg.Config:new(user_config)
    Tardis.session_manager = sm.SessionManager:new(config)
end

function Tardis.tardis()
    Tardis.session_manager:create_session()
end

return Tardis
