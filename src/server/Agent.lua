--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Brain = require(ServerScriptService.server.ai.Brain)
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local BubbleChatControl = require(ServerScriptService.server.ai.control.BubbleChatControl)
local FaceControl = require(ServerScriptService.server.ai.control.FaceControl)
local LookControl = require(ServerScriptService.server.ai.control.LookControl)
local TalkControl = require(ServerScriptService.server.ai.control.TalkControl)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)

--[=[
	@class Agent

	An abstract Agent.
]=]
local Agent = {}
Agent.__index = Agent

export type Agent = typeof(setmetatable({} :: {
	uuid: string,
	characterName: string,
	character: Model,
	alive: boolean,
	brain: Brain.Brain<Agent>,
	bodyRotationControl: BodyRotationControl.BodyRotationControl,
	bubbleChatControl: BubbleChatControl.BubbleChatControl,
	talkControl: TalkControl.TalkControl,
	lookControl: LookControl.LookControl,
	faceControl: FaceControl.FaceControl,
	pathNavigation: PathNavigation.PathNavigation,
	random: Random,
	serverLevel: ServerLevel.ServerLevel
}, Agent))

function Agent.isAlive(self: Agent): boolean
	return self.alive
end

function Agent.getCharacterName(self: Agent): string
	return self.characterName
end

function Agent.getBrain(self: Agent): Brain.Brain<Agent>
	return self.brain
end

function Agent.getFaceControl(self: Agent): FaceControl.FaceControl
	return self.faceControl
end

function Agent.getNavigation(self: Agent): PathNavigation.PathNavigation
	return self.pathNavigation
end

function Agent.getRandom(self: Agent): Random
	return self.random
end

function Agent.getServerLevel(self: Agent): ServerLevel.ServerLevel
	return self.serverLevel
end

function Agent.getUuid(self: Agent): string
	return self.uuid
end

function Agent.getBodyRotationControl(self: Agent): BodyRotationControl.BodyRotationControl
	return self.bodyRotationControl
end

function Agent.getLookControl(self: Agent): LookControl.LookControl
	return self.lookControl
end

function Agent.getBubbleChatControl(self: Agent): BubbleChatControl.BubbleChatControl
	return self.bubbleChatControl
end

function Agent.getTalkControl(self: Agent): TalkControl.TalkControl
	return self.talkControl
end

function Agent.getPrimaryPart(self: Agent): BasePart
	return self.character.PrimaryPart :: BasePart
end

return Agent