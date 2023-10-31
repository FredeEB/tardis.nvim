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

M.SessionManager = { }

function M.SessionManager:new(s)
    s = s or {
        next = 1,
        sessions = {},
    }
    self.__index = self
    setmetatable(s, self)
    return s
end

function M.SessionManager:create_session(buffers)
    assert(#buffers)
    local id = self.next
    self.next = self.next + 1
    local session = M.Session:new({ id = id, parent = self, buffers = buffers })
    table.insert(self.sessions, id, session)
    return session
end

function M.SessionManager:on_session_close(session)
    table.remove(self.sessions, session.id)
end

return M
