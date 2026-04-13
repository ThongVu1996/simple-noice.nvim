# simple-noice.nvim

A lightweight, high-performance Neovim plugin that provides a centered floating command line and search UI, along with intelligent system message redirection. 

Designed to be a minimalist alternative to heavy plugins like `noice.nvim`, focusing on aesthetics and speed.

## Features

- **Centered Floating UI**: Beautifully centered command line for `:`, `/`, and `?`.
- **Syntax Highlighting**: Real-time coloring as you type (Vimscript for commands, Regex for search).
- **Virtual Text Icons**: Fixed prefix icons that stay on the left and never break your code.
- **Smart Message Redirection**: Captures Neovim errors/warnings and redirects them to your notification plugin (e.g., `snacks.nvim`, `nvim-notify`).
- **Intelligent Clearing**: Automatically clears the native command line only if a better notification UI is detected.
- **Tab Completion**: Native command completion support inside the floating window.

## Installation

Using `lazy.nvim`:

```lua
return {
    "ThongVu1996/simple-noice.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
        require("simple-noice").setup(opts)
    end
}
```

## Configuration

The plugin comes with sensible defaults. You can customize icons, colors, and behavior:

```lua
require("simple-noice").setup({
    width = 60,
    border = "rounded",
    config = {
        cmdline = { 
            title = " Cmdline ", 
            icon = "   ", 
            highlight = "DiagnosticInfo", 
            lang = "vim" 
        },
        search_down = { 
            title = " Search ", 
            icon = "    ", 
            highlight = "DiagnosticWarn", 
            lang = "regex" 
        },
        search_up = { 
            title = " Search ", 
            icon = "    ", 
            highlight = "DiagnosticWarn", 
            lang = "regex" 
        },
    },
    messages = {
        enabled = true,
        highlight = "auto", -- Options: "auto", true, or false
        -- true: Always shows popup notification & clears native cmdline.
        -- false: Never shows popup & never clears cmdline (Native behavior).
        -- "auto": Only shows popup & clears cmdline if a notifier is detected.
    }
})
```

### Key Bindings

By default, calling `.setup()` will automatically map:
- `:` -> Floating Cmdline
- `/` -> Floating Search (Down)
- `?` -> Floating Search (Up)

Inside the floating window:
- `<CR>`: Execute command/search.
- `<Tab>`: Command completion (for `:` mode).
- `<Esc>` or `q`: Close window.

## Transparency & Themes

The plugin uses your theme's `Normal` and `FloatBorder` highlight groups. For the best experience, ensure your theme defines `DiagnosticInfo` and `DiagnosticWarn` colors.

## License

MIT
