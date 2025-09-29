--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

export type ResultConsumer<S> = {
	onCommandComplete: (context: CommandContext.CommandContext<S>, success: boolean, result: number) -> ()
}

return nil