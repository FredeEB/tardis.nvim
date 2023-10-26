local M = {}
local constants = require('tardis-nvim.constants')

function M.trim_root_path(path, root)
    return string.sub(path, string.len(root) + 2, string.len(path))
end

function M.force_delete_buffer(buffer)
    return function() vim.api.nvim_buf_delete(buffer, { force = true }) end
end

function M.build_commit_buffer_name(commit)
    return string.format('%s: #%s', constants.name_prefix, commit)
end

function M.build_buffer_name(filename, commit)
    return string.format('%s: %s #%s', constants.name_prefix, filename, commit)
end

function M.close_session(origin, buffer)
    return function ()
        vim.api.nvim_win_set_buf(0, origin)
        M.force_delete_buffer(buffer)()
    end
end

function M.goto_buffer(index, buffers)
    return function()
        local target = buffers[index].fd
        local current_pos = vim.api.nvim_win_get_cursor(0)
        local target_line_count = vim.api.nvim_buf_line_count(target)
        if current_pos[1] >= target_line_count then
            current_pos[1] = target_line_count
        end
        vim.api.nvim_win_set_buf(0, target)
        vim.api.nvim_win_set_cursor(0, current_pos)
    end
end

return M
