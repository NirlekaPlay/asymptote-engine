--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServerLevel = require(ServerScriptService.server.world.level.ServerLevel)
local Elevator = require(ServerScriptService.server.world.level.clutter.props.Elevator)
local ElevatorShaftManager = require(ServerScriptService.server.world.level.clutter.props.ElevatorShaftManager)
local StateComponent = require(ServerScriptService.server.world.level.components.registry.StateComponent)
local GlobalStatesHolder = require(ServerScriptService.server.world.level.states.GlobalStatesHolder)

--[=[
	@class ElevatorShaftController

	Responsible for elevator functions of a single shaft.
]=]
local ElevatorShaftController = {}
ElevatorShaftController.__index = ElevatorShaftController

export type ElevatorShaftController = StateComponent.StateComponent & typeof(setmetatable({} :: {
	shaftManager: ElevatorShaftManager.ElevatorShaftManager,
	shaftId: number,
	initialElevatorId: number,
	requestVariableName: string
}, ElevatorShaftController))

function ElevatorShaftController.fromInstance(inst: Instance): ElevatorShaftController
	local shaftId = inst:GetAttribute("ShaftId") :: number?
	if not shaftId then
		error(`Attempt to create an ElevatorShaftController without a shaft id`)
	end

	local initialElevId = inst:GetAttribute("InitialElevId") :: number?
	if not initialElevId then
		error(`Attempt to create an ElevatorShaftController without an initial elevator id`)
	end

	local requestStateName = inst:GetAttribute("RequestState") :: string?
	if not requestStateName then
		error(`Attempt to create an ElevatorShaftController without a variable name for the request`)
	end

	if not GlobalStatesHolder.hasState(requestStateName) then
		GlobalStatesHolder.setState(requestStateName, initialElevId)
	end

	local newShaftManager = ElevatorShaftManager.new()

	local self = setmetatable({
		shaftManager = newShaftManager,
		shaftId = shaftId,
		initialElevatorId = initialElevId,
		requestVariableName = requestStateName
	}, ElevatorShaftController) :: ElevatorShaftController

	local conn = GlobalStatesHolder.getStateChangedConnection(requestStateName):Connect(function(value)
		if value == -1 then
			return
		end
		self.shaftManager:requestToId(value)
		GlobalStatesHolder.setState(requestStateName, -1)
	end)

	return self
end

function ElevatorShaftController.processElevator(self: ElevatorShaftController, elevator: Elevator.Elevator): ()
	if elevator.shaftId == self.shaftId then
		(self.shaftManager :: ElevatorShaftManager.ElevatorShaftManager):registerElevator(elevator, elevator.id)
		if elevator.id == self.initialElevatorId then
			(self.shaftManager :: ElevatorShaftManager.ElevatorShaftManager):setCurrentElevator(elevator)
		end
	end
end

function ElevatorShaftController.onLevelRestart(self: ElevatorShaftController): ()
	self.shaftManager:onLevelRestart(self.initialElevatorId)
end

function ElevatorShaftController.update(self: ElevatorShaftController, deltaTime: number, serverLevel: ServerLevel.ServerLevel): ()
	self.shaftManager:update(deltaTime)
end

return ElevatorShaftController