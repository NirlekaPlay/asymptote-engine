--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local Level = require(ServerScriptService.server.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local CellCommand = {}

local debugBoundsPerCells : { [Model]: BasePart } = {}

function CellCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("cell")
			:andThen(
				CommandHelper.literal("show")
					:andThen(
						CommandHelper.literal("surfaces")
							:executes(CellCommand.showAllCells)
					)
					:andThen(
						CommandHelper.literal("bounds")
							:executes(function()
								return CellCommand.showOrHideDebugBounds(true) :: number
							end)
					)
			)
			:andThen(
				CommandHelper.literal("hide")
					:andThen(
						CommandHelper.literal("surfaces")
							:executes(CellCommand.hideAllCells)
					)
					:andThen(
						CommandHelper.literal("bounds")
							:executes(function()
								return CellCommand.showOrHideDebugBounds(false) :: number
							end)
					)
			)
	)
end

function CellCommand.showAllCells(): number
	local count = 0
	for _, cellModel in pairs(Level.getCellModels()) do
		Level.showCell(cellModel)
		count += 1
	end
	return count
end

function CellCommand.hideAllCells(): number
	local count = 0
	for _, cellModel in pairs(Level.getCellModels()) do
		Level.hideCell(cellModel)
		count += 1
	end
	return count
end

function CellCommand.showOrHideDebugBounds(show: boolean): number
	local count = 0
	for _, cellModel in pairs(Level.getCellModels()) do
		if show and not debugBoundsPerCells[cellModel] then
			local newDebugBounds = Draw.box(cellModel:GetBoundingBox())
			debugBoundsPerCells[cellModel] = newDebugBounds
		elseif show and debugBoundsPerCells[cellModel] then
			local debugBounds = debugBoundsPerCells[cellModel]
			local boxHanldeAdornment = debugBounds:FindFirstChildOfClass("BoxHandleAdornment")
			if boxHanldeAdornment then
				boxHanldeAdornment.Visible = true
			end
		elseif not show and debugBoundsPerCells[cellModel] then
			local debugBounds = debugBoundsPerCells[cellModel]
			local boxHanldeAdornment = debugBounds:FindFirstChildOfClass("BoxHandleAdornment")
			if boxHanldeAdornment then
				boxHanldeAdornment.Visible = false
			end
		end

		count += 1
	end

	return count
end

return CellCommand