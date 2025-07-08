local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local BodyRotationControl = require(ServerScriptService.server.ai.control.BodyRotationControl)
local GuardPost = require(ServerScriptService.server.ai.navigation.GuardPost)
local PathNavigation = require(ServerScriptService.server.ai.navigation.PathNavigation)
local TargetNearbySensor = require(ServerScriptService.server.ai.sensing.TargetNearbySensor)
local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local TriggerZone = require(ServerScriptService.server.zone.TriggerZone)

type GuardPost = GuardPost.GuardPost

local GUARD_POSTS_TAG_NAME = "Post"

local rig: Model = workspace:WaitForChild("Rig")
local currentSusMan = SuspicionManagement.new(rig)
local currentNearbySensor = TargetNearbySensor.new(20)
local currentTriggerZone = TriggerZone.fromPart(workspace:WaitForChild("Zone1"))
local currentBodyRotCtrl = BodyRotationControl.new(rig.HumanoidRootPart)
local currentPathNav = PathNavigation.new(rig)

local currentPatrolState: "UNEMPLOYED" | "WALKING" | "STAYING" = "UNEMPLOYED"
local currentPost: GuardPost?
local currentPathToPost: Path? = nil
local releaseUntil = 0
local currentGuardPosts: { GuardPost } = {}

local function setupGuardPosts()
	for _, post in ipairs(CollectionService:GetTagged(GUARD_POSTS_TAG_NAME)) do
		local newGuardPost = GuardPost.fromPart(post, false)
		table.insert(currentGuardPosts, newGuardPost)
	end
end

local function getRandomUnoccupiedGuardPost(): GuardPost?
	local unoccupiedPosts: { GuardPost } = {}

	for i, post in ipairs(currentGuardPosts) do
		if post:isOccupied() then
			continue
		end

		table.insert(unoccupiedPosts, post)
	end

	local size = #unoccupiedPosts
	if size <= 0 then
		return nil
	end

	return unoccupiedPosts[math.random(1, size)]
end

setupGuardPosts()

RunService.PreAnimation:Connect(function(deltaTime)
	currentTriggerZone:update()
	currentNearbySensor:update(rig.PrimaryPart.Position, currentTriggerZone:getPlayersInZone())
	currentSusMan:update(deltaTime, currentNearbySensor.detectedTargets)

	-- forgive me.
	-- please work. PLEASE.
	-- shit it doesnt work.
	-- OH SHIT IT WORKS YEAHHHHHHHHHHHHHH
	if currentSusMan.currentState ~= "SUSPICIOUS" and currentSusMan.currentState ~= "ALERTED" then
		if currentPatrolState == "UNEMPLOYED" and currentPost == nil then
			warn(`No assigned post for Guard. Current state is {currentPatrolState}, and current post is {currentPost}`)
			warn("Attempt to find post...")
			local fetchPost = getRandomUnoccupiedGuardPost()
			if not fetchPost then
				warn("No unoccupied posts found")
				return
			end

			warn("Post found.")
			fetchPost:occupy()
			currentPost = fetchPost
			currentPatrolState = "WALKING"
			currentPathNav:moveTo(fetchPost.cframe.Position)
			currentPathToPost = currentPathNav.path
		end

		if currentPatrolState == "WALKING" then
			if currentPathToPost == "nil" then
				warn("shit happend, currentPathToPost is nil")
				return
			end

			--print(currentPathNav.path, currentPathNav.finished)
			if currentPathNav.path == currentPathToPost and currentPathNav.finished then
				-- AWFUL HACK ALERT:
				currentPathNav.finished = false
				currentPatrolState = "STAYING"
				releaseUntil = tick() + math.random(4, 7)
				currentBodyRotCtrl:setRotateTowards(currentPost.cframe.LookVector)
				warn("Walk to finished. Staying for...", releaseUntil, "seconds")
			end
		end

		if currentPatrolState == "STAYING" then
			--local remaining = releaseUntil - tick()
			--print(`Still waiting at post for {math.ceil(remaining)}s...`)
			if tick() > releaseUntil then
				warn("Staying finished. Vacating...")
				currentPost:vacate()
				currentPost = nil
				currentPatrolState = "UNEMPLOYED"
				currentBodyRotCtrl:setRotateTowards(nil)
			end
		end
	else
		if currentPost then
			warn("Path interrupted, targeted suspect is", currentSusMan.focusingSuspect)
			warn("Vacating...")
			currentPost:vacate()
			currentPost = nil
			currentPatrolState = "UNEMPLOYED"
			currentPathNav:stop()
		end
		if currentSusMan.currentState == "SUSPICIOUS" then
		currentBodyRotCtrl:setRotateTowards(currentSusMan.focusingSuspect.Character.PrimaryPart.Position)
		else
			currentBodyRotCtrl:setRotateTowards(nil)
		end
		currentBodyRotCtrl:update(deltaTime)
	end
end)