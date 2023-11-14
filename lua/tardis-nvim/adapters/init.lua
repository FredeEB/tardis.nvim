local M = {}

---@class TardisAdapter
---@field create_revision_buffer fun(revision: string, parent: TardisSession?): integer
---@field get_revisions_for_current_file fun(parent: TardisSession?): TardisBuffer[]
--- Optional fields
---@field create_revision_message_buffer? fun(parent: TardisSession?)
---@field get_file_at_revision? fun(parent: TardisSession?)
---@field get_revision_under_cursor? fun(parent: TardisSession?)


---@param type string?
---@return TardisAdapter?
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
    vim.notify('No suitable adapter found for current file')
    return nil
end

return M
