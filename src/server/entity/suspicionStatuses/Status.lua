local Types = require(script.Parent.Types)

local Status = {}
Status.__index = Status

function Status.new(name: string, priority: number, requiresVisibility: boolean, detectionSpeedModifier: number): Types.Status
    local self = (setmetatable({} :: Types.StatusProperties, Status) :: any) :: Status
    self.name = name
    self.priority = priority
    self.requiresVisibility = requiresVisibility
    self.detectionSpeedModifier = detectionSpeedModifier

    return self
end

function Status.getPriorityLevel(self: Types.Status): number
	return self.priorityLevel
end

function Status.getDetectionSpeedModifier(self: Types.Status): number
	return self.detectionSpeedModifier
end

return Status