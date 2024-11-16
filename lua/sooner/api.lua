local curl = require("plenary.curl")

local M = {}

local function http_request(url, method, body, headers, callback)
	local response = curl[method:lower()]({
		url = url,
		headers = headers,
		timeout = 20000,
		body = vim.fn.json_encode(body),
	})

	if response.status == 200 then
		local decoded = vim.fn.json_decode(response.body)
		callback(decoded)
	else
		print("Request failed with status code", response.status)
		print("Error:", response.body)
		callback(nil)
	end
end

local function get_os_type()
	local os_type

	-- Check for Windows specifically
	if package.config:sub(1, 1) == "\\" then
		os_type = "Windows"
	else
		local handle = io.popen("uname -s")
		if handle then
			local result = handle:read("*a"):gsub("\n", "")
			handle:close()
			os_type = result
		else
			return nil
		end
	end

	return os_type
end

M.send_pulse_data = function(api_key, coding_start_time, file_path, language)
	if not api_key or not coding_start_time then
		return
	end

	local coding_end_time = vim.fn.reltimefloat(vim.fn.reltime()) * 1000
	local pulse_time = coding_end_time - coding_start_time
	print(pulse_time)

	local payload = {
		path = file_path,
		time = pulse_time,
		branch = M.get_current_branch(M.get_project_path()),
		project = vim.fn.getcwd(),
		language = language,
		os = get_os_type(),
		hostname = vim.fn.hostname(),
		timezone = os.date("%Z"),
		editor = "Neovim",
	}

	-- Ensure api_key is a string
	if type(api_key) == "userdata" then
		api_key = tostring(api_key)
	end

	http_request(
		"https://api.sooner.run/v1/pulses",
		"POST",
		payload,
		{ ["Authorization"] = "Bearer " .. api_key },
		function(response)
			if response then
				print("Response: ", vim.inspect(response))
			else
				print("No response or request failed.")
			end
		end
	)
end

M.fetch_coding_time_today = function(api_key, callback)
	local headers = {
		Authorization = string.format("Bearer %s", api_key),
	}

	http_request("https://api.sooner.run/v1/codetime-today", "GET", nil, headers, function(response)
		if response then
			print(response)
			callback(response)
		else
			print("Failed to fetch coding time today")
		end
	end)
end

M.validate_api_key = function(key, callback)
	http_request("https://api.sooner.run/v1/activate-extension", "POST", {
		key = key,
	}, {}, function(response)
		print(vim.inspect(response))
		if response and response.status == 200 then
			callback({
				isValid = true,
				codetime_today = response and response.codetime_today or 0,
			})
		else
			callback({
				isValid = false,
				codetime_today = 0,
			})
			print(vim.inspect(response))
		end
	end)
end

M.get_file_path = function()
	local bufname = vim.fn.bufname()
	return bufname ~= "" and bufname or nil
end

M.get_project_path = function()
	local cwd = vim.fn.getcwd()
	return cwd ~= "" and cwd or nil
end

M.get_current_branch = function(project_path)
	if not project_path then
		return nil
	end
	local branch = vim.fn.systemlist("git -C " .. project_path .. " rev-parse --abbrev-ref HEAD")[1]
	return branch and branch or nil
end

return M
