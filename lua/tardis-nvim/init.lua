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
        on_stderr = function ()
            vim.notify('Unable to determine git root', vim.log.levels.WARN)
        end,
    }):sync()
end

local function trim_root_path(path, root)
    return string.sub(path, string.len(root) + 2, string.len(path))
end

local function file_at_rev(revision, path, root)
    local relative = trim_root_path(path, root)

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

local function build_commit_buffer_name(commit, buffer)
    return string.format('%s#%s (%s)', constants.name_prefix, commit, buffer)
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
        vim.api.nvim_buf_set_name(buffer, build_commit_buffer_name(commit, buffer))

        local current_pos = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_open_win(buffer, true, { relative = 'win', width = 100, height = #message, bufpos = current_pos })
    end
end

local function quit(origin, buffer)
    return function ()
        vim.api.nvim_win_set_buf(0, origin)
        force_delete_buffer(buffer)()
    end
end

local function goto_buffer(index, buffers)
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

local function setup_keymap(root, origin, buffers)
    for i, buffer_info in ipairs(buffers) do
        local buffer = buffer_info.fd
        local commit = buffer_info.commit
        vim.keymap.set('n', config.keymap.quit, force_delete_buffer(0), { buffer = buffer })
        vim.keymap.set('n', config.keymap.commit_message, commit_message(commit, root), { buffer = buffer })
        vim.keymap.set('n', config.keymap.quit, quit(origin, buffer), { buffer = buffer })

        if i > 1 then
            vim.keymap.set('n', config.keymap.prev, goto_buffer(i - 1, buffers), { buffer = buffer })
        else
            vim.keymap.set('n', config.keymap.prev, '<Nop>', { buffer = buffer })
        end
        if i < #buffers then
            vim.keymap.set('n', config.keymap.next, goto_buffer(i + 1, buffers), { buffer = buffer })
        else
            vim.keymap.set('n', config.keymap.next, '<Nop>', { buffer = buffer })
        end
    end
end

local function setup_autocmds(buffers)
    local win = vim.api.nvim_get_current_win()
    local group = vim.api.nvim_create_augroup('Tardis' .. win, {})
    for _, buffer in ipairs(buffers) do
        local to_close = vim.tbl_filter(function(other) return other.fd ~= buffer.fd end, buffers)
        vim.api.nvim_create_autocmd({'BufDelete'}, {
            buffer = buffer.fd,
            callback = function ()
                vim.api.nvim_del_augroup_by_id(group)
                for _, buffer_info in ipairs(to_close) do
                    force_delete_buffer(buffer_info.fd)()
                end
            end,
        })
    end
end

local function build_buffer_name(filename, commit, buffer)
    return string.format(
        '%s%s #%s (%s)',
        constants.name_prefix,
        filename,
        commit,
        buffer
    )
end

local function tardis()
    local git_root = get_git_root()

    if vim.tbl_isempty(git_root) then
        return
    end

    local path = vim.fn.expand('%:p')
    local log = get_git_commits_for_current_file(path, git_root[1])

    if vim.tbl_isempty(log) then
        vim.notify('No previous revisions of this file were found', vim.log.levels.WARN)
        return
    end

    local buffers = {}
    local filename = vim.fn.expand('%')
    local filetype = vim.bo.filetype
    local origin = vim.api.nvim_get_current_buf()

    for _, commit in ipairs(log) do
        local buffer = vim.api.nvim_create_buf(false, true)
        local file_at_commit = file_at_rev(commit, path, git_root[1])
        local name = build_buffer_name(filename, commit, buffer)

        table.insert(buffers, {
            fd = buffer,
            commit = commit
        })

        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, file_at_commit)
        vim.api.nvim_buf_set_option(buffer, 'filetype', filetype)
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_name(buffer, name)
    end

    setup_autocmds(buffers)
    setup_keymap(git_root[1], origin, buffers)
    goto_buffer(1, buffers)()
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

