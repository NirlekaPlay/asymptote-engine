--!nonstrict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Agent = require(ServerScriptService.server.Agent)
local Activity = require(ServerScriptService.server.ai.behavior.Activity)
local BehaviorControl = require(ServerScriptService.server.ai.behavior.BehaviorControl)
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
		textlabelsByActivities = {} :: { [Activity.Activity]: TextLabel},
		textlabelsByBehaviors = {} :: { [BehaviorControl.BehaviorControl<Agent.Agent>]: TextLabel},
		miscsTextLabels = {} :: { [string]: TextLabel }
	}, BrainDebugger)
end

export type BrainDebugger = typeof(BrainDebugger.new())

function BrainDebugger.update(self: BrainDebugger): ()
	if not self.agent:isAlive() then return end
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
			newText.TextColor3 = Color3.new(0.282353, 1, 0)
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

	local runningBehaviorsSet = {} :: { [BehaviorControl.BehaviorControl<Agent.Agent>]: true }
	for _, behaviorControl in ipairs(agentBrain:getRunningBehaviors()) do
		runningBehaviorsSet[behaviorControl] = true
	end

	for behaviorControl in pairs(runningBehaviorsSet) do
		local activityText = self.textlabelsByBehaviors[behaviorControl]
		if not self.textlabelsByBehaviors[behaviorControl] then
			local newText = self.agentBrainDebuggerGui.Frame.REFERENCE:Clone() :: TextLabel
			newText.Visible = true
			newText.Name = "C" .. behaviorControl.name
			newText.Text = behaviorControl.name
			newText.TextColor3 = Color3.new(0, 0.898039, 1)
			newText.Parent = self.agentBrainDebuggerGui.Frame
			self.textlabelsByBehaviors[behaviorControl] = newText
			activityText = newText
		end
		activityText.Visible = true
	end

	for behaviorControl, textLabel in pairs(self.textlabelsByBehaviors) do
		if not runningBehaviorsSet[behaviorControl] then
			self.textlabelsByBehaviors[behaviorControl] = nil
			textLabel:Destroy()
		end
	end

	local humanoid = self.agent.character:FindFirstChildOfClass("Humanoid")
	local healthText = self.miscsTextLabels["health"]
	if not healthText then
		local newText = self.agentBrainDebuggerGui.Frame.REFERENCE:Clone() :: TextLabel
		newText.Visible = true
		newText.Name = "D" .. "health"
		newText.Text = ""
		newText.Parent = self.agentBrainDebuggerGui.Frame
		self.miscsTextLabels["health"] = newText
		healthText = newText
	end

	healthText.Text = `health: {humanoid.Health} / {humanoid.MaxHealth}`
end

function BrainDebugger.destroyGui(self: BrainDebugger): ()
	if self.agentBrainDebuggerGui then
		self.agentBrainDebuggerGui:Destroy()
	end
end

return BrainDebugger