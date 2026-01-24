--!strict

--[=[
	@class WorldInteractionPrompt
]=]
local WorldInteractionPrompt = {}
WorldInteractionPrompt.__index = WorldInteractionPrompt

export type WorldInteractionPrompt = typeof(setmetatable({} :: {
	proxPrompt: ProximityPrompt
}, WorldInteractionPrompt))

function WorldInteractionPrompt.new(proxPrompt: ProximityPrompt): WorldInteractionPrompt
	return setmetatable({
		proxPrompt = proxPrompt
	}, WorldInteractionPrompt)
end

function WorldInteractionPrompt.getTriggeredEvent(self: WorldInteractionPrompt): RBXScriptSignal<Player>
	return self.proxPrompt.Triggered
end

function WorldInteractionPrompt.getHoldBeganEvent(self: WorldInteractionPrompt): RBXScriptSignal<Player>
	return self.proxPrompt.PromptButtonHoldBegan
end

function WorldInteractionPrompt.getHoldEndedEvent(self: WorldInteractionPrompt): RBXScriptSignal<Player>
	return self.proxPrompt.PromptButtonHoldEnded
end

return WorldInteractionPrompt