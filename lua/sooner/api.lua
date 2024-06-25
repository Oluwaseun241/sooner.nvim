local M = {}

local function http_request(url, method, body, callback, headers)
	local cmd = {
		"curl",
		"-s",
		"-X",
		method,
		"-H",
		"Content-Type: application/json",
	}

	if headers then
		for k, v in pairs(headers) do
			table.insert(cmd, "-H")
			table.insert(cmd, string.format("%s: %s", k, v))
		end
	end

	table.insert(cmd, "-d")
	table.insert(cmd, vim.fn.json_encode(body))
	table.insert(cmd, url)

	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			local response = table.concat(data, "\n")
			local decoded = vim.fn.json_decode(response)
			callback(decoded)
		end,
		on_stderr = function(_, data)
			print("Error:", table.concat(data, "\n"))
		end,
		on_exit = function(_, code)
			if code ~= 0 then
				print("Request failed with exit code", code)
			end
		end,
	})
end

local function get_os_type()
	local handle = io.popen("uname -s")
	local result = handle:read("*a")
	handle:close()
	return result:gsub("\n", "")
end

M.send_pulse_data = function(api_key, coding_start_time, file_path, language)
	if not api_key or not coding_start_time then
		return
	end

	local coding_end_time = vim.fn.reltimefloat(vim.fn.reltime()) * 1000
	local pulse_time = coding_end_time - coding_start_time

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

	http_request("https://api.sooner.run/pulse", "POST", {
		api_key = api_key,
		payload = payload,
	}, function(response)
		print(response)
	end)
end

M.fetch_coding_time_today = function(api_key, callback)
	local headers = {
		Authorization = string.format("Bearer %s", api_key),
	}

	http_request("https://api.sooner.run/codetime-today", "GET", {}, callback, headers)
end

M.validate_api_key = function(key, callback)
	http_request("https://api.sooner.run/activate-extension", "POST", {
		key = key,
	}, function(response)
		callback({
			isValid = response and response.status == 200,
			codetime_today = response and response.codetime_today or 0,
		})
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
