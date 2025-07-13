--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")

local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local MemoryModuleTypes = require(ServerScriptService.server.ai.memory.MemoryModuleTypes)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local PlayerStatusReg = require(ServerScriptService.server.player.PlayerStatusReg)
local Statuses = require(ServerScriptService.server.player.Statuses)
local Goal = require("./Goal")

local PursueTrespasserGoal = {}
PursueTrespasserGoal.__index = PursueTrespasserGoal

export type PursueTrespasserGoal = typeof(setmetatable({} :: {
	agent: any,
	giveUpTimer: number,
	shouldContinue: boolean,
	plrsLastKnownLocation: { [Player]: Vector3 },
	waypointReachedConnection: RBXScriptConnection
}, PursueTrespasserGoal)) & Goal.Goal

function PursueTrespasserGoal.new(agent): PursueTrespasserGoal
	return setmetatable({
		flags = {
			"PURSUING"
		},
		agent = agent,
		giveUpTimer = 5,
		shouldContinue = true,
		plrsLastKnownLocation = {},
		waypointReachedConnection = nil
	}, PursueTrespasserGoal)
end

function PursueTrespasserGoal.canUse(self: PursueTrespasserGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	local isSus = susMan.currentState == "ALERTED"
	if isSus then
		self.shouldContinue = true
	end
	return isSus and self.shouldContinue
end

function PursueTrespasserGoal.canContinueToUse(self: PursueTrespasserGoal): boolean
	return (self:canUse() and self.shouldContinue)
end

function PursueTrespasserGoal.isInterruptable(self: PursueTrespasserGoal): boolean
	return true
end

function PursueTrespasserGoal.getFlags(self: PursueTrespasserGoal): {Flag}
	return self.flags
end

-- the amount of fucks the guard gives to not puruse the player when close
local MIN_DISTANCE_TO_PLAYER = 10
-- the amount of distance where the guard actually gives a shit to chase the player
-- it will not stop running towards the damn soul until MIN_DISTANCE_TO_PLAYER is met.
local MIN_DISTANCE_FROM_PLAYER = 15
-- i should probably make these variables more clear but too bad! ill regret it later.
local GIVE_UP_TIME = 5

function PursueTrespasserGoal.start(self: PursueTrespasserGoal): ()
	local trespasser = (self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement).focusingSuspect
	if not trespasser then
		-- how tf did we even got here in the first place?
		return
	end

	-- why bother safe accessing at this point
	local agentPrimaryPart = self.agent:getPrimaryPart()
	local trespasserPrimaryPart = trespasser.Character.PrimaryPart

	local distance = (agentPrimaryPart.Position - trespasserPrimaryPart.Position).Magnitude
	-- what the fuck.
	-- uh the poor sod got shit vision so i do this temporarily.
	self.agent.sensors[1].sightRadius = 90

	-- i did, infact, regret it.
	if distance <= MIN_DISTANCE_TO_PLAYER then
		print("Oi ya mate! Ya not supposed to be here, eh?")
	elseif distance >= MIN_DISTANCE_FROM_PLAYER then
		print(">:O")
		print("Ive got a trespasser here!")
		self.agent:getNavigation():moveTo(trespasserPrimaryPart.Position)
	else
		print("the shit?")
	end
	self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingSuspect.Character.PrimaryPart.Position)
end

function PursueTrespasserGoal.stop(self: PursueTrespasserGoal): ()
	
end

local function moveToFuckingTarget(self: PursueTrespasserGoal, trespasserPrimaryPart: BasePart, nav)
	print("No connection")
	self.reachedConnection = nav.pathfinder.Reached:Connect(function()
		nav:moveTo(trespasserPrimaryPart.Position)
	end)

	self.waypointReachedConnection = nav.pathfinder.WaypointReached:Connect(function()
		nav:moveTo(trespasserPrimaryPart.Position)
	end)

	self.blockedConnection = nav.pathfinder.Blocked:Connect(function()
		nav:moveTo(trespasserPrimaryPart.Position)
	end)

	-- nah fuck you at this point.
	self.errorConnection = nav.pathfinder.Error:Connect(function()
		nav:moveTo(trespasserPrimaryPart.Position)
	end)

	nav:moveTo(trespasserPrimaryPart.Position)
end

local function disconnectConnections(self)
	if self.reachedConnection then
		self.reachedConnection:Disconnect()
		self.reachedConnection = nil
	end

	if self.waypointReachedConnection then
		self.waypointReachedConnection:Disconnect()
		self.waypointReachedConnection = nil
	end

	if self.blockedConnection then
		self.blockedConnection:Disconnect()
		self.blockedConnection = nil
	end

	if self.errorConnection then
		self.errorConnection:Disconnect()
		self.errorConnection = nil
	end
end

function PursueTrespasserGoal.update(self: PursueTrespasserGoal, deltaTime: number): ()
	-- oh god WHAT HAVE I CREATED.
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	local trespasser = susMan.focusingSuspect
	local agentPrimaryPart = self.agent:getPrimaryPart()
	local trespasserPrimaryPart = trespasser.Character.PrimaryPart
	local nav = self.agent:getNavigation() :: PathNavigation.PathNavigation

	if not self.plrsLastKnownLocation[trespasser] then
		self.plrsLastKnownLocation[trespasser] = trespasser.Character.PrimaryPart.Position
	end

	--[[if self.giveUpTimer <= 0 then
		self.agent.sensors[1].sightRadius = 20
		self.agent:getBodyRotationControl():setRotateTowards(nil)
		self.shouldContinue = false
		susMan.currentState = "CALM"
	end

	local agentVisiblePlayersMemory = (self.agent.memories[MemoryModuleTypes.VISIBLE_PLAYERS] :: ExpireableValue.ExpireableValue<{ [Player]: true }>).value
	if not agentVisiblePlayersMemory[trespasser] then
		--nav:moveTo(self.plrsLastKnownLocation[trespasser])
		print("Ive lost the trespasser goddamit!")
		--nav:stop()
		self.giveUpTimer -= deltaTime
		print(self.giveUpTimer)
		return
	else
		self.giveUpTimer = GIVE_UP_TIME
		local status = PlayerStatusReg.getSuspiciousLevel(trespasser).statuses
		local isTrespassing = status[Statuses.PLAYER_STATUSES.MINOR_TRESPASSING] or status[Statuses.PLAYER_STATUSES.MAJOR_TRESPASSING]
		-- trespasser aint trespassing
		if not isTrespassing then
			print("oh well he left")
			susMan.currentState = "CALM"
			susMan.suspicionLevels[trespasser] = 0
			return
		end
	end]]

	self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingSuspect.Character.PrimaryPart.Position)
	local distance = (agentPrimaryPart.Position - trespasserPrimaryPart.Position).Magnitude

	if distance <= MIN_DISTANCE_TO_PLAYER then
		nav:stop()
		disconnectConnections(self)
	elseif distance >= MIN_DISTANCE_FROM_PLAYER then

		-- ok. this might be more performant.
		-- but holy shit connection management is a WHOLE OTHER LEVEL.
		if not (self.reachedConnection and self.waypointReachedConnection and self.blockedConnection and self.errorConnection) then
			moveToFuckingTarget(self, trespasserPrimaryPart, nav)
		end
	end

	self.plrsLastKnownLocation[trespasser] = trespasser.Character.PrimaryPart.Position
end

function PursueTrespasserGoal.requiresUpdating(self: PursueTrespasserGoal): boolean
	return true
end

return PursueTrespasserGoal