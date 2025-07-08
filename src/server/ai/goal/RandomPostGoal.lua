--!nonstrict

local GuardPost = require("../navigation/GuardPost")
local Goal = require("./Goal")

local RandomPostGoal = {}
RandomPostGoal.__index = RandomPostGoal

export type RandomPostGoal = typeof(setmetatable({} :: {
	agent: any,
	state: "UNEMPLOYED" | "WALKING" | "STAYING",
	targetPost: GuardPost?,
	timeToReleasePost: number,
	posts: {GuardPost},
	isAtTargetPost: boolean,
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
end

function RandomPostGoal.new(agent, posts: {GuardPost}): RandomPostGoal
	return setmetatable({
		flags = {},
		agent = agent,
		state = "UNEMPLOYED",
		targetPost = nil,
		isAtTargetPost = false,
		timeToReleasePost = 0,
		posts = posts
	}, RandomPostGoal)
end

function RandomPostGoal.canUse(self: RandomPostGoal): boolean
	local susMan = self.agent:getSuspicionManager()
	return susMan.currentState ~= "SUSPICIOUS" and susMan.currentState ~= "ALERTED"
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
	if self.targetPost and self.targetPost:isOccupied() then
		if not self.isAtTargetPost then
			walkToPost(self, self.targetPost)
		else
			self.agent:getBodyRotationControl():setRotateTowards(self.targetPost.cframe.LookVector)
		end
	else
		warn("Attempt to find post...")
		local post = getRandomUnoccupiedPost(self.posts)
		if not post then
			warn("No unoccupied posts found")
			return
		end

		walkToPost(self, post)
	end
end

function RandomPostGoal.stop(self: RandomPostGoal): ()
	self.agent:getNavigation():stop()
end

function RandomPostGoal.update(self: RandomPostGoal, deltaTime: number): ()
	local nav = self.agent:getNavigation()
	local rot = self.agent:getBodyRotationControl()

	-- WARNING: Might need to check if the path is the same but fuck it
	if self.state == "WALKING" and nav.finished then
		-- AWFUL HACK ALERT, i shouldnt do this but i SHOULD
		nav.finished = false
		self.state = "STAYING"
		self.isAtTargetPost = true
		self.timeToReleasePost = math.random(4, 7)
		rot:setRotateTowards(self.targetPost.cframe.LookVector)
		warn("Walk to finished. Staying for...", self.timeToReleasePost, "seconds")
	elseif self.state == "STAYING" then
		--local remaining = self.releaseUntil - tick()
		--print(`Still waiting at post for {math.ceil(remaining)}s...`)
		self.timeToReleasePost -= deltaTime
		if self.timeToReleasePost <= 0 then
			self.state = "UNEMPLOYED"
			self.targetPost:vacate()
			self.targetPost = nil
			rot:setRotateTowards(nil)
			nav:stop()
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