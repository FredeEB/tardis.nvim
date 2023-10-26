local Job = require('plenary.job')

local constants = {
    name_prefix = "Tardis: "
}

local config = {
    keymap = {
        next = '<C-j>',
        prev = '<C-k>',
        quit = 'q',
        commit_message = 'm',
    },
    commits = 32,
}

local function get_git_root()
    return Job:new({
        command = 'git',
        args = { 'rev-parse', '--show-toplevel' },
    }):sync()[1]
end

local function file_at_rev(revision, path, root)
    local relative = string.sub(path, string.len(root) + 2, string.len(path))

    return Job:new {
        command = 'git',
        args = { 'show', string.format('%s:%s', revision, relative)}
    }:sync()
end

local function get_git_commits_for_current_file(file, root)
    local log = Job:new({
        command = 'git',
        args = { '-C', root, 'log', '-n', config.commits, '--pretty=format:%h', '--', file },
    }):sync()
    return log
end

local function force_delete_buffer(buffer)
    return function() vim.api.nvim_buf_delete(buffer, { force = true }) end
end

local function commit_message(commit, root)
    return function ()
        local message = Job:new({
            command = 'git',
            args = { '-C', root, 'show', '--compact-summary', commit }
        }):sync()

        local buffer = vim.api.nvim_create_buf(false, true)
        vim.keymap.set('n', config.keymap.quit, force_delete_buffer(0), { buffer = buffer })
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, message)
        vim.api.nvim_buf_set_option(buffer, 'filetype', 'gitcommit')
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_name(buffer, constants.name_prefix .. 'message')

        local current_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_open_win(buffer, true, { relative = 'win', width = 100, height = #message, bufpos = current_pos })
    end
end

local function goto_buffer(buffers, index)
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

local function setup_keymap(buffers, root, origin)
    for i, buffer_info in ipairs(buffers) do
        local buffer = buffer_info.fd
        local commit = buffer_info.commit
        vim.keymap.set('n', config.keymap.quit, force_delete_buffer(buffer, origin), { buffer = buffer })
        vim.keymap.set('n', config.keymap.commit_message, commit_message(buffers, commit, root), { buffer = buffer })

        if i > 1 then
            vim.keymap.set('n', config.keymap.prev, goto_buffer(buffers, i - 1), { buffer = buffer })
        else
            vim.keymap.set('n', config.keymap.prev, '<Nop>', { buffer = buffer })
        end
        if i < #buffers then
            vim.keymap.set('n', config.keymap.next, goto_buffer(buffers, i + 1), { buffer = buffer })
        else
            vim.keymap.set('n', config.keymap.next, '<Nop>', { buffer = buffer })
        end
    end
end

local function setup_autocommands(buffers, origin)
    local group = vim.api.nvim_create_augroup('Tardis', {})
    for _, buffer in ipairs(buffers) do
        vim.api.nvim_create_autocmd({'BufUnload'}, {
            group = group,
            callback = function()
                vim.api.nvim_del_augroup_by_id(group)
                local to_close = vim.tbl_filter(function(other) return other.fd ~= buffer.fd end, buffers)
                vim.api.nvim_win_set_buf(0, origin)
                for _, buffer_info in ipairs(to_close) do
                    force_delete_buffer(buffer_info.fd)()
                end
            end,
            buffer = buffer.fd,
        })
    end
    return group
end

local function tardis()
    local git_root = get_git_root()

    if not git_root then
        vim.notify('Unable to determine git root', vim.log.levels.WARN)
        return
    end

    local path = vim.fn.expand('%:p')
    local log = get_git_commits_for_current_file(path, git_root)

    if vim.tbl_isempty(log) then
        vim.notify('No previous revisions of this file were found', vim.log.levels.WARN)
        return
    end

    local filetype = vim.bo.filetype
    local origin = vim.api.nvim_get_current_buf()
    local buffers = {}

    for _, commit in ipairs(log) do
        local buffer = vim.api.nvim_create_buf(false, true)
        local file_at_commit = file_at_rev(commit, path, git_root)

        table.insert(buffers, {
            fd = buffer,
            commit = commit
        })

        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, file_at_commit)
        vim.api.nvim_buf_set_option(buffer, 'filetype', filetype)
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_name(buffer, constants.name_prefix .. commit)
    end

    setup_keymap(buffers, git_root, origin)
    setup_autocommands(buffers, origin)
    goto_buffer(buffers, 1)()
end

local function setup(user_config)
    user_config = user_config or {}
    config = vim.tbl_deep_extend('keep', user_config, config)

    vim.api.nvim_create_user_command("Tardis", tardis, {})
end

return {
    setup = setup,
    tardis = tardis,
}

