--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

export type CommandFunction = (context: CommandContext.CommandContext) -> number

return nil