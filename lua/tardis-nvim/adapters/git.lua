local Job = require('plenary.job')
local util = require('tardis-nvim.util')

local M = {}

---@param root string
---@param ... string
---@return string[]
local function git(root, ...)
    local output = Job:new {
        command = 'git',
        args = { '-C', root, ... },
        on_stderr = function(_, msg)
            vim.print("Tardis: git failed: " .. msg, vim.log.levels.WARN)
        end
    }:sync()
    return output
end

---@param path string
---@return string
local function get_git_file_path(path)
    local root = util.dirname(path)
    return git(root, 'ls-files', '--full-name', path)[1]
end

---@param revision TardisRevision
---@param parent TardisSession
---@return string[]
function M.get_file_at_revision(revision, parent)
    local root = util.dirname(parent.path)
    local file = get_git_file_path(parent.path)
    return git(root, 'show', string.format('%s:%s', revision, file))
end

---@param parent TardisSession
---@return string
function M.get_revision_under_cursor(parent)
    local root = util.dirname(parent.path)
    local line, _ = vim.api.nvim_win_get_cursor(0)
    local blame_line = git(root, 'blame', '-L', line)[1]
    return vim.split(blame_line, ' ', {})[1]
end

---@param parent TardisSession
---@return TardisRevision[]
function M.get_revisions_for_current_file(parent)
    local root = util.dirname(parent.path)
    local file = get_git_file_path(parent.path)
    return git(root, 'log', '-n', parent.parent.config.settings.max_revisions, '--pretty=format:%h', '--', file)
end

---@param revision TardisRevision
---@param parent TardisSession
function M.create_revision_buffer(revision, parent)
    local fd = vim.api.nvim_create_buf(false, true)
    local file_at_revision = M.get_file_at_revision(revision, parent)

    vim.api.nvim_buf_set_lines(fd, 0, -1, false, file_at_revision)
    vim.api.nvim_buf_set_option(fd, 'filetype', parent.filetype)
    vim.api.nvim_buf_set_option(fd, 'readonly', true)

    return fd
end

---@param path string
---@param parent TardisBuffer
function M.create_revision_message_buffer(path, parent)
    local root = util.dirname(path)
    local message = git(root, 'show', '--compact-summary', parent.revision)

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, message)
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'gitrevision')
    vim.api.nvim_buf_set_option(buffer, 'readonly', true)
    vim.api.nvim_buf_set_name(buffer, "revision message")

    local current_ui = vim.api.nvim_list_uis()[1]
    if not current_ui then
        error("no ui found")
    end
    vim.api.nvim_open_win(buffer, false, {
        relative = 'win',
        anchor = 'NE',
        width = 100,
        height = #message,
        row = 0,
        col = current_ui.width,
    })
end

return M
