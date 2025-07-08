--!nonstrict

local GuardPost = require("../navigation/GuardPost")
local Goal = require("./Goal")

local RandomPostGoal = {}
RandomPostGoal.__index = RandomPostGoal

export type RandomPostGoal = typeof(setmetatable({} :: {
	agent: any,
	state: "UNEMPLOYED" | "WALKING" | "STAYING",
	currentPost: GuardPost.GuardPost,
	releaseUntil: number,
	posts: {GuardPost}
}, RandomPostGoal)) & Goal.Goal

function RandomPostGoal.new(agent, posts: {GuardPost.GuardPost}): RandomPostGoal
	return setmetatable({
		flags = {},
		agent = agent,
		state = "UNEMPLOYED",
		currentPost = nil,
		releaseUntil = 0,
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
	warn("Attempt to find post...")
	local post = self:getRandomUnoccupiedPost()
	if not post then
		warn("No unoccupied posts found")
		return
	end

	warn("Post found.")
	post:occupy()
	self.currentPost = post
	self.state = "WALKING"
	self.agent:getNavigation():moveTo(post.cframe.Position)
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
		self.releaseUntil = tick() + math.random(4, 7)
		rot:setRotateTowards(self.currentPost.cframe.LookVector)
		warn("Walk to finished. Staying for...", math.floor(self.releaseUntil - tick()), "seconds")
	elseif self.state == "STAYING" then
		--local remaining = self.releaseUntil - tick()
		--print(`Still waiting at post for {math.ceil(remaining)}s...`)
		if tick() > self.releaseUntil then
			self.state = "UNEMPLOYED"
			self.currentPost:vacate()
			self.currentPost = nil
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

function RandomPostGoal.getRandomUnoccupiedPost(self: RandomPostGoal): GuardPost.GuardPost
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

return RandomPostGoal