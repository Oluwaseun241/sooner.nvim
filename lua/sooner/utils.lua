local M = {}

local home_dir = vim.fn.expand("~")
local api_key_file = home_dir .. "/.sooner.cfg"

function M.save_api_key(key)
	local file, err = io.open(api_key_file, "w")
	if not file then
		vim.api.nvim_err_writeln("Error: Unable to open file to save API key: " .. err)
		return
	end
	file:write(key)
	file:close()
	vim.fn.setenv("SOONER_API_KEY", key)
end

function M.load_api_key_from_file()
	local file, err = io.open(api_key_file, "r")
	if not file then
		vim.api.nvim_err_writeln("Error: Unable to open file to load API key: " .. err)
		return nil
	end
	local key = file:read("*a")
	file:close()
	return key:gsub("\n", "")
end
return M
