--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local TeleportCommand = {}

function TeleportCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	local teleportNode = dispatcher:register(
		LiteralArgumentBuilder.new("teleport")
			:andThen(
				RequiredArgumentBuilder.new("entity1", EntitySelectorParser)
					:executes(function(c)
						local selectorData = c:getArgument("entity1") :: any
						local source = c:getSource() :: Player

						if not source.Character or not source.Character.PrimaryPart then
							error("Player has no character.")
						end

						local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
						if next(targets) == nil then
							error("No targets to teleport to found.")
						end

						TeleportCommand.teleportEntityToEntity(source, targets[1])
					end)

					:andThen(
						RequiredArgumentBuilder.new("entity2", EntitySelectorParser)
							:executes(function(c)
								local targetData = c:getArgument("entity2")
								local sourceData = c:getArgument("entity1")
								local cmdSource = c:getSource()
								
								local targets = EntitySelectorParser.resolvePlayerSelector(targetData, cmdSource)
								local sources = EntitySelectorParser.resolvePlayerSelector(sourceData, cmdSource)
								
								if #targets == 0 then error("No target found") end
								if #sources == 0 then error("No source found") end
								
								local targetPos = TeleportCommand.getEntityPosition(targets[1])
								if not targetPos then error("Target has no valid position") end
								
								for _, source in sources do
									TeleportCommand.teleportEntity(source, targetPos)
								end
								
								return #sources
							end)
					)
			)
	)

	dispatcher:register(
		LiteralArgumentBuilder.new("tp")
			:redirect(teleportNode)
)
end

function TeleportCommand.getEntityPosition(entity: Instance): CFrame?
	if typeof(entity) == "Instance" and entity:IsA("Player") then
		local char = entity.Character
		return char and char.PrimaryPart and char.PrimaryPart.CFrame
	elseif typeof(entity) == "Instance" and entity:FindFirstChildOfClass("Humanoid") then
		return entity.PrimaryPart and entity.PrimaryPart.CFrame
	end
	return nil
end

function TeleportCommand.teleportEntityToEntity(from: Instance, to: Instance): ()
	local toCframe = TeleportCommand.getEntityPosition(to)
	if not toCframe then
		error("Cannot get teleport target CFrame.")
	end

	TeleportCommand.teleportEntity(from, toCframe)
end

function TeleportCommand.teleportEntity(entity: Instance, targetCFrame: CFrame): ()
	if entity:IsA("Player") then
		local char = entity.Character
		if char then
			char:PivotTo(targetCFrame)
		end
	elseif entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") then
		entity:PivotTo(targetCFrame)
	end
end

return TeleportCommand