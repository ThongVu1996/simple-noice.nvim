local M = {}

-- 1. Default Configuration
M.defaults = {
	width = 60,
	border = "rounded",
	config = {
		cmdline = { title = " Cmdline ", icon = "  ", highlight = "DiagnosticInfo", lang = "vim" },
		search_down = { title = " Search ", icon = "   ", highlight = "DiagnosticWarn", lang = "regex" },
		search_up = { title = " Search ", icon = "   ", highlight = "DiagnosticWarn", lang = "regex" },
	},
}

M.options = {}
local ns_id = vim.api.nvim_create_namespace("SimpleNoiceUI")

-- Helper to get configuration based on current mode
local function get_config(mode)
	local map = { [":"] = "cmdline", ["/"] = "search_down", ["?"] = "search_up" }
	return M.options.config[map[mode] or "cmdline"]
end

-- Force redrawing the statusline to ensure UI stability
local function refresh_statusline()
	vim.schedule(function()
		vim.cmd("redrawstatus!")
	end)
end

-- 2. Core UI Logic for Cmdline/Search
function M.open(mode)
	local setup = get_config(mode)
	local buf = vim.api.nvim_create_buf(false, true)
	
	-- Prepare history list
	local history_type = (mode == ":" and "cmd" or "search")
	local history_list = {}
	local h_count = vim.fn.histnr(history_type)
	for i = 1, h_count do
		local h = vim.fn.histget(history_type, i)
		if h ~= "" then table.insert(history_list, h) end
	end
	local h_idx = #history_list + 1

	-- Buffer setup
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	
	if mode == ":" then
		vim.bo[buf].filetype = "simple_noice_input"
		vim.bo[buf].syntax = "vim"
	else
		vim.bo[buf].filetype = setup.lang
	end

	-- Open window
	local width = M.options.width
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - 1) / 2) - 4,
		col = math.floor((vim.o.columns - width) / 2),
		width = width, height = 1,
		style = "minimal", border = M.options.border,
		title = setup.title, title_pos = "center",
	})

	vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:" .. setup.highlight
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " })
	
	local function redraw_icon()
		vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
		vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
			virt_text = { { setup.icon, setup.highlight } },
			virt_text_pos = "inline",
		})
	end
	redraw_icon()

	vim.schedule(function()
		if vim.api.nvim_win_is_valid(win) then vim.cmd("startinsert!") end
	end)
	
	local function close()
		if win and vim.api.nvim_win_is_valid(win) then
			vim.cmd("stopinsert")
			vim.api.nvim_win_close(win, true)
		end
		refresh_statusline()
	end

	-- Keymaps
	local b_opts = { buffer = buf, expr = true }
	vim.keymap.set("i", "<BS>", function()
		return vim.api.nvim_win_get_cursor(0)[2] <= 1 and "" or "<BS>"
	end, b_opts)
	
	vim.keymap.set("i", "<CR>", function()
		local ok, blink = pcall(require, "blink.cmp")
		if ok and blink.is_visible() then
			blink.accept()
			return
		end
		local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
		line = line:gsub("^%s+", "")
		close()
		if line ~= "" then
			local cmd = (mode == ":" and "" or mode) .. line
			local ok_cmd, err = pcall(vim.cmd, cmd)
			if not ok_cmd then
				local clean_err = err:gsub("^.*:%s*E%d+:%s*", "")
				vim.notify(clean_err, vim.log.levels.ERROR, { title = "Error" })
			end
			vim.fn.histadd(history_type, line)
		end
	end, { buffer = buf })

	vim.keymap.set("i", "<Up>", function()
		local new_idx = h_idx - 1
		if new_idx >= 1 then
			h_idx = new_idx
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. history_list[h_idx] })
			redraw_icon()
			vim.cmd("startinsert!")
		end
	end, { buffer = buf })

	vim.keymap.set("i", "<Down>", function()
		local new_idx = h_idx + 1
		if new_idx <= #history_list + 1 then
			h_idx = new_idx
			local cmd = history_list[h_idx] or ""
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. cmd })
			redraw_icon()
			vim.cmd("startinsert!")
		end
	end, { buffer = buf })

	vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = buf })
end

-- 3. Message Integration (Advanced Aggregator)
local msg_buffer = {}
local msg_timer = nil
local last_level = vim.log.levels.INFO

local function setup_message_delegation()
	vim.ui_attach(ns_id, { ext_messages = true }, function(event, ...)
		if event ~= "msg_show" then return end
		local args = { ... }
		local kind, content, replace_last = args[1], args[2], args[3]
		if kind == "search_count" or kind == "statusline" or kind == "" then return end

		local full_msg = ""
		for _, chunk in ipairs(content) do full_msg = full_msg .. chunk[2] end

		if full_msg ~= "" and full_msg ~= "\n" then
			local level = vim.log.levels.INFO
			if kind:match("err") then level = vim.log.levels.ERROR
			elseif kind:match("warn") then level = vim.log.levels.WARN end
			
			if replace_last and #msg_buffer > 0 then table.remove(msg_buffer) end
			table.insert(msg_buffer, full_msg)
			last_level = level

			if msg_timer then msg_timer:stop() end
			msg_timer = vim.defer_fn(function()
				if #msg_buffer > 0 then
					vim.notify(table.concat(msg_buffer, "\n"), last_level, { title = "System" })
					msg_buffer = {}
				end
				msg_timer = nil
			end, 20)
		end
	end)
end

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
	setup_message_delegation()
	vim.keymap.set("n", ":", function() M.open(":") end)
	vim.keymap.set("n", "/", function() M.open("/") end)
	vim.keymap.set("n", "?", function() M.open("?") end)
end

return M
