--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local KillCommand = {}

function KillCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("kill")
			:executes(function(c)
				KillCommand.kill(c, {c:getSource()})
			end)
			:andThen(
				RequiredArgumentBuilder.new("victims", EntitySelectorParser)
					:executes(function(c)
						local selectorData = c:getArgument("victims") :: any
						local source = c:getSource()
						local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
						KillCommand.kill(c, targets)
					end)
			)
	)
end

function KillCommand.kill(c: CommandContext.CommandContext<Player>, targets: {Instance}): number
	for _, target in targets do
		local targetChar
		if target:IsA("Player") then
			targetChar = target.Character
		else
			targetChar = target
		end
		if targetChar then
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
				print("Killed " .. target.Name)
			end
		end
	end
	
	return #targets
end

return KillCommand