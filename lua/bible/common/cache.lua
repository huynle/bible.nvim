local classes = require("bible.common.classes")
local Path = require("plenary.path")
local scan = require("plenary.scandir")

local Cache = classes.class()

local function get_current_date()
	return os.date("%Y-%m-%d_%H:%M:%S")
end

local function get_default_filename()
	return os.time()
end

local function parse_date_time(str)
	local year, month, day, hour, min, sec = string.match(str, "(%d+)-(%d+)-(%d+)_(%d+):(%d+):(%d+)")
	return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = sec })
end

local function read_cache_file(filename)
	local file = io.open(filename, "rb")
	if not file then
		vim.notify("Cannot read cache file", vim.log.levels.ERROR)
		return nil
	end

	local jsonString = file:read("*a")
	file:close()

	local data = vim.json.decode(jsonString)
	return data.name, data.updated_at
end

function Cache:init(opts)
	opts = opts or {}
	self.filename = opts.filename or nil
	if self.filename then
		self:load()
	else
		local dt = get_current_date()
		self.name = opts.name or dt
		self.updated_at = dt
		self.filename = Cache.get_dir():joinpath(get_default_filename() .. ".json"):absolute()
		self.conversation = {}
		self.parameters = {}
	end
end

function Cache:rename(name)
	self.name = name
	self:save()
end

function Cache:delete()
	return Path:new(self.filename):rm()
end

function Cache:to_export()
	return {
		name = self.name,
		updated_at = self.updated_at,
		parameters = self.parameters,
		conversation = self.conversation,
	}
end

function Cache:previous_context()
	for ith = #self.conversation, 1, -1 do
		local context = self.conversation[ith].context
		if context then
			return context
		end
	end
	return {}
end

function Cache:add_item(item)
	local ctx = item.ctx or {}
	if item.ctx then
		item.ctx = nil
	end
	if ctx and ctx.params and ctx.params.options then
		self.parameters = ctx.params.options
		self.parameters.model = ctx.params.model
		item.context = ctx.context
	end
	if self.updated_at == self.name and item.type == 1 then
		self.name = item.text
	end
	-- tmp hack for system message
	if item.type == 3 then
		local found = false
		for index, msg in ipairs(self.conversation) do
			if msg.type == item.type then
				self.conversation[index].text = item.text
				found = true
			end
		end

		if not found then
			table.insert(self.conversation, 1, item)
		end
	else
		table.insert(self.conversation, item)
	end

	self.updated_at = get_current_date()
	self:save()

	return #self.conversation + 1
end

function Cache:delete_by_index(idx)
	table.remove(self.conversation, idx)
	self.updated_at = get_current_date()
	self:save()
end

function Cache:save()
	local data = self:to_export()

	local file, err = io.open(self.filename, "w")
	if file ~= nil then
		local json_string = vim.json.encode(data)
		file:write(json_string)
		file:close()
	else
		vim.notify("Cannot save cache: " .. err, vim.log.levels.ERROR)
	end
end

function Cache:load()
	local file = io.open(self.filename, "rb")
	if not file then
		vim.notify("Cannot read cache file", vim.log.levels.ERROR)
		return nil
	end

	local jsonString = file:read("*a")
	file:close()

	local data = vim.json.decode(jsonString)
	self.name = data.name
	self.updated_at = data.updated_at or get_current_date()
	self.parameters = data.parameters
	self.conversation = data.conversation
end

--
-- static methods
--

function Cache.get_dir()
	local dir = Path:new(vim.fn.stdpath("state")):joinpath("ogpt")
	if not dir:exists() then
		dir:mkdir()
	end
	return dir
end

function Cache.list_caches()
	local dir = Cache.get_dir()
	local files = scan.scan_dir(dir:absolute(), { hidden = false })
	local caches = {}

	for _, filename in pairs(files) do
		local name, updated_at = read_cache_file(filename)
		if updated_at == nil then
			updated_at = filename
		end

		table.insert(caches, {
			filename = filename,
			name = name,
			ts = parse_date_time(updated_at),
		})
	end

	table.sort(caches, function(a, b)
		return a.ts > b.ts
	end)

	return caches
end

function Cache.latest()
	local caches = Cache.list_caches()
	if #caches > 0 then
		local cache = caches[1]
		return Cache.new({ filename = cache.filename })
	end
	return Cache.new()
end

return Cache
