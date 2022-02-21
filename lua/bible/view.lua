local buf, win, start_win

local M = {}

-- default options
M.defaults = {
  bufname = "bible #"
}



M.options = M.defaults -- not necessary, but better code completion

function M.open()
  -- We get path from line which user push enter on
  local path = vim.api.nvim_get_current_line()

  -- if the starting window exists
  if vim.api.nvim_win_is_valid(start_win) then
    -- we move to it
    vim.api.nvim_set_current_win(start_win)
    -- and edit chosen file
    vim.api.nvim_command('edit ' .. path)
  else
    -- if there is no starting window we create new from lest side
    vim.api.nvim_command('leftabove vsplit ' .. path)
    -- and set it as our new starting window
    start_win = vim.api.nvim_get_current_win()
  end
end

-- After opening desired file user no longer need our navigation
-- so we should create function to closing it.
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- Ok. Now we are ready to making two first opening functions

function M.open_and_close()
  M.open() -- We open new file
  M.close() -- and close navigation
end

function M.preview()
  M.open() -- WE open new file
  -- but in preview instead of closing navigation
  -- we focus back to it
  vim.api.nvim_set_current_win(win)
end

-- To making splits we need only one function
function M.split(axis)
  local path = vim.api.nvim_get_current_line()

  -- We still need to handle two scenarios
  if vim.api.nvim_win_is_valid(start_win) then
    vim.api.nvim_set_current_win(start_win)
    -- We pass v in axis argument if we want vertical split
    -- or nothing/empty string otherwise.
    vim.api.nvim_command(axis ..'split ' .. path)
  else
    -- if there is no starting window we make new on left
    vim.api.nvim_command('leftabove ' .. axis..'split ' .. path)
    -- but in this case we do not need to set new starting window
    -- because splits always close navigation 
  end

  M.close()
end

function M.open_in_tab()
  local path = vim.api.nvim_get_current_line()

  vim.api.nvim_command('tabnew ' .. path)
  close()
end


function M.redraw(content)
  -- First we allow introduce new changes to buffer. We will block that at end.
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  local items_count =  vim.api.nvim_win_get_height(win) - 1 -- get the window height
  local list = {}
  
  list = content
  -- We apply results to buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
  -- And turn off editing
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

function M.set_mappings()
  -- set mapping to the current buffer
  local mappings = {
    -- q = 'close()',
    ['<c-c>'] = 'close()',
    -- ['<cr>'] = 'open_and_close()',
    -- v = 'split("v")',
    -- s = 'split("")',
    -- p = 'preview()',
    -- t = 'open_in_tab()'
  }

  for k,v in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"bible.ui".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
end

function M.create_ephem_win(options)
  -- We save handle to window from which we open the navigation
  start_win = vim.api.nvim_get_current_win()

  -- vim.api.nvim_command('botright 85vnew '..filepath) -- We open a new vertical window at the far right
  vim.api.nvim_command('botright 85vnew ') -- We open a new vertical window at the far right
  win = vim.api.nvim_get_current_win() -- We save our navigation window handle...
  buf = vim.api.nvim_get_current_buf() -- ...and it's buffer handle.

  -- We should name our buffer. All buffers in vim must have unique names.
  -- The easiest solution will be adding buffer handle to it
  -- because it is already unique and it's just a number.
  vim.api.nvim_buf_set_name(buf, options.bufname .. buf)

  -- Now we set some options for our buffer.
  -- nofile prevent mark buffer as modified so we never get warnings about not saved changes.
  -- Also some plugins treat nofile buffers different.
  -- For example coc.nvim don't triggers aoutcompletation for these.
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- We do not need swapfile for this buffer.
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  -- And we would rather prefer that this buffer will be destroyed when hide.
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- It's not necessary but it is good practice to set custom filetype.
  -- This allows users to create their own autocommand or colorschemes on filetype.
  -- and prevent collisions with other plugins.
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  -- For better UX we will turn off line wrap and turn on current line highlight.
  vim.api.nvim_win_set_option(win, 'wrap', true)

  vim.api.nvim_win_set_option(win, 'cursorline', true)

  M.set_mappings() -- At end we will set mappings for our navigation.
end

function M.ephemeral_entry(content, options)
  local options = vim.tbl_extend("force", M.options, options)
  -- options.ui = options.query
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  else
    M.create_ephem_win(options)
  end
  M.redraw(content)
end

return M
