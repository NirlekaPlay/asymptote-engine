--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

export type CommandFunction<S> = (context: CommandContext.CommandContext<S>) -> number

return nil