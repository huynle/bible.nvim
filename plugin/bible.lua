vim.api.nvim_create_user_command("BibleLookup", function(params)
	local args = loadstring("return " .. params.args)()
	require("bible").bibleLookup(args)
end, { nargs = "?", force = true, complete = "lua" })

vim.api.nvim_create_user_command("BibleLookupSelection", function(params)
	local args = loadstring("return " .. params.args)()
	require("bible").bibleLookupSelection(args)
end, { nargs = "?", force = true, complete = "lua" })
