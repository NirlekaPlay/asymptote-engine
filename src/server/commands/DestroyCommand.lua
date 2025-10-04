--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntitySelectorParser = require(ReplicatedStorage.shared.commands.arguments.asymptote.selector.EntitySelectorParser)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local RequiredArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.RequiredArgumentBuilder)

local DestroyCommand = {}

function DestroyCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("destroy")
			:andThen(
				RequiredArgumentBuilder.new("victims", EntitySelectorParser.entities())
					:executes(function(c)
						local selectorData = c:getArgument("victims") :: any
						local source = c:getSource()
						local targets = EntitySelectorParser.resolvePlayerSelector(selectorData, source)
						DestroyCommand.destroyAllTargets(targets)
					end)
			)
	)
end

function DestroyCommand.destroyAllTargets(targets: {Instance}): ()
	for _, inst in ipairs(targets) do 
		if inst:IsA("Player") then
			warn(`Destroy command: Cannot attempt to destroy {inst}, as its a Player.`)
			continue
		else
			inst:Destroy()
		end
	end
end

return DestroyCommand