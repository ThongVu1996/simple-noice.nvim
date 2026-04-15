# simple-noice.nvim

A lightweight, high-performance Neovim plugin that provides a centered floating command line and search UI, along with intelligent system message redirection. 

Designed to be a minimalist alternative to heavy plugins like `noice.nvim`, focusing on aesthetics and speed.

## Features

- **Centered Floating UI**: Beautifully centered command line for `:`, `/`, and `?`.
- **Syntax Highlighting**: Real-time coloring as you type (Vimscript for commands, Regex for search).
- **Virtual Text Icons**: Fixed prefix icons that stay on the left and never break your code.
- **Intelligent Clearing**: Automatically clears the native command line only if a better notification UI is detected.
- **Tab Completion**: Native command completion support inside the floating window.
- **Blink.cmp Integration**: Deep integration for high-speed, correctly positioned command-line completion.
- **Argument Completion**: Suggests not only commands but also their arguments (e.g., health checks for `:checkhealth`).
- **Noice-grade Notifications**: Aggregates multi-line system messages (like `:LspInfo`) into clean, single notification bubbles.
- **Smart Message Redirection**: Captures Neovim errors/warnings and redirects them to your notification plugin (e.g., `snacks.nvim`, `nvim-notify`).

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

## Completion Setup (Blink.cmp)

To enable the "Luxury" completion experience, you **must** configure `blink.cmp` to use the `simple-noice` provider for our custom filetype:

```lua
-- In your blink.cmp configuration
opts = {
    sources = {
        default = { "snippets", "lsp", "path", "buffer" },
        per_filetype = {
            simple_noice_input = { "simple_noice" },
        },
        providers = {
            simple_noice = {
                name = "SimpleNoice",
                module = "simple-noice.blink_source",
                score_offset = 100,
            },
        },
    },
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

Inside the floating window:
- `<CR>`: Accept `blink.cmp` completion item if visible, otherwise execute command.
- `<C-j>`, `<C-k>` or `<Tab>`: Navigate through completion suggestions.
- `<Up>` / `<Down>`: Navigate command history.
- `<Esc>`: Close window / Cancel.

## License

MIT
