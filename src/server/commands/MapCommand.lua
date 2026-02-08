--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.world.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local StringArgumentType = require(ReplicatedStorage.shared.commands.arguments.StringArgumentType)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)
local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)

local MapCommand = {}

function MapCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("map")
			:andThen(
				CommandHelper.literal("clear")
					:executes(MapCommand.clear)
			)
			:andThen(
				CommandHelper.literal("load")
					:andThen(
						CommandHelper.argument("mapName", StringArgumentType.greedyString())
							:executes(function(c)
								return MapCommand.loadMap(c)
							end)
					)
			)
	)
end

function MapCommand.clear(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>): number
	Level.clearLevel()

	c:getSource():sendSuccess(MutableTextComponent.literal("Successfully cleared level"))

	return 1
end

function MapCommand.loadMap(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, explicit: boolean?): number
	local rawInput = StringArgumentType.getString(c, "mapName")
	local mapName = rawInput:gsub("%s*--explicit%s*", ""):gsub("%s*$", "")
	
	local success, err = pcall(function()
		--[[task.spawn(function()
			Level.loadLevel(mapName)
		end)
		task.wait(1)]]
		Level.loadLevel(mapName)
	end)

	if not success then
		local errMsg = MutableTextComponent.literal(`An error occured while trying to load map '{mapName}':`)
		if explicit then
			errMsg:appendString(` {err}`)
		else
			errMsg:appendString(` {((err :: any) :: string):match("^[^:]+:%d+: (.+)")}`)
		end

		c:getSource():sendFailure(errMsg)
		return 0
	else
		c:getSource():sendSuccess(
			MutableTextComponent.literal(`Successfully loaded map '{mapName}'`)
		)
	end

	return 1
end

return MapCommand