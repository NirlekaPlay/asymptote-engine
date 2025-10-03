--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local TeleportCommand = {}

function TeleportCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	local teleportNode = dispatcher:register(
		LiteralArgumentBuilder.new("teleport")
			:andThen(
				RequiredArgumentBuilder.new("location", Vector3ArgumentType.vec3())
					:executes(function(c)
						local source = c:getSource()
						local vec3 = Vector3ArgumentType.resolveAndGetVec3(c, "location", source)
						TeleportCommand.teleportEntity(source, CFrame.new(vec3.X, vec3.Y, vec3.Z), false)
						return 1
					end)
			)

			:andThen(
				RequiredArgumentBuilder.new("destination", EntitySelectorParser.entities())
					:executes(function(c)
						local selectorData = c:getArgument("destination") :: any
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
			)

			:andThen(
				RequiredArgumentBuilder.new("targets", EntitySelectorParser.entities())
					:andThen(
						RequiredArgumentBuilder.new("destination", EntitySelectorParser.entities())
							:executes(function(c)
								local targetData = c:getArgument("destination")
								local sourceData = c:getArgument("targets")
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

					:andThen(
						RequiredArgumentBuilder.new("location", Vector3ArgumentType.vec3())
							:executes(function(c)
								print("called")
								local targetData = c:getArgument("targets")
								local cmdSource = c:getSource()
								local targets = EntitySelectorParser.resolvePlayerSelector(targetData, cmdSource)
								local source = c:getSource()
								local vec3 = Vector3ArgumentType.resolveAndGetVec3(c, "location", source)
								
								for _, target in targets do
									TeleportCommand.teleportEntity(target, CFrame.new(vec3.X, vec3.Y, vec3.Z), false)
								end

								return #targets
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

function TeleportCommand.teleportEntity(entity: Instance, targetCFrame: CFrame, rotated: boolean?): ()
	if entity:IsA("Player") then
		local char = entity.Character
		if char then
			if rotated then
				char:PivotTo(targetCFrame)
			else
				local current = char:GetPivot()
				local posOnly = CFrame.new(targetCFrame.Position) * (current - current.Position)
				char:PivotTo(posOnly)
			end
		end
	elseif entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") then
		if rotated then
			entity:PivotTo(targetCFrame)
		else
			local current = entity:GetPivot()
			local posOnly = CFrame.new(targetCFrame.Position) * (current - current.Position)
			entity:PivotTo(posOnly)
		end
	end
end

return TeleportCommand