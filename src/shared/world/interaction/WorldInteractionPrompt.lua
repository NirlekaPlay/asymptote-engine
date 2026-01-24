--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TriggerAttributes = require(ReplicatedStorage.shared.world.interaction.attributes.TriggerAttributes)

--[=[
	@class WorldInteractionPrompt
]=]
local WorldInteractionPrompt = {}
WorldInteractionPrompt.__index = WorldInteractionPrompt

export type WorldInteractionPrompt = typeof(setmetatable({} :: {
	proxPrompt: ProximityPrompt,
	attachment: Attachment
}, WorldInteractionPrompt))

function WorldInteractionPrompt.new(proxPrompt: ProximityPrompt): WorldInteractionPrompt
	return setmetatable({
		proxPrompt = proxPrompt,
		attachment = proxPrompt.Parent :: Attachment
	}, WorldInteractionPrompt)
end

function WorldInteractionPrompt.setServerEnabled(self: WorldInteractionPrompt, enabled: boolean): ()
	self.attachment:SetAttribute(TriggerAttributes.SERVER_VISIBLE, enabled)
end

--

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