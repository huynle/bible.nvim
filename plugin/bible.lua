vim.api.nvim_create_user_command("BibleLookup", function(opts)
	require("bible").bibleLookup(opts)
end, {})

vim.api.nvim_create_user_command("BibleLookupSelection", function(opts)
	require("bible").bibleLookupSelection(opts)
end, {})
