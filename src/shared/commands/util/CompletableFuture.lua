--!strict

--[=[
	@class CompletableFuture
]=]
local CompletableFuture = {}
CompletableFuture.__index = CompletableFuture

export type CompletableFuture<T> = typeof(setmetatable({} :: {
	_result: T?,
	_isDone: boolean,
	_callbacks: { () -> () },
}, CompletableFuture))

local NIL = {}

function CompletableFuture.new<T>(r: T?): CompletableFuture<T>
	local self = setmetatable({
		_result = r,
		_isDone = r ~= nil,
		_callbacks = {},
	}, CompletableFuture)
	return self
end

function CompletableFuture.completedFuture<U>(value: U): CompletableFuture<U>
	local future = CompletableFuture.new(nil) :: any
	future._result = if value == nil then NIL else value
	future._isDone = true
	return future
end

function CompletableFuture.allOf(cfs: {CompletableFuture<any>}): CompletableFuture<nil>
	local result = CompletableFuture.new(nil)
	local count = #cfs
	
	if count == 0 then
		result:complete(nil)
		return result
	end

	local completed = 0
	for _, cf in cfs do
		cf:thenRun(function()
			completed += 1
			if completed == count then
				result:complete(nil)
			end
		end)
	end

	return result
end

function CompletableFuture.complete<T>(self: CompletableFuture<T>, value: T?): boolean
	if self._isDone then
		return false
	end

	self._result = if value == nil then NIL else (value :: any)
	self._isDone = true

	for _, callback in self._callbacks do
		task.spawn(callback)
	end
	table.clear(self._callbacks)

	return true
end

function CompletableFuture.join<T>(self: CompletableFuture<T>): T
	if self._result == NIL then
		return nil :: any
	end
	return self._result :: T
end

function CompletableFuture.isDone<T>(self: CompletableFuture<T>): boolean
	return self._isDone
end

function CompletableFuture.thenRun<T>(self: CompletableFuture<T>, action: () -> ()): CompletableFuture<T>
	if self._isDone then
		task.spawn(action)
	else
		table.insert(self._callbacks, action)
	end
	return self
end

return CompletableFuture