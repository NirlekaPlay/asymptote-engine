--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)
local Prop = require(ServerScriptService.server.world.level.clutter.props.Prop)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)
local ExpressionParser = require(ReplicatedStorage.shared.util.expression.ExpressionParser)

local ASSET_ID_PREFIX_STR = "rbxassetid://"
local DEFAULT_VOLUME = 1
local DEFAULT_IS_LOOPED = false

--[=[
	@class SoundSource
]=]
local SoundSource = {}
SoundSource.__index = SoundSource

export type SoundSource = Prop.Prop & typeof(setmetatable({} :: {
	parsedPlayCondition: ExpressionParser.ASTNode?,
	parsedVariablesConnections: { [string]: RBXScriptConnection }
}, SoundSource))

function SoundSource.new(
	parsedNode: ExpressionParser.ASTNode?,
	varConns: { [string]: RBXScriptConnection }
): SoundSource
	return setmetatable({
		parsedPlayCondition = parsedNode,
		parsedVariablesConnections = varConns
	}, SoundSource) :: SoundSource
end

function SoundSource.createFromPlaceholder(placeholder: BasePart): SoundSource
	local volume = (placeholder:GetAttribute("Volume") :: number?) or DEFAULT_VOLUME
	local looped = (placeholder:GetAttribute("Looped") :: boolean?) or DEFAULT_IS_LOOPED
	local activeStr = (placeholder:GetAttribute("Active") :: string)

	local sound = Instance.new("Sound")
	sound.Volume = volume
	sound.Looped = looped
	sound.SoundId = ASSET_ID_PREFIX_STR .. tostring((placeholder:GetAttribute("SoundId") :: number?))

	placeholder.Transparency = 1
	placeholder.CanCollide = false
	placeholder.CanQuery = false
	placeholder.CanTouch = false
	placeholder.AudioCanCollide = false

	-- For legacy support
	for _, child in placeholder:GetChildren() do
		child.Parent = sound
		if child:IsA("BaseScript") then
			child.Enabled = true
		end
	end

	sound.Parent = placeholder

	local parsed: ExpressionParser.ASTNode?
	local variablesChangedConn: { [string]: RBXScriptConnection } = {}
	
	if activeStr then
		parsed = ExpressionParser.fromString(activeStr):parse()
		local variablesUsedSet = ExpressionParser.getVariablesSet(parsed)
		local evaluatedResult = ExpressionParser.evaluate(
			parsed, ExpressionContext.new(GlobalStatesHolder.getAllStatesReference())
		)

		if evaluatedResult then
			sound:Play()
		end

		for varName in variablesUsedSet do
			variablesChangedConn[varName] = GlobalStatesHolder.getStateChangedConnection(varName):Connect(function(_)
				local evaluated = ExpressionParser.evaluate(
					parsed, ExpressionContext.new(GlobalStatesHolder.getAllStatesReference())
				)

				if evaluated then
					sound:Play()
				else
					sound:Stop()
				end
			end)
		end
	else
		sound:Play()
	end

	local newSoundSource = SoundSource.new(
		parsed, variablesChangedConn
	)

	return newSoundSource
end

function SoundSource.onLevelRestart(): ()
	-- Should we? No? Alright.

	-- Seriously though, if the level restarts, then the variables
	-- will also reset. And the SoundSource will also update from those,
	-- so no need to disconnect any connections for now.
end

function SoundSource.update(deltaTime: number): ()
	return
end

return SoundSource