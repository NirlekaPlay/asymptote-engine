--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Level = require(ServerScriptService.server.level.Level)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local LiteralArgumentBuilder = require(ReplicatedStorage.shared.commands.builder.LiteralArgumentBuilder)
local Draw = require(ReplicatedStorage.shared.thirdparty.Draw)

local CellCommand = {}

local debugBoundsPerCells : { [Model]: BasePart } = {}

function CellCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<Player>): ()
	dispatcher:register(
		LiteralArgumentBuilder.new("cell")
			:andThen(
				LiteralArgumentBuilder.new("show")
					:andThen(
						LiteralArgumentBuilder.new("surfaces")
							:executes(CellCommand.showAllCells)
					)
					:andThen(
						LiteralArgumentBuilder.new("bounds")
							:executes(function()
								return CellCommand.showOrHideDebugBounds(true)
							end)
					)
			)
			:andThen(
				LiteralArgumentBuilder.new("hide")
					:andThen(
						LiteralArgumentBuilder.new("surfaces")
							:executes(CellCommand.hideAllCells)
					)
					:andThen(
						LiteralArgumentBuilder.new("bounds")
							:executes(function()
								return CellCommand.showOrHideDebugBounds(false)
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