# Folder Structure
In order for your levels, or *missions* to work, you need to set up your workspace.

In `workspace` make sure you have a `Folder` named `Level`
with this folder structure:

    .
    ├── Barrier (Folder)
    ├── Npcs (Folder)
    ├── Cells (Folder)
    ├── Geometry (Folder)
    ├── Glass (Folder)
    ├── MissionSetup (ModuleScript)
    ├── Nodes (Folder)
    └── Props (Folder)

I will explain what each folder does.

# Barrier
All `Part`s who are descendants of this folder will act as, well, barriers!<p>
In-game, they will become invisible and collides with players, but any other game objects such as NPCs do not. Make sure to keep
these parts anchored.

!!! note "Traversal"

    Keep in mind that the engine does a [depth-first-search](https://en.wikipedia.org/wiki/Depth-first_search) traversal.
    When traversing this folder, it will skip instances that are not `Folder`s.
    This means any Parts inside a `Model`, other `Part`s, or any other instances that are not `Folder`s will not be proccessed.

# Npcs
!!! info

    This folder can be named either `Npcs` or `Bots`, and it will work the same.

What's a stealth game without its NPCs? This is where you store your custom NPCs that will be spawned in-game. They are represented as `BoolValue`s or `Configuration` instances, and their behaviors and appearance are configured by their [attributes](https://create.roblox.com/docs/scripting/attributes#create-attributes).

Only traverses `Folder`s.

## Attributes

### `CharName` *(string)*
A non-unique name that is used in NPC dialogues. For example, if a guard founds a another guard with the `CharName` attribute set to *"Kelly"*, then the guard will say *"Control! Someone took down Kelly!"*

### `Nodes` *(string)*
This is the name of a `Folder` that can be found inside the `Nodes` folder. This is what the engine use to randomly spawn the NPC on the defined nodes and what the NPC uses where to walk.

For NPCs with patrolling behaviors, such as guards, these nodes act like 'posts.' They will choose a seemingly
random node, walk towards it, stay on it for a random time, then choose another node.

!!! info

    If you are using your nodes for NPCs who patrols, the node's `CFrame.LookVector` (positive X-axis)
    will be used for the NPCs to turn to when they arrive and stay at the node.

!!! note

    If you have a node structure like this:

        .
        └── Upstairs (Folder)
            ├── FirstFloor (Folder)
            │   ├── Node (Part)
            │   ├── Node (Part)
            │   ├── Node (Part)
            └── SecondFloor (Folder)
                ├── Node (Part)
                ├── Node (Part)
                └── Node (Part)

    And your `Nodes` attributes is set to '`Upstairs`' then it will also include the nodes of
    '`FirstFloor`' and '`SecondFloor`'.

# Cells
*Cells* or *Zones* are an important part of missions. Currently, they are used to check if a player is trespassing
and what status to give them.

Cells must be a `Model` containing atleast 1 `Floor` and 1 `Roof` which are both `BasePart`s. This is what the engine
use to determine if a point in space is "inside" a cell, which is when said point is BETWEEN a `Floor` and `Roof` parts.

# Geometry
This is where you store static level geometries.

# Glass
This is where you store glass parts. This feature currently does not exist. In the future, glass parts can be shot,
broken, and see through for NPCs.

# Nodes
Not to be confused with waypoints, nodes can be used for a variety of cases for NPCs, such as patrolling posts,
and investigation areas. Nodes must be `BasePart`s, and you can place them around the map to your liking.
Just make sure that NPCs can actually pathfind there.

# Props
Oh boy. You will use this often. Props are either static assets represented with placeholders that are replaced
with the actual prop asset during level initialization, or fully functional props. This section will be expanded.