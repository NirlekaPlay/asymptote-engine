--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")

local SuspicionManagement = require(ServerScriptService.server.ai.suspicion.SuspicionManagement)
local GuardPost = require("../navigation/GuardPost")
local Goal = require("./Goal")

local MIN_TIME_TO_PATROL_AGAIN = 1 -- seconds

local RandomPostGoal = {}
RandomPostGoal.__index = RandomPostGoal

export type RandomPostGoal = typeof(setmetatable({} :: {
	agent: any,
	state: "UNEMPLOYED" | "WALKING" | "STAYING" | "RESUMING",
	targetPost: GuardPost?,
	timeToReleasePost: number,
	posts: {GuardPost},
	isAtTargetPost: boolean,
	pathToPost: Path?
}, RandomPostGoal)) & Goal.Goal

type GuardPost = GuardPost.GuardPost

local function getRandomUnoccupiedPost(posts: { GuardPost }): GuardPost?
	local unoccupied = {}

	for _, post in ipairs(posts) do
		if not post:isOccupied() then
			table.insert(unoccupied, post)
		end
	end

	if #unoccupied == 0 then
		return nil
	end

	return unoccupied[math.random(1, #unoccupied)]
end

local function walkToPost(self: RandomPostGoal, post: GuardPost): ()
	post:occupy()
	self.isAtTargetPost = false
	self.targetPost = post
	self.state = "WALKING"
	self.agent:getNavigation():moveTo(post.cframe.Position)
	self.pathToPost = self.agent:getNavigation():getPath()
end

function RandomPostGoal.new(agent, posts: {GuardPost}): RandomPostGoal
	return setmetatable({
		flags = { "MOVING" },
		agent = agent,
		state = "UNEMPLOYED",
		targetPost = nil,
		isAtTargetPost = false,
		timeToReleasePost = 0,
		posts = posts,
		pathToPost = nil
	}, RandomPostGoal)
end

function RandomPostGoal.canUse(self: RandomPostGoal): boolean
	local susMan = self.agent:getSuspicionManager() :: SuspicionManagement.SuspicionManagement
	return not susMan.amICurious
end

function RandomPostGoal.canContinueToUse(self: RandomPostGoal): boolean
	return self:canUse()
end

function RandomPostGoal.isInterruptable(self: RandomPostGoal): boolean
	return true
end

function RandomPostGoal.getFlags(self: RandomPostGoal): {Flag}
	return self.flags
end

function RandomPostGoal.start(self: RandomPostGoal): ()
	self.resumeDelayRemaining = MIN_TIME_TO_PATROL_AGAIN
	self.state = "RESUMING" -- introduce a temporary state
end

function RandomPostGoal.stop(self: RandomPostGoal): ()
	self.agent:getBodyRotationControl():setRotateToDirection(nil)
	self.agent:getNavigation():stop()
end

function RandomPostGoal.update(self: RandomPostGoal, deltaTime: number): ()
	local nav = self.agent:getNavigation()
	local rot = self.agent:getBodyRotationControl()

	if self.state == "RESUMING" then
		self.resumeDelayRemaining -= deltaTime
		if self.resumeDelayRemaining <= 0 then
			-- now begin regular logic
			if self.targetPost and self.targetPost:isOccupied() then
				if (not self.isAtTargetPost) or (self.isAtTargetPost and nav:getPath() ~= self.pathToPost) then
					walkToPost(self, self.targetPost)
				else
					rot:setRotateToDirection(self.targetPost.cframe.LookVector)
					self.state = "STAYING"
				end
			else
				local post = getRandomUnoccupiedPost(self.posts)
				if post then
					walkToPost(self, post)
				end
			end
		end
		return -- prevent further logic this frame
	end

	if self.state == "WALKING" and nav.finished and not self.isAtTargetPost then
		nav.finished = false
		self.state = "STAYING"
		self.isAtTargetPost = true
		self.timeToReleasePost = math.random(4, 7)
		rot:setRotateToDirection(self.targetPost.cframe.LookVector)
	elseif self.state == "STAYING" then
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			self.state = "UNEMPLOYED"
			self.targetPost:vacate()
			self.targetPost = nil
			self.isAtTargetPost = false
			rot:setRotateToDirection(nil)
		end
	end

	if self.state == "UNEMPLOYED" then
		self:start()
	end
end

function RandomPostGoal.requiresUpdating(self: RandomPostGoal): boolean
	return true
end

return RandomPostGoal