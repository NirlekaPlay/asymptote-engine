--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)

--[=[
	@class CinematicsDirector
]=]
local CinematicsDirector = {}
CinematicsDirector.__index = CinematicsDirector

export type CinematicsDirector = typeof(setmetatable({} :: {
	assets: { [string]: Instance },
	rawIntroData: any,
	currentThread: thread?,
	--
	_maid: Maid.Maid,
	_activeThreads: {thread}
}, CinematicsDirector))

function CinematicsDirector.fromData(rawIntroData: any): CinematicsDirector
	return setmetatable({
		assets = {},
		rawIntroData = rawIntroData,
		_maid = Maid.new(),
		_activeThreads = {},
		_currentThread = nil :: thread?
	}, CinematicsDirector) :: CinematicsDirector
end

function CinematicsDirector.initializeAssets(self: CinematicsDirector): ()
	for name, data in self.rawIntroData.declarations.sounds do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = data.id
		s.Volume = data.volume
		s.Looped = data.looping
		s.Parent = SoundService
		self.assets[name] = s
	end
end

function CinematicsDirector.executeAction(self: CinematicsDirector, data: any): ()
	local target = self.assets[data.target]
	if not target or not target:IsA("Sound") then
		return
	end

	if data.action == "play" then
		target:Play()
	elseif data.action == "fade" then
		local tween = TweenService:Create(target, TweenInfo.new(data.duration or 1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Volume = data.to })
		self._maid:giveTask(tween)
		tween:Play()
	elseif data.action == "stop" then
		target:Stop()
	end
end

function CinematicsDirector.stop(self: CinematicsDirector): ()
	if self.currentThread then
		task.cancel(self.currentThread)
		self.currentThread = nil
	end

	for _, thread in self._activeThreads do
		task.cancel(thread)
	end

	table.clear(self._activeThreads)

	self._maid:doCleaning()
end

--

function CinematicsDirector.runScene(self: CinematicsDirector, sceneName: string, intertitlesScreen: any): ()
	local sceneData = self.rawIntroData.scenes[sceneName]
	if not sceneData then
		error(`No such scene name '{sceneName}'`)
	end

	if self.currentThread then
		task.cancel(self.currentThread)
		self.currentThread = nil
	end

	self.currentThread = task.spawn(CinematicsDirector.runThread, self, sceneData, intertitlesScreen)
end

function CinematicsDirector.runThread(self: CinematicsDirector, sceneData: any, intertitlesScreen: any): ()
	self:initializeAssets()
	
	intertitlesScreen.prepare()
	intertitlesScreen.fadeIn()

	for _, block in sceneData do
		if block.onStart then
			for _, event in block.onStart do
				self:executeAction(event)
			end
		end

		local formattedSteps = {}
		for _, step in block.steps do
			table.insert(formattedSteps, {
				text = step.text,
				duration = step.duration,
				onVisible = function()
					if step.events then
						for _, ev in step.events do
							local thread = task.delay(ev.time or 0, function()
								self:executeAction(ev)
							end)

							table.insert(self._activeThreads, thread)
						end
					end
				end
			})
		end

		intertitlesScreen.runSequenceThread({formattedSteps})

		if block.onEnd then
			for _, event in block.onEnd do
				self:executeAction(event)
			end
		end
	end

	intertitlesScreen.fadeOut()
end

--

function CinematicsDirector.destroy(self: CinematicsDirector): ()
	if self.currentThread then
		task.cancel(self.currentThread)
		self.currentThread = nil
	end

	for _, thread in self._activeThreads do
		task.cancel(thread)
	end

	table.clear(self._activeThreads)

	self._maid:doCleaning()

	for _, inst in self.assets do
		inst:Destroy()
	end
end

return CinematicsDirector