local ses = require('tardis-nvim.session')
local M = {}

---@class TardisSessionManager
---@field sessions TardisSession[]
---@field config TardisConfig
---@field next integer
M.SessionManager = {}

---@param config TardisConfig
function M.SessionManager:init(config)
    self.sessions = {}
    self.config = config
    self.next = 1
end

---@param config TardisConfig
function M.SessionManager:new(config)
    local session_manager = {}
    self.__index = self
    setmetatable(session_manager, self)
    session_manager:init(config)
    return session_manager
end

function M.SessionManager:create_session(args)
    local filename = vim.api.nvim_buf_get_name(0)
    if self.sessions[filename] then
        self.sessions[filename]:goto_buffer(1)
        return
    end
    local session = ses.Session:new(self, args)
    session:goto_buffer(1)
end

---@param session TardisSession
function M.SessionManager:on_session_opened(session)
    self.sessions[session.filename] = session
end

---@param session TardisSession
function M.SessionManager:on_session_closed(session)
    self.sessions[session.filename] = nil
end

return M
