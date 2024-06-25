local M = {}

local statusline_id = nil

M.initialize = function()
	statusline_id = vim.api.nvim_create_buf(false, true)
	if statusline_id == 0 then
		vim.api.nvim_err_writeln("Failed to create buffer for status line.")
		return
	end
	vim.bo[statusline_id].buftype = "nofile"
	vim.bo[statusline_id].bufhidden = "hide"
	vim.api.nvim_win_set_buf(0, statusline_id)
end

M.update_text = function(total_coding_time)
	if statusline_id == nil or not vim.api.nvim_buf_is_valid(statusline_id) then
		vim.api.nvim_err_writeln("Status line buffer is not valid.")
		return
	end

	local hours = math.floor(total_coding_time / 3600)
	local minutes = math.floor((total_coding_time % 3600) / 60)
	local text = string.format("Coding Time Today: %02d:%02d", hours, minutes)
	vim.api.nvim_buf_set_lines(statusline_id, 0, -1, false, { text })
end

return M
