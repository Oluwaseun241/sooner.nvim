local api = require("sooner.api")
local status_bar = require("sooner.status_bar")
local commands = require("sooner.commands")

local M = {}
--variable
local coding_start_time = nil
local total_coding_time = 0
local activity_timeouts = {}
local api_key = nil

local debounce_time = 120 * 1000

local function start_tracking()
	if not api_key then
		return
	end
	if not coding_start_time then
		coding_start_time = vim.fn.reltimefloat(vim.fn.reltime()) * 1000
	end
end

local function stop_tracking()
	if coding_start_time then
		local coding_end_time = vim.fn.reltimefloat(vim.fn.reltime()) * 1000
		local coding_duration = coding_end_time - coding_start_time
		total_coding_time = total_coding_time + coding_duration
		coding_start_time = nil
	end
end

local function on_text_changed()
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	local language = vim.bo[bufnr].filetype

	start_tracking()

	if not api_key then
		return
	end

	if activity_timeouts[bufnr] then
		vim.fn.timer_stop(activity_timeouts[bufnr])
	end

	activity_timeouts[bufnr] = vim.fn.timer_start(debounce_time, function()
		vim.schedule(function()
			api.send_pulse_data(api_key, coding_start_time, file_path, language)
			stop_tracking()
			activity_timeouts[bufnr] = nil
		end)
	end)
end

M.setup = function()
	status_bar.initialize()
	api_key = vim.fn.getenv("SONNER_API_KEY")
	--api_key = "EI0L7Nu9QYK1lx85eFrLMYoEQWo7FbTGkDDEVJk8enuwRbZsi4pDWXwlgKutO2SGZ2i4Y"
	if api_key then
		api.fetch_coding_time_today(api_key, function(coding_time_today)
			if coding_time_today then
				total_coding_time = coding_time_today.time
				status_bar.update_text(total_coding_time)
			end
		end)
	end

	vim.api.nvim_create_autocmd("TextChanged", {
		pattern = "*",
		callback = on_text_changed,
	})

	commands.setup()
end

return M
