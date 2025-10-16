# Asymptote Engine: Command System
Commands are a subsystem in the Asymptote Engine.
Just like Mojang's Brigadier, it is based on a tree architecture.

The command system is built under the philosphy of "do what is needed."
Autocompletion and smart errors will be added once Asymptote Engine has gained
popularity and more users will be needing convinience.

My philosphy in this engine is explicitness, which may be verbose at some times.
Much of the programming styles and convention inherits from Java and JavaScript
styles and conventions.

## Making commands
Before we can start parsing and executing commands, we first need a
command tree. From here, we should create a dispatcher, with `<S>` being
something that represents a "source" on who executed the command.

```lua
local dispatcher = CommandDispatcher.new() :: CommandDispatcher.CommandDispatcher<CommandSourceStack.CommandSourceStack>
```

From here, we can start registering commands:

```lua
dispatcher:register(
    CommandHelper.literal("foo")
        :executes(function(context)
            print("Executed foo with no arguments.")
            return 1
        end)

        :andThen(
            CommandHelper.argument("bar", StringArgumentType.greedyString())
                :executes(function(context)
                    local strBarArg = StringArgumentType.getString(context, "bar")
                    print("Foo has yapped", strBarArg)
                    return 1
                end)
        )
)
```

From here, we have command usages of:

`/foo` and<p>
`/foo <bar>`

Common patterns you will see is that you will be using literals and arguments.
Literals are typed exactly how they are, and arguments tell the parser how to
convert texts to actual data you will be using.

Arguments will have the pattern of:

Constructors:

```lua
StringArgumentType.greedyString()
StringArgumentType.string()
StringArgumentType.word()
```

You pass these into the RequiredArgumentBuilder.

And getters:

```lua
StringArgumentType.getString()
```

These provides a type-safe method to actually retrieve the data of arguments
once they are parsed. This is because `context:getArgument("bar")` returns type `any`,
which does not tell you what type the argument supposed to be.

These getter methods will always return a type returned by the arguments' parser,
if an argument does not exist or is of incorrect type, it will throw an error immediately.

Another things are *redirects.* This allow you to have command nodes to "redirect" to another
node. Which can be useful for creating aliases and other arbirtary things.

```lua
local teleportNode = dispatcher:register(
    CommandHelper.literal("teleport")
        :andThen(...)

dispatcher:register(
    CommandHelper.literal("tp")
        :redirect(teleportNode)
)
```

And to actually run them, you can just do:

```lua
dispatcher:execute("/foo Hello there!", CommandSourceStack.createPlayer(player)) -- or whatever "Source" you defined.
```

```
Command system folder tree:
.
├── arguments
│   ├── asymptote
│   │   ├── selector
│   │   │   └── EntitySelectorParser.lua
│   │   └── ItemArgument.lua
│   ├── json
│   │   └── JsonArgumentType.lua
│   ├── position
│   │   └── Vector3ArgumentType.lua
│   ├── ArgumentType.lua
│   ├── BooleanArgumentType.lua
│   ├── DummyArgumentType.lua
│   ├── IntegerArgumentType.lua
│   └── StringArgumentType.lua
├── builder
│   ├── ArgumentBuilder.lua
│   ├── LiteralArgumentBuilder.lua
│   └── RequiredArgumentBuilder.lua
├── context
│   └── CommandContext.lua
├── tree
│   └── CommandNode.lua
├── CommandDispatcher.lua
├── CommandFunction.lua
└── ResultConsumer.lua
```