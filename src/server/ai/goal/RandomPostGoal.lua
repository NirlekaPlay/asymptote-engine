--!nonstrict
local TouchInputService = game:GetService("TouchInputService")

local Agent = require("../../Agent")
local GuardPost = require("../navigation/GuardPost")
local Goal = require("./Goal")

local MIN_TIME_TO_PATROL_AGAIN = 1 -- seconds
local MIN_RANDOM_WAIT_TIME = 5
local MAX_RANDOM_WAIT_TIME = 10

local RandomPostGoal = {}
RandomPostGoal.__index = RandomPostGoal

export type RandomPostGoal = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	state: "UNEMPLOYED" | "WALKING" | "STAYING" | "RESUMING",
	targetPost: GuardPost?,
	previousPost: GuardPost?,
	timeToReleasePost: number,
	resumeDelayRemaining: number,
	posts: { GuardPost },
	isAtTargetPost: boolean,
	pathToPost: Path?,
	diedConnection: RBXScriptConnection?
}, RandomPostGoal)) & Goal.Goal

type GuardPost = GuardPost.GuardPost

function RandomPostGoal.new(agent, posts: { GuardPost }): RandomPostGoal
	return setmetatable({
		flags = { "MOVING", "SHOCKED"},
		agent = agent,
		state = "UNEMPLOYED",
		targetPost = nil :: GuardPost?,
		isAtTargetPost = false,
		timeToReleasePost = 0,
		posts = posts,
		pathToPost = nil :: Path?,
		resumeDelayRemaining = 0
	}, RandomPostGoal)
end

function RandomPostGoal.canUse(self: RandomPostGoal): boolean
	return not (self.agent:getSuspicionManager().amICurious)
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
	if not self.diedConnection then
		local humanoid = self.agent.character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self.diedConnection = humanoid.Died:Once(function()
				if self.targetPost then
					self.targetPost:vacate()
					return
				end

				if self.state == "UNEMPLOYED" then
					if self.previousPost then
						self.previousPost:vacate()
					end
				end
			end)
		end
	end
	self.resumeDelayRemaining = MIN_TIME_TO_PATROL_AGAIN
	self.state = "RESUMING" -- introduce a temporary state
end

function RandomPostGoal.stop(self: RandomPostGoal): ()
	self.agent:getBodyRotationControl():setRotateToDirection(nil)
	self.agent:getNavigation():stop()
	if not self.agent:isAlive() then
		if not self.targetPost then
			return
		end
		self.targetPost:vacate()
	end
end

function RandomPostGoal.update(self: RandomPostGoal, deltaTime: number): ()
	local nav = self.agent:getNavigation()
	local rot = self.agent:getBodyRotationControl()

	if self.agent.character.Head:FindFirstChild("RandomPostDebugGui") then
		self.agent.character.Head.RandomPostDebugGui.Frame.State.Text = `state: {self.state}`
		self.agent.character.Head.RandomPostDebugGui.Frame.TimeToReleasePost.Text = `wait timer: {math.ceil(self.timeToReleasePost)}`
		self.agent.character.Head.RandomPostDebugGui.Frame.ResumingTimer.Text = `resume timer: {math.ceil(self.resumeDelayRemaining)}`
	end

	if self.state == "RESUMING" then
		if self.resumeDelayRemaining > 0 then
			self.resumeDelayRemaining -= deltaTime
			return
		end

		-- now begin regular logic
		if self.targetPost and self.targetPost:isOccupied() then
			if (not self.isAtTargetPost) or (self.isAtTargetPost and nav:getPath() ~= self.pathToPost) then
				self:moveToPost(self.targetPost)
			else
				rot:setRotateToDirection(self.targetPost.cframe.LookVector)
				self.state = "STAYING"
			end
		else
			local post = self:getRandomUnoccupiedPost()
			if post then
				self:moveToPost(post)
			end
		end

		return -- prevent further logic this frame
	end

	if self.state == "WALKING" and nav.finished and not self.isAtTargetPost then
		nav.finished = false
		self.state = "STAYING"
		self.isAtTargetPost = true
		self.timeToReleasePost = math.random(MIN_RANDOM_WAIT_TIME, MAX_RANDOM_WAIT_TIME)
		rot:setRotateToDirection(self.targetPost.cframe.LookVector)
	elseif self.state == "STAYING" then
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			self.state = "UNEMPLOYED"
			--self.targetPost:vacate()
			self.previousPost = self.targetPost
			self.targetPost = nil
			self.isAtTargetPost = false
			rot:setRotateToDirection(nil)
		end
	end

	if self.state == "UNEMPLOYED" then
		local post = self:getRandomUnoccupiedPost()
		if post then
			self:moveToPost(post)
		end
	end
end

function RandomPostGoal.moveToPost(self: RandomPostGoal, post: GuardPost): ()
	post:occupy()
	self.isAtTargetPost = false
	if self.previousPost then
		self.previousPost:vacate()
	end
	self.targetPost = post
	self.state = "WALKING"
	self.agent:getNavigation():moveTo(post.cframe.Position)
	self.pathToPost = self.agent:getNavigation():getPath()
end

function RandomPostGoal.getRandomUnoccupiedPost(self: RandomPostGoal): GuardPost?
	local unoccupied = {}

	for _, post in ipairs(self.posts) do
		if not post:isOccupied() then
			table.insert(unoccupied, post)
		end
	end

	if #unoccupied == 0 then
		return nil
	end

	return unoccupied[math.random(1, #unoccupied)]
end

function RandomPostGoal.requiresUpdating(self: RandomPostGoal): boolean
	return true
end

return RandomPostGoal