--!strict

local DEFAULT_FOV = 70

--[=[
	@class CameraSocket
]=]
local CameraSocket = {}
CameraSocket.__index = CameraSocket

export type CameraSocket = typeof(setmetatable({} :: {
	cframe: CFrame,
	fov: number
}, CameraSocket))

function CameraSocket.new(name: string, cframe: CFrame, fov: number): CameraSocket
	return setmetatable({
		cframe = cframe,
		fov = fov
	}, CameraSocket)
end

function CameraSocket.fromPart(part: BasePart, fov: number?): CameraSocket
	fov = fov or DEFAULT_FOV
	return CameraSocket.new(part.Name, part.CFrame, fov)
end

function CameraSocket.fromArray(array: {BasePart}): {CameraSocket}
	local arrayCount = #array
	local socketTable = table.create(arrayCount, true) :: {CameraSocket}

	for i, part in array do
		local newSocket = CameraSocket.fromPart(part, part:GetAttribute("FOV") :: number?)
		socketTable[i] = newSocket
	end

	return socketTable
end

return CameraSocket