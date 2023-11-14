local cfg = require('tardis-nvim.user_config')
local sm = require('tardis-nvim.session_manager')

Tardis = {
    session_manager = nil
}

---@param user_config TardisPartialConfig?
function Tardis.setup(user_config)
    if Tardis.session_manager then
        vim.notify('tardis-nvim.setup called twice', vim.log.levels.WARN)
        return
    end
    local config = cfg.Config:new(user_config)
    Tardis.session_manager = sm.SessionManager:new(config)
    vim.api.nvim_create_user_command('Tardis', Tardis.tardis, {})
end

function Tardis.tardis()
    Tardis.session_manager:create_session()
end

return Tardis
