local api = require("sooner.api")
local status_bar = require("sooner.status_bar")

local M = {}
local api_key = nil
local home_dir = vim.fn.expand("~")
local api_key_file = home_dir .. "/.sooner.cfg"

local function save_api_key(key)
	local file, err = io.open(api_key_file, "w")
	if not file then
		vim.api.nvim_err_writeln("Error: Unable to open file to save API key: " .. err)
		return
	end
	file:write(key)
	file:close()
	vim.fn.setenv("SOONER_API_KEY", key)
end

local function load_api_key_from_file()
	local file, err = io.open(api_key_file, "r")
	if not file then
		vim.api.nvim_err_writeln("Error: Unable to open file to load API key: " .. err)
		return nil
	end
	local key = file:read("*a")
	file:close()
	return key:gsub("\n", "")
end

M.setup = function()
	-- Load the API key from file on startup
	api_key = load_api_key_from_file()

	-- If an API key was loaded, set it in the environment
	if api_key then
		vim.fn.setenv("SOONER_API_KEY", api_key)
	end

	vim.api.nvim_create_user_command("SoonerActivate", function()
		if api_key then
			vim.fn.jobstart("xdg-open https://www.sooner.run/dashboard")
		else
			vim.ui.input({ prompt = "Enter your API key: " }, function(key)
				if key then
					print("\nActivating Sooner...")
					save_api_key(key)
					api.validate_api_key(key, function(response)
						print(vim.inspect(response))
						if response.isValid then
							api_key = key
							status_bar.update_text(response.codetime_today)
							vim.api.nvim_out_write("Extension activated successfully.\n")
						else
							vim.api.nvim_err_writeln("Invalid API key. Please try again.")
						end
					end)
				end
			end)
		end
	end, {})

	vim.api.nvim_create_user_command("SoonerClearApiKey", function()
		print("Key", api_key)
		api_key = nil
		vim.fn.setenv("SOONER_API_KEY", "")
		vim.fn.delete(api_key_file)
		vim.api.nvim_out_write("API key deleted successfully.\n")
		status_bar.update_text(0)
	end, {})
end

return M
