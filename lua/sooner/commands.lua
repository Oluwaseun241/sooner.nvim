local api = require("sooner.api")
local status_bar = require("sooner.status_bar")

local M = {}

M.setup = function()
	vim.api.nvim_create_user_command("SoonerStatusBarClick", function()
		if api_key then
			vim.fn.jobstart("xdg-open https://www.sooner.run/dashboard")
		else
			vim.ui.input({ prompt = "Enter your API key" }, function(key)
				if key then
					vim.fn.with_progress("Activating Sooner", function()
						api.validate_api_key(key, function(response)
							if response.isValid then
								api_key = key
								vim.fn.setenv("SOONER_API_KEY", key)
								status_bar.update_text(response.codetime_today)
								vim.api.nvim_out_write("Extension activated successfully.\n")
							else
								vim.api.nvim_err_writeln("Invalid API key. Please try again.")
							end
						end)
					end)
				end
			end)
		end
	end, {})

	vim.api.nvim_create_user_command("SoonerClearApiKey", function()
		api_key = nil
		vim.fn.setenv("SOONER_API_KEY", "")
		vim.api.nvim_out_write("API key deleted successfully.\n")
		status_bar.update_text(0)
	end, {})
end

return M
