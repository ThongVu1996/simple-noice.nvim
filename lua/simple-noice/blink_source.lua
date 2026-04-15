local M = {}
local timer = nil

function M.new()
    return setmetatable({}, { __index = M })
end

function M:get_completions(context, callback)
    -- Debounce completion requests to avoid UI jitter on every keystroke
    if timer then timer:stop() end
    
    timer = vim.defer_fn(function()
        -- Get the text before the cursor and remove the seed space
        local cursor_col = context.cursor[2]
        local line_until_cursor = context.line:sub(1, cursor_col)
        local query = line_until_cursor:gsub("^%s+", "")
        
        -- Trigger native Neovim completion for the full command line (including arguments)
        local candidates = vim.fn.getcompletion(query, "cmdline")
        local items = {}
        
        for _, cand in ipairs(candidates) do
            table.insert(items, {
                label = cand,
                kind = vim.lsp.protocol.CompletionItemKind.Event,
                insertText = cand,
            })
        end
        
        callback({
            is_incomplete_backward = false,
            is_incomplete_forward = false,
            items = items,
        })
        timer = nil
    end, 10) -- 10ms debounce: even snappier response
end

return M
