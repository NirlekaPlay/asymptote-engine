--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local EntityManager = require(ServerScriptService.server.entity.EntityManager)

--[=[
	@class EntityUtils

	A bunch of utility functions so we don't have to deal
	with the bullshits Nico has given us for an entity system.

	Jk Nico you still did something to progress the engine.
]=]
local EntityUtils = {}

type AnEntity = EntityManager.StaticEntity | EntityManager.DynamicEntity

--[=[
	Returns `true` if the given `entity` object is a Player.
	Otherwise, `false`.
]=]
function EntityUtils.isPlayer(entity: AnEntity): boolean
	if entity.isStatic then
		return false
	else
		if entity.name == "Player" and entity.instance and (entity.instance :: Player):IsA("Player") then
			return true
		end
	end

	return false
end

--[=[
	Returns a `Player` instance if the given `entity` is a Player.
	Otherwise, `nil`.
]=]
function EntityUtils.ifPlayerThenGet(entity: AnEntity): Player?
	if EntityUtils.isPlayer(entity) then
		return (entity :: any).instance
	else
		return nil
	end
end

--[=[
	Returns a `Player` instance if the given `entity` is a Player.
	Otherwise throws an error.
]=]
function EntityUtils.getPlayerOrThrow(entity: AnEntity): Player
	if EntityUtils.isPlayer(entity) then
		return (entity :: any).instance
	else
		return error(`Entity '{entity.uuid}' is not a valid Player!`)
	end
end

--[=[
	Returns a `Vector3` representing the "position" of the given `entity`.
	Otherwise throws an error.
]=]
function EntityUtils.getPos(entity: AnEntity): Vector3
	if entity.isStatic then
		return entity.position
	else
		local instance = entity.instance :: Instance?
		if instance then
			if instance:IsA("Model") and instance.PrimaryPart then
				return (instance.PrimaryPart :: BasePart).Position
			elseif instance:IsA("BasePart") then
				return instance.Position
			elseif instance:IsA("Player") then
				-- oh fuck no.
				if instance.Character then
					if instance.Character.PrimaryPart then
						return instance.Character.PrimaryPart.Position
					end
				end
			end
		end
	end

	error(`Entity '{entity.uuid}' does not have a valid way to get position!`)
end

return EntityUtils