--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.ArgumentBuilder)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

return function<S>(self): ArgumentBuilder.ArgumentBuilder<S, any>
	if self.nodeType == "argument" then
		local builder = RequiredArgumentBuilder.new(self.name, self.argumentType)
		builder:requires(self:getRequirement())
		builder:suggests(self.customSuggestions)
		if self:getCommand() ~= nil then
			builder:executes(self:getCommand())
		end
		if self:getRedirect() then
			builder:redirect(self:getRedirect())
		end
		return builder
	else
		local builder = LiteralArgumentBuilder.new(self.name)
		builder:requires(self.requirement)
		if self:getCommand() ~= nil then
			builder:executes(self:getCommand())
		end
		if self:getRedirect() then
			builder:redirect(self:getRedirect())
		end
		return builder
	end
end
