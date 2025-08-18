--!strict

local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

local Agent = require(ServerScriptService.server.Agent)

--[=[
	@class AnimationControl

	Controls all animations of an Agent.
]=]
local AnimationControl = {}
AnimationControl.__index = AnimationControl

export type AnimationControl = typeof(setmetatable({} :: {
	agent: Agent.Agent,
	animator: Animator,
	loadedAnimations: { [string]: AnimationTrack }
}, AnimationControl))

function AnimationControl.new(agent: Agent.Agent): AnimationControl
	local self = setmetatable({}, AnimationControl)

	self.agent = agent
	self.character = agent.character
	self.animator = AnimationControl.getAnimator(agent.character)
	self.loadedAnimations = {}

	local humanoid = agent.character:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.Running:Connect(function(speed)
		--print(speed)
		--[[if agent:getNavigation():isMoving() then
			if humanoid.WalkSpeed < 19 and not self:isAnimationPlaying("movementWalk") then
				self:removeAnimation("movementRun")
				self:loadAndPlayAnimation("movementWalk", 15719486204)
			elseif humanoid.WalkSpeed >= 19 and not self:isAnimationPlaying("movementRun") then
				self:removeAnimation("movementWalk")
				self:loadAndPlayAnimation("movementRun", 79947225688040)
			end
		else
			self:removeAnimation("movementWalk")
			self:removeAnimation("movementRun")
			self:loadAndPlayAnimation("idle", 180435571)
		end]]
	end)

	return self
end

function AnimationControl.loadAndPlayAnimation(self: AnimationControl, animName: string, animId: number): ()
	local animation = Instance.new("Animation")
	animation.AnimationId = AnimationControl.assetIdNumberToString(animId)

	local animationTrack = self.animator:LoadAnimation(animation)
	self.loadedAnimations[animName] = animationTrack

	animationTrack:Play()
	Debris:AddItem(animationTrack, animationTrack.Length + 1)
end

function AnimationControl.removeAnimation(self: AnimationControl, animName: string): ()
	local animationTrack = self.loadedAnimations[animName]
	if animationTrack then
		animationTrack:Stop()
		animationTrack:Destroy()
		self.loadedAnimations[animName] = nil
	end
end

function AnimationControl.isAnimationPlaying(self: AnimationControl, animName: string): boolean
	return self.loadedAnimations[animName] ~= nil
end

--[=[
	Returns the [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator)
	instance from the character. Which is parented to its humanoid.
	If no animator is found, it will create a new animator instance
	and returns that instead.
]=]
function AnimationControl.getAnimator(character: Model): Animator
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local animator = character:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator :: Animator
end

--[=[
	Takes in an asset ID number such as `1234567890`
	and returns `rbxassetid://1234567890`
]=]
function AnimationControl.assetIdNumberToString(assetIdNum: number): string
	return `rbxassetid://{assetIdNum}`
end


return AnimationControl