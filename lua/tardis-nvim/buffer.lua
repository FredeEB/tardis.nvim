local M = {}

---@class TardisBuffer
---@field fd integer
---@field revision string
M.Buffer = {}

---@param revision string
---@param fd integer?
---@return TardisBuffer
function M.Buffer:new(revision, fd)
    local buffer = {}
    self.__index = self

    buffer.revision = revision
    buffer.fd = fd

    return setmetatable(buffer, self)
end

function M.Buffer:focus()
    local current_pos = vim.api.nvim_win_get_cursor(0)
    local target_line_count = vim.api.nvim_buf_line_count(self.fd)
    if current_pos[1] >= target_line_count then
        current_pos[1] = target_line_count
    end
    vim.api.nvim_win_set_buf(0, self.fd)
    vim.api.nvim_win_set_cursor(0, current_pos)
end

---@param fd integer
function M.Buffer:open(fd)
    if self.fd then
        self:close(true)
    end
    self.fd = fd
end

---@param force boolean?
function M.Buffer:close(force)
    if not self.fd then return end
    force = force or true
    vim.api.nvim_buf_delete(self.fd, { force = force })
    self.fd = nil
end

return M
