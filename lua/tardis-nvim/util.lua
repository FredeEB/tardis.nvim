local M = {}

function M.dirname(path)
    local str = string.gsub(path, '(.*/)(.*)', '%1')
    if str == path then
        return '.'
    end
    return str
end

function M.basename(path)
    return string.gsub(path, '(.*/)(.*)', '%2')
end

return M
