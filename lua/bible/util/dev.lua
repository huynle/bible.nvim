local M = {}

-- add the escape character to special characters
local escape_pattern = function (text)
    return text:gsub("([^%w])", "%%%1")
end

-- unload loaded modules by the matching text
function M.unload_packages(package_name)
	local esc_package_name = escape_pattern(package_name)

	for module_name, _ in pairs(package.loaded) do
		if string.find(module_name, esc_package_name) then
			package.loaded[module_name] = nil
		end
	end
end

return M
