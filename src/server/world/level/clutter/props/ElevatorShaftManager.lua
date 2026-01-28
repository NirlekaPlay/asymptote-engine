--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Bounds = require(ReplicatedStorage.shared.util.math.geometry.Bounds)
local Elevator = require(ServerScriptService.server.world.level.clutter.props.Elevator)

local STATES = {
	DOORS_OPENED = 0,
	DOORS_OPENING = 1,
	DOORS_CLOSED = 2,
	DOORS_CLOSING = 3,
	MOVING = 4
}

local TRAVEL_TIME = 5

--[=[
	@class ElevatorShaftManager
]=]
local ElevatorShaftManager = {}
ElevatorShaftManager.__index = ElevatorShaftManager

export type ElevatorShaftManager = typeof(setmetatable({} :: {
	elevators: { [number]: Elevator.Elevator },
	currentElevator: Elevator.Elevator?,
	targetElevator: Elevator.Elevator?,
	moveTimer: number,
	currentState: number
}, ElevatorShaftManager))

function ElevatorShaftManager.new(): ElevatorShaftManager
	return setmetatable({
		elevators = {},
		currentElevator = nil :: Elevator.Elevator?,
		targetElevator = nil :: Elevator.Elevator?,
		moveTimer = 0
	}, ElevatorShaftManager) :: ElevatorShaftManager
end

function ElevatorShaftManager.setCurrentElevator(
	self: ElevatorShaftManager,
	elevator: Elevator.Elevator
): ()
	self.currentElevator = elevator
	elevator.cartPresent = true
end

function ElevatorShaftManager.registerElevator(
	self: ElevatorShaftManager,
	elevator: Elevator.Elevator,
	id: number
): ()

	self.elevators[id] = elevator
end

function ElevatorShaftManager.requestToId(
	self: ElevatorShaftManager,
	elevatorId: number
): ()
	local target = self.elevators[elevatorId]
	if not target or target == self.currentElevator or self.targetElevator == target then
		print("returned")
		if not target then
			warn(`Attempt to move elevator cart to elevator id {target} that is not registered`)
		end
		return
	end

	self.targetElevator = target
	
	-- Ensure the current elevator closes its doors before we move
	if self.currentElevator then
		self.currentElevator.cartPresent = false
	end
	
	self.currentState = STATES.MOVING
	self.moveTimer = TRAVEL_TIME
end

function ElevatorShaftManager.update(self: ElevatorShaftManager, deltaTime: number): ()
	if self.currentState == STATES.MOVING then
		self.moveTimer -= deltaTime
		
		if self.moveTimer <= 0 then
			local oldElevator = self.currentElevator
			local newElevator = self.targetElevator

			if oldElevator and newElevator then

				if oldElevator and newElevator then
					-- TODO: This should be handled in the elevator itself.
					local playersToMove: {Player} = {}
					for _, player in Players:GetPlayers() do
						local char = player.Character
						local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
						
						if root then
							local inBounds = Bounds.isPosInBounds(
								root.Position,
								oldElevator.bounds.cframe,
								oldElevator.bounds.size
							)
							if inBounds then
								table.insert(playersToMove, player)
							end
						end
					end
					newElevator:teleportPlayersToSelf(playersToMove, oldElevator.bounds.cframe)

					oldElevator.cartPresent = false
					self:setCurrentElevator(newElevator)
				end
			end
			
			self.targetElevator = nil
			self.currentState = STATES.DOORS_CLOSED
		end
	end
end

function ElevatorShaftManager.onLevelRestart(self: ElevatorShaftManager, initElevId: number): ()
	self.currentState = STATES.DOORS_CLOSED
	self.moveTimer = 0
	self.targetElevator = nil

	for _, elevator in self.elevators do
		elevator.cartPresent = false
	end

	local startingElev = self.elevators[initElevId]
	if initElevId then
		self:setCurrentElevator(startingElev)
	else
		self.currentElevator = nil
	end
end

return ElevatorShaftManager