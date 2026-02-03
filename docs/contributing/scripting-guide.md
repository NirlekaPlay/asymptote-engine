# Nirleka's Guide to Scripting
Do note that you don't *ALWAYS* need to follow these guides. If you're doing quick and dirty prototyping to prove your theories,
then you don't really need to follow all of these. This guide is mostly for production ready code.

## Naming Conventions
* Classes, server, client, and module scripts: **UpperCamelCase**.
* Variables, functions, fields: **lowerCamelCase**.
* Constants: **UPPER_SNAKE_CASE**.

## Use Luau's Static Typechecker
Use `--!strict` at the top of a file to enable Luau's strictest type checking. This prevents you from giving a function the wrong
parameter types, mispelling variable names, etc, through autocomplete.

## Declaration of Variables
### Roblox Services
Services used in a script should all be declared on the top of the script, preferably in alphabetical order.

Avoid directly accessing services using the dot `.`, for example `game.ReplicatedStorage`, instead use `game:GetService(...)`, like `game:GetService("ReplicatedStorage")`.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
```

### Types
If you declare a variable but you do not set a value to it immediately, or it's initially `nil`, specify the type of the variable.

```lua
local destroyingConnection: RBXScriptConnection
```

And of course, if it could be `nil`, use `?`

```lua
local destroyingConnection: RBXScriptConnection?
local currentTarget: Player? = nil
```

Avoid specifying the type if you *DO* set it immediately

```lua
local initialStartTime: number = 10 -- Avoid this, it's redundant
local initialStartTime = 10 -- This is acceptable
```

An exception to this is for tables and other types that uses generics or contains something.

```lua
local closestPlayers = {} -- Avoid this
local closestPlayers: { [Player]: true } = {} -- Do this instead
```

Another example for other types:

```lua
local currentWalkTarget: WalkTarget<Player>? = nil
```

## Classes
Avoid writing all systems and logic into a single monolith script. Seperate the systems into module scripts.
A typical module script will have this as the canvas:

```lua
--!strict

--[=[
    @class Class

    A class. Mindblowing I know.
]=]
local Class = {}
Class.__index = Class

export type Class = typeof(setmetatable({} :: {
    field: string
}, Class))

function Class.new(): Class
    return setmetatable({
        field = "A field"
    }, Class)
end

function Class.getField(self: Class): string
    return self.field
end

return Class
```

## Functions
### Declaration
Avoid using the colon `:` when declaring functions where it is part of a class.

Avoid:

```lua
function Class:getField(): string
    return self.field
end
```

Instead do:

```lua
function Class.getField(self: Class): string
    return self.field
end
```

This lets the typechecker know what `self` is. Elsewhere, you can still call the function normally with a colon:

```lua
local fieldString = classInstance:getField()
```

### Declaring a Function's Parameters and Returns
If your function takes something and returns something, you should state their types.

```lua
local function add(x: number, y: number): number
    return x + y
end
```

Multiple returns:

```lua
function ServerPlayer.getNameAndSurname(self: ServerPlayer): (string, string)
    return self.name, self.surname
end
```

And if it doesn't return anything, explictly state it by using `()`

```lua
local function doSomething(): ()
    -- Does something.
end
```

### Using Functions
Avoid using direct access to a class's fields. Use getter and setter methods instead. For example:

Avoid:

```lua
local entityPos = entity.position
```

```lua
entity.walkSpeed = 16
```

Instead do:

```lua
local entityPos = entity:getPosition()
```

```lua
entity:setWalkSpeed(16)
```

This lets you change on *how* a position is retrieved without having to modify every single script that wanted to retrieve the position
of an entity.

```lua
function Entity.getPosition(self: Entity): Vector?
    if not self:isAlive() then
        return nil
    end

    return self:getCharacter().HumanoidRootPart.Position
end
```

And this lets you change how a walkspeed is set for each entities. If you want an entity that doesn't use a humanoid, you can
change how it's implemented without other scripts needing to handle each entity types.

```lua
function Entity.setWalkSpeed(self: Entity, walkSpeed: number): ()
    if not self:isAlive() or not self.humanoid then
        return
    end

    self.humanoid.WalkSpeed = walkSpeed
end
```

Of course, this is for external uses. This becomes less important if you're using them inside the class functions itself.

```lua
function Entity.update(self: Entity, deltaTime: number): ()
    if not self:isAlive() then
        return
    end

    if self.isGoingInsane then
        self.sanity -= deltaTime
    end

    if self.sanity <= INSANITY_THRESHOLD then
        self:ascend()
    end
end
```

## Constants
Constants are variables where its value never change during runtime. Avoid using raw, *magic numbers*, strings, or other datas in your logic.
This makes it easier for other people reading your code to know what those values are for. And also makes it easier for you to change them
if there are multiple logics using the same constant.

You should declare constants at the upper part of the file.

```lua
local MIN_WAIT_TIME = 0.1
local MAX_WAIT_TIME = 1.5

local waitTime = Random.new():NextNumber(MIN_WAIT_TIME, MAX_WAIT_TIME)

task.wait(waitTime)
```

## Design Patterns

### Interfaces
Interfaces are type definitions that describes what a class *should* look like without knowing its internal logic. This allows you
to make a function that accepts any object, as long as that object has the required methods the specified interface have.

```lua
export type Damageable = {
    takeDamage: (self: any, amount: number) -> (),
    getHealth: (self: any) -> number,
}
```

```lua
function Server.hurtExplosion(self: Server, damageable: Damageable): ()
    -- Some logic or something...
    local calculatedDamage = 10

    -- Then:
    -- Here, we don't care on how the class actually *handles* damage.
    damageable:takeDamage(calculatedDamage)
end
```

Then we can have other classes implement that interface and supply it into the function:

```lua
function ServerPlayer.takeDamage(self: ServerPlayer, amount: number): ()
    if not self:isAlive() then
        return
    end

    self.humanoid.Health -= amount
end
```

```lua
function Npc.takeDamage(self: Npc, amount: number): ()
    if not self:isAlive() then
        return
    end

    self.health -= amount
    if self.health <= 0 then
        self:kill()
    end
end
```