local M = {}

---@param type string?
function M.get_adapter(type)
    type = type or 'git'
    local ok, adapter = pcall(require, 'tardis-nvim.adapters.' .. type)
    if ok then
        return adapter
    end
    ok, adapter = pcall(require, type)
    if ok then
        return adapter
    end
end

return M
