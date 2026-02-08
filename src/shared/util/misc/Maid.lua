--!strict

--[=[
	@class Maid

	Manages the cleaning of connections and other instances.
]=]
local Maid = {}
Maid.__index = Maid

export type Maid = typeof(setmetatable({} :: {
	_tasks: {any}
}, Maid))

function Maid.new(): Maid
	return setmetatable({
		_tasks = {}
	}, Maid)
end

function Maid.giveTask<T>(self: Maid, task: T): T
	assert(task ~= nil, `Cannot give a Maid a task that's nil`)

	table.insert(self._tasks, task)

	return task
end

function Maid.doCleaning(self: Maid): ()
	local tasks = self._tasks
	-- Move to a local reference and clear the original immediately
	-- to prevent re-entrant calls from re-cleaning the same list
	
	while #tasks > 0 do
		local index = #tasks
		local task = tasks[index]
		tasks[index] = nil

		if typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		elseif typeof(task) == "Instance" then
			task:Destroy()
		elseif type(task) == "table" then
			local destroy = task.Destroy or task.destroy
			if type(destroy) == "function" then
				pcall(destroy, task)
			end
		elseif type(task) == "function" then
			(task :: (...any) -> (...any))()
		end
	end
end

return Maid