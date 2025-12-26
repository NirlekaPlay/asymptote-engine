# Making Your Own Command
Making your own commands requires you to modify the engine's source code.
And since I'm kind enough to open source it, you can download the source code from the GitHub repo,
clone it, and sync it to Roblox Studio using Rojo.

Asymptote Engine's command parser is based on Mojang's [Brigadier](https://github.com/Mojang/brigadier) command parser,
which they used in Minecraft Java.

## Command Tree
Every part of a command is represented as a *node*,
and the "tree" is formed by how these nodes are linked together.

### Components
The main node types of every tree are:
 * **Root Node.** The starting point of any command, it does not contain logic but serves as the parent for all registered commands.

 * **Literal Nodes.** These are fixed strings of a command, such as `kill` and `teleport`. They are used for
 command names and sub-commands. All commands must start with a literal node for the command's name.

 * **Argument Nodes.** This is where the users can input data, such as booleans `true` and `false`,
 numbers, strings, entity selectors, and many more to turn texts to data during parsing.

Take the `/kill` command for example:

```lua
dispatcher:register(
    CommandHelper.literal("kill")
        :executes(function(c)
            return KillCommand.kill(c, {c:getSource():getPlayerOrThrow()})
        end)
        :andThen(
            CommandHelper.argument("victims", EntityArgument.entities())
                :executes(function(c)
                    local targets = EntityArgument.getEntities(c, "victims")
                    return KillCommand.kill(c, targets)
                end)
        )
)
```

And here's a representation of that tree:

```
(root)
  └── "kill" (literal) [executable]
        └── <victims> (argument: entities) [executable]
```

This allows for deep nesting commands, sub-commands, and arguments.

## Programming Your First Command
All server-side logic for commands are located in `src/server/commands`. While the command parser
itself is located in `src/shared/commands`.

To create your first command, let's make a simple `/greet` command. First make a new file,
something like `GreetCommand.lua`, and place somewhere you won't lose it. Inside the file,

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CommandHelper = require(ServerScriptService.server.commands.registry.CommandHelper)
local CommandSourceStack = require(ServerScriptService.server.commands.source.CommandSourceStack)
local CommandDispatcher = require(ReplicatedStorage.shared.commands.CommandDispatcher)
local EntityArgument = require(ReplicatedStorage.shared.commands.arguments.asymptote.EntityArgument)
local CommandContext = require(ReplicatedStorage.shared.commands.context.CommandContext)

local MutableTextComponent = require(ReplicatedStorage.shared.network.chat.MutableTextComponent)
local NamedTextColors = require(ReplicatedStorage.shared.network.chat.NamedTextColors)
local TextStyle = require(ReplicatedStorage.shared.network.chat.TextStyle)

local GreetCommand = {}

function GreetCommand.register(dispatcher: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>): ()
	dispatcher:register(
		CommandHelper.literal("greet")
			-- Path 1: /greet
			:executes(function(c)
				local sender = c:getSource():getPlayerOrThrow()
				return GreetCommand.greet(c, {sender})
			end)
			-- Path 2: /greet <target>
			:andThen(
				CommandHelper.argument("target", EntityArgument.entities())
					:executes(function(c)
						local targets = EntityArgument.getEntities(c, "target")
						return GreetCommand.greet(c, targets)
					end)
			)
	)
end

function GreetCommand.greet(c: CommandContext.CommandContext<CommandSourceStack.CommandSourceStack>, targets: {Player}): number
	local sender = c:getSource():getPlayerOrThrow()
	local senderName = sender and sender.DisplayName or "System"

	for _, player in targets do
		local message = MutableTextComponent.literal("Hello ")
			:appendComponent(
				MutableTextComponent.literal(player.DisplayName)
					:withStyle(TextStyle.empty():withColor(NamedTextColors.YELLOW):withBold(true))
			)
			:appendString(", ")
			:appendComponent(
				MutableTextComponent.literal(senderName)
					:withStyle(TextStyle.empty():withColor(NamedTextColors.DARK_AQUA):withItalic(true))
			)
			:appendString(" says hi!")

		c:getSource():sendSuccess(message)
	end
	
	return #targets
end

return GreetCommand
```