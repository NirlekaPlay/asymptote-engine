--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require("../../Agent")
local PlayerStatusRegistry = require("../../player/PlayerStatusRegistry")
local ExpireableValue = require(ServerScriptService.server.ai.memory.ExpireableValue)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local Goal = require("./Goal")

local PursueTrespasserGoal = {}
PursueTrespasserGoal.__index = PursueTrespasserGoal

export type PursueTrespasserGoal = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	giveUpTimer: number,
	shouldContinue: boolean,
	plrsLastKnownLocation: { [Player]: Vector3 },
	waypointReachedConnection: RBXScriptConnection,
	patienceCountdown: number,
	triggerFingerPatience: number,
	killingOn: Player?,
	warnedPlayers: { [Player]: ExpireableValue.ExpireableValue<Player> }
}, PursueTrespasserGoal)) & Goal.Goal

function PursueTrespasserGoal.new(agent): PursueTrespasserGoal
	return setmetatable({
		flags = {
			"PURSUING",
			"SHOCKED"
		},
		agent = agent,
		giveUpTimer = 5,
		shouldContinue = true,
		plrsLastKnownLocation = {},
		waypointReachedConnection = nil,
		patienceCountdown = 5,
		triggerFingerPatience = 5,
		warnedPlayers = (function()
			agent.memories.WARNED_PLAYERS = {}
			return agent.memories.WARNED_PLAYERS
		end)()
	}, PursueTrespasserGoal)
end

function PursueTrespasserGoal.canUse(self: PursueTrespasserGoal): boolean
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	local hasSuspect = susMan.excludedSuspect
	if not hasSuspect then
		return false
	end
	local highestStatus = PlayerStatusRegistry.getPlayerStatuses(hasSuspect.suspect):getHighestPriorityStatus()
	local isTrespassing = highestStatus == "MINOR_TRESPASSING" or highestStatus == "MAJOR_TRESPASSING"

	if isTrespassing then
		self.shouldContinue = true
	end

	return isTrespassing and self.shouldContinue
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
	local trespasser = (self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement).focusingOn
	if not trespasser then
		-- how tf did we even got here in the first place?
		return
	end

	self.agent:getFaceControl():setFace("Angry")

	if not self.agent.memories.IS_DEALING_WITH_SOMETHING_HERE then
		self.agent.memories.IS_DEALING_WITH_SOMETHING_HERE = ExpireableValue.nonExpiring(true)
	else
		self.agent.memories.IS_DEALING_WITH_SOMETHING_HERE.value = true
	end

	if self.warnedPlayers[trespasser] then
		--print(trespasser, "again?!")
		local bubControl = self.agent:getBubbleChatControl()
		self.patienceCountdown = 0
		self.triggerFingerPatience = 0
		self.warnedPlayers[trespasser].timeToLive += 20
		local timeToLive = self.warnedPlayers[trespasser].timeToLive
		
		if timeToLive > 10 and timeToLive < 25 then
			bubControl:displayBubble("You again?!")
			task.wait(1)
			bubControl:displayBubble("Oh fuck off!")
		elseif timeToLive > 25 and timeToLive < 35 then
			bubControl:displayBubble("Do you have enough?! Go away!")
		else
			task.spawn(function()
				bubControl:displayBubble("OH.")
				task.wait(0.5)
				bubControl:displayBubble("MY.")
				task.wait(0.5)
				bubControl:displayBubble("GOOOOOOOOOD!")
			end)
		end
		return
	end

	-- why bother safe accessing at this point
	local agentPrimaryPart = self.agent:getPrimaryPart()
	local trespasserPrimaryPart = trespasser.Character.PrimaryPart

	local distance = (agentPrimaryPart.Position - trespasserPrimaryPart.Position).Magnitude
	-- what the fuck.
	-- uh the poor sod got shit vision so i do this temporarily.
	self.agent.sensors[1].sightRadius = 90
	local bubControl = self.agent:getBubbleChatControl()

	-- i did, infact, regret it.
	if distance <= MIN_DISTANCE_TO_PLAYER then
		bubControl:displayBubble("This is a restricted area. You need to leave.")
	elseif distance >= MIN_DISTANCE_FROM_PLAYER then
		bubControl:displayBubble("Hey! This area is restricted! You need to leave!")
		self.agent:getNavigation():moveTo(trespasserPrimaryPart.Position)
	else
		bubControl:displayBubble("What the hell?!")
		task.spawn(function()
			task.wait(1)
			bubControl:displayBubble("Hey! You're not supposed to be here! Get out!")
		end)
	end
	--self.agent:getBodyRotationControl():setRotateTowards(self.agent:getSuspicionManager().focusingSuspect.Character.PrimaryPart.Position)
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

function PursueTrespasserGoal.stop(self: PursueTrespasserGoal): ()
	self.agent:getFaceControl():setFace("Neutral")
	self.agent.memories.IS_DEALING_WITH_SOMETHING_HERE.value = false
	self.patienceCountdown = 5
	self.triggerFingerPatience = 5
	self.killingOn = nil
	local bubControl = self.agent:getBubbleChatControl()
	disconnectConnections(self)
	if self.agent.character:FindFirstChild("FBB") then
		local fbb = self.agent.character.FBB
		--local humanoid = self.agent.character.Humanoid :: Humanoid
		fbb.unequip:Fire()
		--humanoid:UnequipTools()
		task.wait(1)
		fbb.Parent = game.ServerStorage
		--bubControl:displayBubble("Piece of shit.")
	end
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

local playersLastPos: { [Player]: Vector3 } = {}
local function isPlayerMoving(player: Player): boolean
	local humanoidRootPart = player.Character.HumanoidRootPart
	local curPos = humanoidRootPart.Position
	local lastPos = playersLastPos[player]
	if not lastPos then
		playersLastPos[player] = curPos
		return false
	end
	
	curPos = Vector3.new(curPos.X, 0, curPos.Z)
	lastPos = Vector3.new(lastPos.X, 0, lastPos.Z)
	playersLastPos[player] = curPos
	return (curPos - lastPos).Magnitude > 1e-6
end

function PursueTrespasserGoal.update(self: PursueTrespasserGoal, deltaTime: number): ()
	-- oh god WHAT HAVE I CREATED.
	--print(self.warnedPlayers)
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	local trespasser = susMan.excludedSuspect.suspect
	local agentPrimaryPart = self.agent:getPrimaryPart()
	local trespasserPrimaryPart = trespasser.Character.PrimaryPart
	local nav = self.agent:getNavigation() :: PathNavigation.PathNavigation
	local bubControl = self.agent:getBubbleChatControl()

	local warnedMemory = self.warnedPlayers[trespasser]
	
	local inMag = 10
	local maxRoundsInMag = 10
	local shootSpeed = 0.3

	if warnedMemory then
		local timeToLive = self.warnedPlayers[trespasser].timeToLive
		
		if timeToLive > 10 and timeToLive < 25 then
			inMag = 10
			maxRoundsInMag = 10
			shootSpeed = 0.3
		elseif timeToLive > 25 and timeToLive < 35 then
			inMag = 0
			maxRoundsInMag = 30
			shootSpeed = 0.1
		else
			inMag = 0
			maxRoundsInMag = 100
			shootSpeed = 0.01
		end
	end

	if self.patienceCountdown <= 0 then

		if self.killingOn == nil then
			self.killingOn = trespasser
			if not self.warnedPlayers[trespasser] then
				--print("new player")
				bubControl:displayBubble("Hey! Im warning you!")
			else
				--print("repeat offender")
			end
			
			if not self.agent.character:FindFirstChild("FBB") then
				local fbb = game.ServerStorage.FBB
				fbb.Parent = self.agent.character
				fbb.settings.inmag.Value = inMag
				fbb.settings.maxmagcapacity.Value = maxRoundsInMag
				fbb.settings.speed.Value = shootSpeed
			end
		end

		if self.triggerFingerPatience <= 1 and not self.warnedPlayers[trespasser] then
			self.warnedPlayers[trespasser] = ExpireableValue.new(true, 20)
			bubControl:displayBubble("Alright! You've been warned!")
		end

		if self.triggerFingerPatience <= 0 then
			local character = self.agent.character
			if character and character:FindFirstChild("FBB") then
				local remote = self.agent.character.FBB.fire :: BindableEvent
				--local dir = workspace:Raycast(character.Head.Position, character.Head.CFrame.LookVector.Unit * 90)
				--warn(dir)

				remote:Fire("2", trespasser.Character.PrimaryPart.Position)
			end
		else
			self.triggerFingerPatience -= deltaTime
		end

	else
		self.patienceCountdown -= deltaTime
	end

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

	if not self.warnedPlayers[trespasser] then
		local distance = (agentPrimaryPart.Position - trespasserPrimaryPart.Position).Magnitude

		if distance <= MIN_DISTANCE_TO_PLAYER then
			if not isPlayerMoving(trespasser) then
				--print("player is not moving not stopping")
				nav:stop()
				disconnectConnections(self)
			end
		elseif distance >= MIN_DISTANCE_FROM_PLAYER then

			-- ok. this might be more performant.
			-- but holy shit connection management is a WHOLE OTHER LEVEL.
			if not (self.reachedConnection and self.waypointReachedConnection and self.blockedConnection and self.errorConnection) then
				moveToFuckingTarget(self, trespasserPrimaryPart, nav)
			end
		end
	end

	self.plrsLastKnownLocation[trespasser] = trespasser.Character.PrimaryPart.Position
end

function PursueTrespasserGoal.requiresUpdating(self: PursueTrespasserGoal): boolean
	return true
end

return PursueTrespasserGoal