--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local TriggerZone = require(ServerScriptService.server.world.level.clutter.props.triggers.TriggerZone)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local DEBUG_TRIGGER_BOUNDS = true

--[=[
	@class MissionEndZone

	Zones used to end missions when all Players are in it.
]=]
local MissionEndZone = {}
MissionEndZone.__index = MissionEndZone

export type MissionEndZone = Prop.Prop & typeof(setmetatable({} :: {
	enabled: boolean,
	targetVariableName: string,
	parsedEnabledExpression: ExpressionParser.ASTNode?,
	zonePart: BasePart
}, MissionEndZone))

function MissionEndZone.new(
	enabled: boolean,
	targetVariableName: string,
	parsedEnabledExpression: ExpressionParser.ASTNode?,
	zonePart: BasePart
): MissionEndZone
	return setmetatable({
		enabled = false,
		targetVariableName = targetVariableName,
		parsedEnabledExpression = parsedEnabledExpression,
		zonePart = zonePart
	}, MissionEndZone) :: MissionEndZone
end

function MissionEndZone.createFromPlaceholder(
	placeholder: BasePart, model: Model?, serverLevel: ServerLevel.ServerLevel
): MissionEndZone
	local expressionStr = placeholder:GetAttribute("Active") :: string
	local targetVariableName = placeholder:GetAttribute("Variable") :: string
	local evaluated: any
	local parsedExpression
	if not expressionStr or expressionStr == "" then
		evaluated = true
	else
		parsedExpression = ExpressionParser.fromString(expressionStr):parse()
		evaluated = ExpressionParser.evaluate(parsedExpression, serverLevel:getExpressionContext())
	end

	local newTriggerZone = MissionEndZone.new(
		evaluated,
		targetVariableName,
		parsedExpression,
		placeholder
	)

	TriggerZone.makePartStatic(placeholder)

	if DEBUG_TRIGGER_BOUNDS then
		Draw.box(placeholder.CFrame, placeholder.Size)
	end

	return newTriggerZone
end

function MissionEndZone.update(self: MissionEndZone, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
	if serverLevel:getMissionManager():isConcluded() then
		return
	end
	local canCheck = false
	if self.parsedEnabledExpression == nil then
		canCheck = true
	else
		local evaluated = ExpressionParser.evaluate(
			self.parsedEnabledExpression, serverLevel:getExpressionContext()
		)

		canCheck = not not evaluated -- don't ask.
	end

	if not canCheck then
		return
	end

	local validPlayers: {Player} = {}
	local playerPositions: { [Player]: Vector3 } = {}
	for _, player in Players:GetPlayers() do
		local isValid, pos = MissionEndZone.isValidPlayer(player)
		if isValid and pos then
			table.insert(validPlayers, player)
			playerPositions[player] = pos
		end
	end

	local numOfValidPlayers = #validPlayers
	local playersInZone = 0

	if numOfValidPlayers <= 0 then
		return
	end

	for _, player in validPlayers do
		local playerPos = playerPositions[player]
		if not playerPos then
			continue
		end

		local isInZone = TriggerZone.isPosInPart(playerPos, self.zonePart)
		if isInZone then
			playersInZone += 1
		end
	end

	if playersInZone < numOfValidPlayers then
		return
	end
	
	serverLevel:getMissionManager():concludeMission()
end

function MissionEndZone.isValidPlayer(player: Player): (boolean, Vector3?)
	local pos = TriggerZone.getPlayerPos(player)
	if not pos then
		return false, nil
	end

	local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, nil
	end

	return true, pos
end

function MissionEndZone.onLevelRestart(self: MissionEndZone): ()
	return
end

return MissionEndZone