local M = {}

M.get_os_type = function()
	local handle = io.popen("uname -s")
	local result = handle:read("*a")
	handle:close()
	return result:gsub("\n", "")
end
return M
