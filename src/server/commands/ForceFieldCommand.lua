--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local ForceFieldCommand = {}

local FORCE_FIELD_INST_NAME = "CmdForceField"

function ForceFieldCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("forcefield")
			:executes(function(c)
				local source: CommandSourceStack.CommandSourceStack = c:getSource()
				local playerSource = source:getPlayerOrThrow()
				if not playerSource.Character then
					error("Player does not have a character")
				end

				ForceFieldCommand.addForceFieldToCharacter(playerSource.Character)
				return 1
			end)
		
		:andThen(
			CommandHelper.argument("targets", EntityArgument.entities())
				:executes(function(c)
					local targets = EntityArgument.getEntities(c, "targets")
					if next(targets) == nil then
						error("No targets found.")
					end
					ForceFieldCommand.addForceFieldToEntities(c, targets)
					return #targets
				end)
			
			:andThen(
				CommandHelper.literal("pop")
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "targets")
						if next(targets) == nil then
							error("No targets found.")
						end
						ForceFieldCommand.removeForceFieldFromEntities(c, targets)

						return 0
				end)
			)
		)
	)
end

function ForceFieldCommand.addForceFieldToEntities(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, entities: {Instance}): ()
	local numOfPlayers = 0
	local numOfNonPlayers = 0
	for _, entity in pairs(entities) do
		if entity:IsA("Player") and entity.Character then
			numOfPlayers += 1
			ForceFieldCommand.addForceFieldToCharacter(entity.Character)
		else
			numOfNonPlayers += 1
			ForceFieldCommand.addForceFieldToCharacter(entity)
		end
	end

	ForceFieldCommand.informClient(c, numOfPlayers, numOfNonPlayers, true)
end

function ForceFieldCommand.removeForceFieldFromEntities(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, entities: {Instance}): ()
	local numOfPlayers = 0
	local numOfNonPlayers = 0
	for _, entity in pairs(entities) do
		if entity:IsA("Player") and entity.Character then
			numOfPlayers += 1
			ForceFieldCommand.removeForceFieldFromCharacter(entity.Character)
		else
			numOfNonPlayers += 1
			ForceFieldCommand.removeForceFieldFromCharacter(entity)
		end
	end

	ForceFieldCommand.informClient(c, numOfPlayers, numOfNonPlayers, false)
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

--

function ForceFieldCommand.informClient(
	context: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>,
	numOfPlayers: number,
	numOfNonPlayers: number,
	flag: boolean
): ()
	local firstMessage: MutableTextComponent.MutableTextComponent
	if flag then
		firstMessage = MutableTextComponent.literal("Successfully applied forcefield to ")
	else
		firstMessage = MutableTextComponent.literal("Successfully removed forcefield from ")
	end

	firstMessage:appendComponent(
		MutableTextComponent.literal(`{numOfPlayers} `)
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.YELLOW)
			)
			:appendComponent(
				MutableTextComponent.literal(if (numOfPlayers > 1 or numOfPlayers == 0) then "players " else "player ")
					:withStyle(
						TextStyle.empty()
							:withColor(NamedTextColors.DARK_AQUA)
					)
			)
	)		
	:appendString("and ")
	:appendComponent(
		MutableTextComponent.literal(`{numOfNonPlayers} `)
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.SOFT_YELLOW)
			)
	)
	:appendComponent(
		MutableTextComponent.literal("non players.")
			:withStyle(
				TextStyle.empty()
					:withColor(NamedTextColors.MUTED_SOFT_AQUA)
			)
	)

	context:getSource():sendSuccess(firstMessage)
end

return ForceFieldCommand