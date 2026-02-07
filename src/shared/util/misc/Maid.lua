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
	for index, task in self._tasks do
		if typeof(task) == "RBXScriptConnection" then
			(task :: RBXScriptConnection):Disconnect()
		elseif typeof(task) == "Instance" then
			(task :: Instance):Destroy()
		elseif typeof(task) == "table" then
			if task.destroy and type(task.destroy) == "function" then
				local success, err = pcall(task.destroy, task)
				if not success then
					warn(`An error has occured when calling <{task}>::destroy() :\n{err}`)
				end
			end
		end
	end

	table.clear(self._tasks)
end

return Maid