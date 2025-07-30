--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Agent = require(ServerScriptService.server.Agent)
local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)

local BrainDebugger = {}
BrainDebugger.__index = BrainDebugger

local function getDebugGui(character: Model): BillboardGui
	local findGuiInChar = character.Head:FindFirstChild("BrainDebugGui")
	if not findGuiInChar then
		local new = ServerStorage.BrainDebugGui:Clone()
		new.Parent = character.Head
		return new
	end

	return findGuiInChar
end

function BrainDebugger.new(agent: Agent.Agent)
	return setmetatable({
		agent = agent,
		agentBrainDebuggerGui = getDebugGui(agent.character),
		textlabelsByMemories = {} :: { [MemoryModuleTypes.MemoryModuleType<any>]: TextLabel},
		textlabelsByActivities = {} :: { [Activity.Activity]: TextLabel}
	}, BrainDebugger)
end

export type BrainDebugger = typeof(BrainDebugger.new())

function BrainDebugger.update(self: BrainDebugger): ()
	local agentBrain = self.agent:getBrain()

	for memoryType, memoryOptional in pairs(agentBrain.memories) do
		local memoryText = self.textlabelsByMemories[memoryType]
		if not memoryText then
			local newText = self.agentBrainDebuggerGui.Frame.REFERENCE:Clone() :: TextLabel
			newText.Visible = true
			newText.Name = "A" .. memoryType.name
			newText.Text = memoryType.name .. ":"
			newText.Parent = self.agentBrainDebuggerGui.Frame
			self.textlabelsByMemories[memoryType] = newText
			memoryText = newText
		end

		if memoryOptional:isEmpty() then
			memoryText.Text = memoryType.name .. ": -"
			continue
		end

		local memoryValue = memoryOptional:get():getValue()

		if typeof(memoryValue) == "Instance" then
			memoryText.Text = memoryType.name .. ": " .. memoryValue.Name
			continue
		end

		if typeof(memoryValue) == "table" then
			local finalEndText = ""

			for k, v in pairs(memoryValue) do
				finalEndText = finalEndText .. " " .. string.format(`\{ [{k}]: {v} \}`)
			end
			memoryText.Text = memoryType.name .. ": " .. finalEndText
			continue
		end

		memoryText.Text = memoryType.name .. ": " .. tostring(memoryValue)
	end

	for activity in pairs(agentBrain.activeActivities) do
		local activityText = self.textlabelsByActivities[activity]
		if not self.textlabelsByActivities[activity] then
			local newText = self.agentBrainDebuggerGui.Frame.REFERENCE:Clone() :: TextLabel
			newText.Visible = true
			newText.Name = "B" .. activity.name
			newText.Text = activity.name
			newText.TextColor3 = Color3.new(0, 0.898039, 1)
			newText.Parent = self.agentBrainDebuggerGui.Frame
			self.textlabelsByActivities[activity] = newText
			activityText = newText
		end
		activityText.Visible = true
	end

	for activity, textLabel in pairs(self.textlabelsByActivities) do
		if not agentBrain.activeActivities[activity] then
			self.textlabelsByActivities[activity] = nil
			textLabel:Destroy()
		end
	end
end

return BrainDebugger