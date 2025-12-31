--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

local DEFAULT_VOLUME = 0.5
local DEFAULT_NO_LOOP = false

local function isEmptyString(str: string?): boolean
	return not str or string.match(str, "%S") == nil
end

local function getOrCreateSoundGroup(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end

	local new = Instance.new("SoundGroup")
	new.Name = name
	new.Parent = SoundService
	return new
end

local musicSoundGroup = getOrCreateSoundGroup("Music")
local worldMusicControllers: { MusicController } = {}

--[=[
	@class MusicController

	Control which music(s) is/are playing and under what circumstances.
]=]
local MusicController = {}
MusicController.__index = MusicController

export type MusicController = StateComponent.StateComponent & typeof(setmetatable({} :: {
	parsedActivePriority: ExpressionParser.ASTNode,
	soundInst: Sound,
	varsChangedConn: RBXScriptConnection,
	currentPriority: number
}, MusicController))

function MusicController.fromInstance(inst: Instance, context: ExpressionContext.ExpressionContext): MusicController
	local activePriorityStr = inst:GetAttribute("ActivePriority") :: string?
	if not activePriorityStr or isEmptyString(activePriorityStr) then
		error(`Failed to create MusicControl StateComponent: 'ActivePriority' attribute must be a valid expression`)
	end

	local trackId = inst:GetAttribute("TrackId") :: string
	if isEmptyString(trackId) then
		error("MusicController requires a valid TrackId")
	end

	local parsed = ExpressionParser.fromString(activePriorityStr):parse() :: ExpressionParser.ASTNode
	local usedVars = ExpressionParser.getVariablesSet(parsed)

	local volume = inst:GetAttribute("Volume") :: number? or DEFAULT_VOLUME
	local noLoop = inst:GetAttribute("NoLoop") :: boolean? or DEFAULT_NO_LOOP

	local sound = Instance.new("Sound")
	sound.Name = "MusicTrack"
	sound.SoundId = "rbxassetid://" .. trackId:match("%d+") :: string
	sound.Volume = volume
	sound.Looped = not noLoop
	sound.SoundGroup = musicSoundGroup
	sound.Parent = musicSoundGroup

	local self = {
		parsedActivePriority = parsed,
		soundInst = sound,
		noLoop = noLoop,
		currentPriority = ExpressionParser.evaluate(parsed, context)
	}

	self.varsChangedConn = GlobalStatesHolder.getStatesChangedConnection():Connect(function(varName, varVal)
		if usedVars[varName] then
			self.currentPriority = ExpressionParser.evaluate(parsed, context)
			MusicController.evaluateStack()
		end
	end)

	local newMusicController = setmetatable(self, MusicController)
	table.insert(worldMusicControllers, newMusicController :: MusicController)

	return newMusicController :: MusicController
end

function MusicController.onLevelRestart(self: MusicController): ()
	if self.soundInst.Playing then
		self.soundInst:Stop()
	end
end

function MusicController.evaluateStack(): ()
	if next(worldMusicControllers) == nil then
		return
	end

	local maxPriority = -math.huge
	
	-- Determine the current peak priority in the stack
	for _, controller in worldMusicControllers do
		if controller.currentPriority > maxPriority then
			maxPriority = controller.currentPriority
		end
	end

	-- Stop everything if max priority is negative
	-- Otherwise, play only those that match the max priority
	for _, controller in worldMusicControllers do
		local isPlaying = controller.soundInst.IsPlaying
		local shouldPlay = (maxPriority >= 0) and (controller.currentPriority == maxPriority)

		if shouldPlay then
			if not isPlaying then
				controller.soundInst:Play()
			end
		else
			if isPlaying then
				controller.soundInst:Stop()
			end
		end
	end
end

return MusicController