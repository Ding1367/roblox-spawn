export type Summon = {
	thenDo: (self: Summon, this: (...any) -> (...any)) -> Summon,
	thenCall: (self: Summon, f: (...any) -> (...any), ...any) -> Summon,
	join: (self: Summon) -> (boolean, ...any | any),
	ifError: (self: Summon, thenDo: (...any) -> (...any)) -> Summon,
	ifErrorCall: (self: Summon, f: (...any) -> (...any), ...any) -> Summon,
	alwaysDo: (self: Summon, this: (...any) -> (...any), ...any) -> Summon,
	halt: (self: Summon) -> (),
	timeout: (self: Summon, duration: number) -> Summon, 
}
local mt
local function wrapper(func, p, summon)
	local values = table.pack(pcall(func, table.unpack(p)))
	summon.err = not values[1]
	table.remove(values, 1)
	values.n -= 1
	summon.future = values
	for i,v in pairs(summon.waiters) do
		coroutine.resume(v)
	end
end
local function spawn(func, ...): Summon
	local summon = setmetatable({}, mt)
	local p = table.pack(...)
	summon.waiters = {}
	summon.robloxTask = task.spawn(wrapper, func, p, summon)
	return summon
end
local function _thenDo(self, this)
	self:join()
	return (self.err and error or this)(table.unpack(self.future))
end
local function _alwaysDo(self, this, p)
	local result = self:join()
	local v = this(table.unpack(p))
	if not result then
		error(self.future[1])
	end
	return v
end
local function _ifError(self, thenDo)
	if not self:join() then
		return thenDo(table.unpack(self.future))
	end
end
local function _timeout(self, duration)
	if not self.future then
		local running = coroutine.running()
		local idx = #self.waiters + 1
		table.insert(self.waiters, running)
		task.delay(duration, function()
			table.remove(self.waiters, idx)
			coroutine.resume(running)
		end)
		coroutine.yield()
	end
	local fut = self.future
	if fut then
		if self.err then
			error(fut)
		end
		return not not fut, table.unpack(fut)
	end
	return false
end
mt = {__index = {
	thenDo = function(self, this)
		return spawn(_thenDo, self, this)
	end,
	thenCall = function(self, f, ...)
		local p = table.pack(...)
		return self:thenDo(function()
			return f(table.unpack(p))
		end)
	end,
	join = function(self)
		if not self.future then
			table.insert(self.waiters, coroutine.running())
			coroutine.yield()
		end
		return not self.err and not self.halted, table.unpack(self.future)
	end,
	ifError = function(self, thenDo)
		return spawn(_ifError, self, thenDo)
	end,
	ifErrorCall = function(self, f, ...)
		local p = table.pack(...)
		return self:ifError(function()
			return f(table.unpack(p))
		end)
	end,
	alwaysDo = function(self, this, ...)
		local p = table.pack(...)
		return spawn(_alwaysDo, self, this, p)
	end,
	halt = function(self)
		self.err = true
		self.halted = true
		task.cancel(self.robloxTask)
		self.future = "<halted>"
	end,
	timeout = function(self, duration)
		return spawn(_timeout, self, duration)
	end,}}
return spawn
