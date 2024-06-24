local M = {}

M.show_message = function()
	vim.api.nvim_out_write("Hello from sooner!\n")
end
