--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local DEBUG_TRIGGER_BOUNDS = false

--[=[
	@class TriggerZone

	TriggerZones are used to set variables coresponding to the amount of Players
	whose HumanoidRootPart position is within the bounds of the TriggerZone.
]=]
local TriggerZone = {}
TriggerZone.__index = TriggerZone

export type TriggerZone = Prop.Prop & typeof(setmetatable({} :: {
	enabled: boolean,
	targetVariableName: string,
	parsedEnabledExpression: ExpressionParser.ASTNode?,
	zonePart: BasePart
}, TriggerZone))

function TriggerZone.new(
	enabled: boolean,
	targetVariableName: string,
	parsedEnabledExpression: ExpressionParser.ASTNode?,
	zonePart: BasePart
): TriggerZone
	return setmetatable({
		enabled = false,
		targetVariableName = targetVariableName,
		parsedEnabledExpression = parsedEnabledExpression,
		zonePart = zonePart
	}, TriggerZone) :: TriggerZone
end

function TriggerZone.createFromPlaceholder(
	placeholder: BasePart, model: Model?, serverLevel: ServerLevel.ServerLevel
): TriggerZone
	local expressionStr = placeholder:GetAttribute("Active") :: string
	local targetVariableName = placeholder:GetAttribute("Variable") :: string

	local parsedExpression = ExpressionParser.fromString(expressionStr):parse()
	
	local newTriggerZone = TriggerZone.new(
		ExpressionParser.evaluate(parsedExpression, serverLevel:getExpressionContext()),
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

function TriggerZone.update(self: TriggerZone, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
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

	local playersInZone = 0

	for _, player in Players:GetPlayers() do
		local playerPos = TriggerZone.getPlayerPos(player)
		if not playerPos then
			continue
		end

		local isInZone = TriggerZone.isPosInPart(playerPos, self.zonePart)
		if isInZone then
			playersInZone += 1
		end
	end

	GlobalStatesHolder.setState(self.targetVariableName, playersInZone)
end

function TriggerZone.makePartStatic(part: BasePart): ()
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.AudioCanCollide = false
end

function TriggerZone.getPlayerPos(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return nil
	end

	return humanoidRootPart.Position
end

function TriggerZone.isPosInPart(pos: Vector3, part: BasePart): boolean
	local v3 = part.CFrame:PointToObjectSpace(pos)
	return (math.abs(v3.X) <= part.Size.X / 2)
		and (math.abs(v3.Y) <= part.Size.Y / 2)
		and (math.abs(v3.Z) <= part.Size.Z / 2)
end

function TriggerZone.onLevelRestart(self: TriggerZone): ()
	return
end

--

function TriggerZone.destroy(self: TriggerZone): ()
	return
end

return TriggerZone