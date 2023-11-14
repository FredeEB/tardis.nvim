local M = {}

M.Session = {}

function M.Session:new(s)
    local buffers = {}
    s = s or {
        id = 0,
        parent = nil,
        buffers = buffers,
    }
    setmetatable(s, self)
    self.__index = self
    return s
end

function M.Session:close()
    for _, buffer in ipairs(self.buffers) do
        vim.api.nvim_buf_delete(buffer, { force = true })
    end
    if self.parent then
        self.parent:on_session_close(self)
    end
end

end

end

end

return M
