--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.shared.util.misc.Maid)
local TriggerAttributes = require(ReplicatedStorage.shared.world.interaction.attributes.TriggerAttributes)

--[=[
	@class WorldInteractionPrompt
]=]
local WorldInteractionPrompt = {}
WorldInteractionPrompt.__index = WorldInteractionPrompt

export type WorldInteractionPrompt = typeof(setmetatable({} :: {
	proxPrompt: ProximityPrompt,
	attachment: Attachment,
	_maid: Maid.Maid
}, WorldInteractionPrompt))

function WorldInteractionPrompt.new(proxPrompt: ProximityPrompt): WorldInteractionPrompt
	return setmetatable({
		proxPrompt = proxPrompt,
		attachment = proxPrompt.Parent :: Attachment,
		_maid = Maid.new()
	}, WorldInteractionPrompt)
end

function WorldInteractionPrompt.setTitleKey(self: WorldInteractionPrompt, titleKey: string): ()
	self.proxPrompt.ActionText = titleKey
end

function WorldInteractionPrompt.setSubtitleKey(self: WorldInteractionPrompt, subtitleKey: string): ()
	self.proxPrompt.ObjectText = subtitleKey
end

function WorldInteractionPrompt.enable(self: WorldInteractionPrompt): ()
	self.proxPrompt.Enabled = true
end

function WorldInteractionPrompt.disable(self: WorldInteractionPrompt): ()
	self.proxPrompt.Enabled = false
end

function WorldInteractionPrompt.setServerEnabled(self: WorldInteractionPrompt, enabled: boolean): ()
	self.attachment:SetAttribute(TriggerAttributes.SERVER_VISIBLE, enabled)
end

function WorldInteractionPrompt.setServerVisible(self: WorldInteractionPrompt, visible: boolean): ()
	self.attachment:SetAttribute(TriggerAttributes.SERVER_VISIBLE, visible)
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

--

function WorldInteractionPrompt.getMaid(self: WorldInteractionPrompt): Maid.Maid
	return self._maid
end

function WorldInteractionPrompt.destroy(self: WorldInteractionPrompt): ()
	self._maid:doCleaning()
end

return WorldInteractionPrompt