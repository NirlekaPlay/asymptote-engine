--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local Vector3ArgumentType = require(ReplicatedStorage.shared.commands.arguments.position.Vector3ArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local TeleportCommand = {}

function TeleportCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	local teleportNode = dispatcher:register(
		CommandHelper.literal("teleport")
			:andThen(
				CommandHelper.argument("location", Vector3ArgumentType.vec3())
					:executes(function(c)
						local source = c:getSource()
						local vec3 = Vector3ArgumentType.resolveAndGetVec3(c, "location", source)
						TeleportCommand.teleportEntity(source:getPlayerOrThrow(), CFrame.new(vec3.X, vec3.Y, vec3.Z), false)
						return 1
					end)
			)

			:andThen(
				CommandHelper.argument("destination", EntityArgument.entities())
					:executes(function(c)
						local sourcePlayer = c:getSource():getPlayerOrThrow()

						if not sourcePlayer.Character or not sourcePlayer.Character.PrimaryPart then
							error("Player has no character.")
						end

						local targets = EntityArgument.getEntities(c, "destination")
						if next(targets) == nil then
							error("No targets to teleport to found.")
						end

						TeleportCommand.teleportEntityToEntity(sourcePlayer, targets[1])

						return 1
					end)
			)

			:andThen(
				CommandHelper.argument("targets", EntityArgument.entities())
					:andThen(
						CommandHelper.argument("destination", EntityArgument.entities())
							:executes(function(c)
								local targets = EntityArgument.getEntities(c, "destination")
								local sources = EntityArgument.getEntities(c, "targets")
								
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
						CommandHelper.argument("location", Vector3ArgumentType.vec3())
							:executes(function(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>)
								local targets = EntityArgument.getEntities(c, "targets")
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
		CommandHelper.literal("tp")
			:redirect(teleportNode)
	)
end

function TeleportCommand.getEntityPosition(entity: Instance): CFrame?
	if entity:IsA("Player") then
		local char = entity.Character
		return char and char.PrimaryPart and (char.PrimaryPart :: BasePart).CFrame
	elseif entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") then
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