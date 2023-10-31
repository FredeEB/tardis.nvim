<img src="./assets/tardis.webp"/>

Tardis allows you to travel in time (git history) scrolling through each revision of your current file.

Inspired by [git-timemachine](https://github.com/emacsmirror/git-timemachine) which I used extensively when I was using emacs.

# Installation

Like with any other

```lua
{
    'fredeeb/tardis.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = true,
}
```

The default options are

```lua
require('tardis-nvim').setup {
    keymap = {
        next = '<C-j>',       -- next entry in log (older)
        prev = '<C-k>',       -- previous entry in log (newer)
        quit = 'q',           -- quit all
        commit_message = 'm', -- show commit message for current commit in buffer
    },
    commits = 32,             -- max number of commits to read
}
```

# Usage

Using tardis is pretty simple

```
:Tardis
```

This puts you into a new buffer where you can use the keymaps, like described above, to navigate the revisions of the currently open file

# Known issues

See ![issues](https://github.com/FredeEB/tardis.nvim/issues)

# Contributing

Go ahead :)
