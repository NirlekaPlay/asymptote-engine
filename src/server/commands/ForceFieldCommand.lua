--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local ForceFieldCommand = {}

local FORCE_FIELD_INST_NAME = "CmdForceField"

function ForceFieldCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("forcefield")
			:executes(function(c)
				local playerSource = c:getSource() :: Player
				if not playerSource.Character then
					error("Player does not have a character")
				end

				ForceFieldCommand.addForceFieldToCharacter(playerSource.Character)
			end)
		
		:andThen(
			RequiredArgumentBuilder.new("targets", EntitySelectorParser)
				:executes(function(c)
					local selectorData = c:getArgument("targets") :: any
					local source = c:getSource()
					local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
					if next(targets) == nil then
						error("No targets found.")
					end
					ForceFieldCommand.addForceFieldToEntities(targets)
				end)
			
			:andThen(
				LiteralArgumentBuilder.new("pop")
					:executes(function(c)
						local selectorData = c:getArgument("targets") :: any
						local source = c:getSource()
						local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
						if next(targets) == nil then
							error("No targets found.")
						end
						ForceFieldCommand.removeForceFieldFromEntities(targets)
				end)
			)
		)
	)
end

function ForceFieldCommand.addForceFieldToEntities(entities: {Instance}): ()
	for _, entity in pairs(entities) do
		if entity:IsA("Player") and entity.Character then
			ForceFieldCommand.addForceFieldToCharacter(entity.Character)
		else
			ForceFieldCommand.addForceFieldToCharacter(entity)
		end
	end
end

function ForceFieldCommand.removeForceFieldFromEntities(entities: {Instance}): ()
	for _, entity in pairs(entities) do
		if entity:IsA("Player") and entity.Character then
			ForceFieldCommand.removeForceFieldFromCharacter(entity.Character)
		else
			ForceFieldCommand.removeForceFieldFromCharacter(entity)
		end
	end
end

function ForceFieldCommand.removeForceFieldFromCharacter(character: Instance): ()
	local existingForceField = character:FindFirstChildOfClass("ForceField")
	if existingForceField then
		existingForceField:Destroy()
		return
	end
end

function ForceFieldCommand.addForceFieldToCharacter(character: Instance): ()
	local existingForceField = character:FindFirstChild(FORCE_FIELD_INST_NAME)
	if existingForceField and existingForceField:IsA("ForceField") then
		return
	end

	local newForcefield = Instance.new("ForceField")
	newForcefield.Visible = true
	newForcefield.Name = FORCE_FIELD_INST_NAME
	newForcefield.Parent = character
end

return ForceFieldCommand