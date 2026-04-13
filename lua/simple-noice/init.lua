local M = {}

-- Default configuration
M.defaults = {
	width = 60,
	border = "rounded",
	config = {
		cmdline = { title = " Cmdline ", icon = "   ", highlight = "DiagnosticInfo", lang = "vim" },
		search_down = { title = " Search ", icon = "    ", highlight = "DiagnosticWarn", lang = "regex" },
		search_up = { title = " Search ", icon = "    ", highlight = "DiagnosticWarn", lang = "regex" },
	},
	messages = {
		enabled = true,
		highlight = "auto", -- Options: "auto", true, or false
	}
}

M.options = {}
local last_msg_count = 0
local ns_id = vim.api.nvim_create_namespace("SimpleNoice")

-- Mapping internal modes to config keys (Supports both named and literal keys)
local function get_config(mode)
	local key_map = { [":"] = "cmdline", ["/"] = "search_down", ["?"] = "search_up" }
	local key = key_map[mode]
	return M.options.config[key] or M.options.config[mode] or M.options.config.cmdline
end

-- Detect if a notification plugin (e.g., snacks.nvim, nvim-notify) is active
local function has_notifier()
	local info = debug.getinfo(vim.notify)
	if info and info.source and (info.source:match("lazy") or info.source:match("site") or info.source:match("pack")) then
		return true
	end
	if package.loaded["snacks.notifier"] or package.loaded["notify"] or package.loaded["fidget"] then
		return true
	end
	return false
end

-- Poll system message history and redirect errors/warnings if configured
local function check_messages()
	local messages_str = vim.fn.execute("messages")
	local messages_list = vim.fn.split(messages_str, "\n")
	local current_count = #messages_list
	
	if current_count ~= last_msg_count then
		local is_new = current_count > last_msg_count
		last_msg_count = current_count

		if is_new then
			local last_msg = messages_list[current_count]
			if last_msg and last_msg ~= "" then
				-- Filter for Vim Errors (E...) or Warnings (W...)
				if last_msg:match("^E%d+:") or last_msg:match("^W%d+:") then
					local active_notifier = has_notifier()
					local should_redirect = false
					
					-- Check redirection logic based on user settings
					if M.options.messages.highlight == true then
						should_redirect = true
					elseif M.options.messages.highlight == "auto" then
						should_redirect = active_notifier
					end

					if should_redirect then
						-- Notify via external plugin and clear native cmdline
						pcall(vim.notify, last_msg, vim.log.levels.ERROR, { title = "System Error" })
						vim.schedule(function()
							vim.cmd([[echo ""]])
						end)
					end
				end
			end
		end
	end
end

--- Initialize plugin with user options
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Initialize message redirection system if enabled
	if M.options.messages.enabled then
		last_msg_count = #vim.fn.split(vim.fn.execute("messages"), "\n")
		
		-- Use on_key for real-time capture
		vim.on_key(function(key)
			if key == nil or key == "" then return end
			vim.schedule(check_messages)
		end)

		-- Autocmds to capture non-keyboard triggered messages
		vim.api.nvim_create_autocmd({ "CmdlineLeave", "CursorHold", "ModeChanged" }, {
			group = vim.api.nvim_create_augroup("SimpleNoiceMessages", { clear = true }),
			callback = function()
				vim.schedule(check_messages)
			end,
		})
	end

	-- Automaticaly set global keybinds for standard command-line triggers
	vim.keymap.set("n", ":", function() M.open(":") end, { desc = "Simple Noice Cmdline" })
	vim.keymap.set("n", "/", function() M.open("/") end, { desc = "Simple Noice Search Down" })
	vim.keymap.set("n", "?", function() M.open("?") end, { desc = "Simple Noice Search Up" })
end

--- Open the floating command line window for the given mode
function M.open(mode)
	local setup = get_config(mode)
	local buf = vim.api.nvim_create_buf(false, true)
	
	-- Enable Syntax Highlighting by setting filetype and triggering syntax sync
	if setup.lang then
		vim.api.nvim_buf_set_option(buf, "filetype", setup.lang)
		vim.api.nvim_buf_set_option(buf, "syntax", "on")
	end

	-- Window sizing and positioning (centered)
	local width = M.options.width
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2) - 4
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = M.options.border,
		title = setup.title,
		title_pos = "center",
	})

	-- Style window with specific highlight groups
	vim.api.nvim_win_set_option(win, "winhighlight", "Normal:Normal,FloatBorder:" .. setup.highlight)
	
	-- Draw icon as Inline Virtual Text to preserve clean buffer for syntax highlighting
	vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
		virt_text = { { setup.icon, setup.highlight } },
		virt_text_pos = "inline",
		right_gravity = false, -- Ensures typed text appears AFTER the icon
	})
	
	vim.cmd("startinsert!")

	-- Helper to close the window gracefully
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.cmd("stopinsert")
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Execution logic for Enter key
	vim.keymap.set("i", "<CR>", function()
		local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
		close()
		if line and line ~= "" then
			if mode == ":" then
				pcall(vim.api.nvim_command, line)
			else
				vim.cmd(mode .. line)
			end
		end
	end, { buffer = buf })

	-- Completion logic for Tab key (commands only)
	vim.keymap.set("i", "<Tab>", function()
		if mode ~= ":" then return end
		if vim.fn.pumvisible() == 1 then
			vim.api.nvim_input("<C-n>")
			return
		end
		local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
		local candidates = vim.fn.getcompletion(line, "command")
		if candidates and #candidates > 0 then
			vim.fn.complete(1, candidates)
		end
	end, { buffer = buf })

	-- Closing mappings
	vim.keymap.set("i", "<Esc>", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })
	vim.keymap.set("n", "q",     close, { buffer = buf })
end

return M
