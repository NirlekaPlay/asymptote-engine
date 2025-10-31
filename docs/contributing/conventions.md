# Bugs
If you believe to have found a bug in any of our games using the Engine that is related to the Engine itself, please open a [GitHub issue](https://github.com/NirlekaPlay/asymptote-engine/issues/new). It helps if you also include the engine version where the bug happened.

## Contributing

### Naming Conventions

Our project primarily follows Java naming conventions as a foundation for consistency across code and assets.

#### Directories

Directory names should use all lowercase letters.
**Example:** `server`, `client`, `alertlevel`

#### Scripts

* Luau scripts must use the `.lua` file extension.
* Client, server, and module scripts should follow **UpperCamelCase**.
  **Examples:** `Brain.lua`, `JoinServerLobbies.server.lua`, `Detection.client.lua`

#### Roblox Files

* Roblox instances (e.g., ScreenGuis, sounds) should use the `.rbxmx` file extension, which is XML-based.
* Asset files, such as sounds, should use **lower\_snake\_case**.
  **Example:** `detected_sound.rbxmx`
* Other Roblox files, such as GUIs, should use **UpperCamelCase**.
  **Example:** `DetectionGui.rbxmx`

### Scripting Naming Conventions: Nirleka's Rant

#### Classes, Interfaces, and Types

Classes, interfaces, and types should use **UpperCamelCase.**
Use whole words and must avoid acronyms and abbreviations.

```lua
local BrainDebugRenderer = {}
```

```lua
local Entity = {}
Entity.__index = Entity
```

```lua
export type Sensor<T> = {
	doUpdate: ( self: Sensor<T> , agent: T, deltaTime: number) -> ()
}
```

#### Functions and Methods

Functions and methods should be verbs and use **lowerCamelCase.**

```lua
function Brain.setMemoryInternal<T, U>(self: Brain<T>, memoryType: MemoryModuleType<U>, optional: Optional<ExpireableValue<U>>): ()
	if self.memories[memoryType] then
		if optional:isPresent() and isEmptyTable(optional:get():getValue()) then
			self:eraseMemory(memoryType)
		else
			self.memories[memoryType] = optional
		end
	end
end
```

#### Variables

Variables should be descriptive, and use **lowerCamelCase.**

```lua
local lastDetectionValue = 10
```

And I swear to God, **DO NOT ABREVIATE.**

```lua
local larm
local rarm
local lleg
local rleg
local head
local torso
local hrp
```

Look at this monstorsity. You can not understand jackshit. When you write code, always assume that there will be a poor soul that is gonna read, understand, and refactor your code.

The good way to do is:

```lua
local leftArm: BasePart
local rightArm: BasePart
local leftLeg: BasePart
local rightLeg: BasePart
local head: BasePart
local torso: BasePart
local humanoidRootPart: BasePart
```

Oh now my eyes won't cry anymore. Now I can easily understand what the hell the variables means and do.

Oh and also, since these are not set immediately, **ALWAYS ADD A SPECIFIC TYPE.** This does not include variables where the type is obvious. Such as:

```lua
local deltaTime = 0.5
```

We already know what the hell deltaTime is. A number. However, if a variable is not set immediately:

```lua
local detectedEntity
```

Now we know jackshit on what the hell "detectedEntity" supposed to be. Sure, you're gonna set it *SOMEWHERE* but that adds extra suffering.

Even if the name is *somewhat* obvious, You should always add a type.

```lua
local detectedEntity: Entity
```

This applies to tables as well.

```lua
local entitiesByUuid = {}
```

What the fuck does this supposed to store? Sure we immediately set it to a table, but that tells us jackshit on what it's supposed to be storing.

Adding a type provides *clarity.*

```lua
local entitiesByUuid: { [string]: Entity } = {}
```

This also won't leave the type checker to slap in you in the face when trying to set a value to a table.

Now you might be saying *"But nir!1! What if I need to change the variable's type-"* **NO.** Variables should store only ONE type. ***ONE.*** What circumstances where variable need to change multiple types of data???? Thats just stupid! This applies to tables as well! Do not have a goddamn table which stores multiple types of data!

#### Comments

Comments are either tools for developers to tell other developers what a piece of code does, or a way for a developer to vent.

```lua
--[=[
	If a value is present, returns the value, otherwise returns `other`, which may be `nil`.
]=]
function Optional.orElse<T, U>(self: Optional<T>, other: U): T | U
    -- I SWEAR TO GOD THE TYPECHECKER WONT STFU
	return if (self.value :: any) ~= nil then self.value else other
end
```

Oh, the contrast. The documentation comment everyone sees when they hover their little mouse over the method. Clean. Elegant. The person using the method will think the code is all sunshine and rainbows. Until you get to the comments inside the method.

Yes. It is acceptable to vent your frusterations and rage. Infact, its ***MANDATORY.***

### Constants
For the love of all that is holy, please do not write [magic numbers](https://en.wikipedia.org/wiki/Magic_number_(programming)), or any other hard-coded values. Do not, and **I mean under no godforsaken circumstance—write magic numbers in your code.**

You know what I'm talking about. Those random little gremlins like `42`, `0.37`, or `69` (nice)
that you sprinkle into your logic because "you'll remember what it means later."
You won't. You never will. Future you will stare at it six months from now, dead-eyed, wondering which
past-life version of yourself thought `0.73` was a perfectly reasonable value for "ghost spawn offset."

For example:

```lua hl_lines="3"
function DeanHaunt.spawnBehindPlayerIfPossible(rootPart: BasePart): ()
	-- ...

	local spawnDistance = rng:NextNumber(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)

	-- ...
end
```

See that? That's clean. That's readable. That's merciful. Someone can open this file, see `MIN_SPAWN_DISTANCE`
and `MAX_SPAWN_DISTANCE`, and actually have a fighting chance of figuring out what the hell is going on.
That's civilization right there.

Now imagine this instead:

```lua
local spawnDistance = rng:NextNumber(7.5, 13.25)
```

Congratulations, you've just created a mystery novel no one asked for. What's 7.5? What's 13.25? Are those meters? Studs? The number of brain cells you lost debugging this later? No one knows. Every developer who encounters it loses a little sanity reading it.