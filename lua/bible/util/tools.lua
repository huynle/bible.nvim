local M = {}

local results = {}
local function onread(err, data)
	if err then
		-- print('ERROR: ', err)
		-- TODO handle err
	end
	if data then
		local vals = vim.split(data, "\n")
		for _, d in pairs(vals) do
			if d == "" then
				goto continue
			end
			table.insert(results, d)
			::continue::
		end
	end
end
function M.exec(cmd, args, on_complete)
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	-- local function setQF()
	-- 	vim.fn.setqflist({}, "r", { title = "Search Results", lines = results })
	-- 	api.nvim_command("cwindow")
	-- 	local count = #results
	-- 	for i = 0, count do
	-- 		results[i] = nil
	-- 	end -- clear the table for the next search
	-- end
	handle = vim.loop.spawn(
		cmd,
		{
			args = args,
			stdio = { nil, stdout, stderr },
		},
		vim.schedule_wrap(function()
			stdout:read_stop()
			stderr:read_stop()
			stdout:close()
			stderr:close()
			handle:close()
			on_complete(stdout)
		end)
	)
	vim.loop.read_start(stdout, onread)
	vim.loop.read_start(stderr, onread)
end

-- got it from telescope
function M.get_os_command_output(cmd, cwd)
	if type(cmd) ~= "table" then
		utils.notify("get_os_command_output", {
			msg = "cmd has to be a table",
			level = "ERROR",
		})
		return {}
	end
	local command = table.remove(cmd, 1)
	local stderr = {}
	local stdout, ret = Job:new({
		command = command,
		args = cmd,
		cwd = cwd,
		on_stderr = function(_, data)
			table.insert(stderr, data)
		end,
	}):sync()
	return stdout, ret, stderr
end

return M
