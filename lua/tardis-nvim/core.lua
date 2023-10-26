local git = require('tardis-nvim.git')
local util = require('tardis-nvim.util')
local constants = require('tardis-nvim.constants')

local M = {}

function M.setup_keymap(root, origin, buffers, keymap)
    for i, buffer_info in ipairs(buffers) do
        local buffer = buffer_info.fd
        local commit = buffer_info.commit
        vim.keymap.set('n', keymap.quit, util.close_session(origin, buffer), { buffer = buffer })
        vim.keymap.set('n', keymap.commit_message, git.get_commit_message(commit, root, keymap), { buffer = buffer })

        if i > 1 then
            vim.keymap.set('n', keymap.prev, util.goto_buffer(i - 1, buffers), { buffer = buffer })
        else
            vim.keymap.set('n', keymap.prev, '<Nop>', { buffer = buffer })
        end
        if i < #buffers then
            vim.keymap.set('n', keymap.next, util.goto_buffer(i + 1, buffers), { buffer = buffer })
        else
            vim.keymap.set('n', keymap.next, '<Nop>', { buffer = buffer })
        end
    end
end

function M.setup_autocmds(buffers)
    local win = vim.api.nvim_get_current_win()
    local group = vim.api.nvim_create_augroup(constants.name_prefix .. win, {})
    for _, buffer in ipairs(buffers) do
        vim.api.nvim_create_autocmd({'BufUnload'}, {
            buffer = buffer.fd,
            callback = function()
                local to_close = vim.tbl_filter(function(other) return other.fd ~= buffer.fd end, buffers)
                vim.api.nvim_del_augroup_by_id(group)
                for _, buffer_info in ipairs(to_close) do
                    util.force_delete_buffer(buffer_info.fd)()
                end
            end,
        })
    end
end

return M
