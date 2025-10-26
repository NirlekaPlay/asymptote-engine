--!strict

local GuardPost = {}
GuardPost.__index = GuardPost

export type GuardPost = typeof(setmetatable({} :: {
	cframe: CFrame,
	occupied: boolean
}, GuardPost))

function GuardPost.new(cframe: CFrame): GuardPost
	return setmetatable({
		cframe = cframe,
		occupied = false
	}, GuardPost)
end

function GuardPost.fromPart(part: BasePart, doDestroy: boolean?): GuardPost
	local newPost = GuardPost.new(part.CFrame)
	if doDestroy then
		part:Destroy()
	end
	return newPost
end

function GuardPost.isOccupied(self: GuardPost): boolean
	return self.occupied
end

function GuardPost.occupy(self: GuardPost): ()
	self.occupied = true
end

function GuardPost.vacate(self: GuardPost): ()
	self.occupied = false
end

function GuardPost.__tostring(self: GuardPost): string
	return `GuardPost\{ occupied: {self.occupied}; pos: {self.cframe} \}`
end

return GuardPost