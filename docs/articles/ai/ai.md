# Entity AI
Asymptote Engine's entity AI is based on *Minecraft: Java Edition*'s entity AI, especially the *brain system*,
which lacks documentation. If you want to know how Minecraft's brain system, you can see
the documentation for a Minecraft mod named SmartBrainLib for the [brain system](https://github.com/Tslat/SmartBrainLib/wiki/How-do-Brains-Work).

This documentation will provide a high-level overview on how the engine's entity AI works.

## Brain system
All NPCs have a *Brain* object, which acts as the orchestrator of the NPCs' behaviors, memories, and sensors.

## Memories
Memories are a way for NPCs to store data. Think of it as a giant dictionary, where the key is the
memory name with a value assosciated with it.

## Sensors
Sensors are an NPC's eyes and ears. They gather information on the enviremount and set a memory on what they
*sensed.* For example, the `VisibleEntitiesSensor`, every update, it gets all entities in the world
and does line-of-sight checks: is the entity within range? Is the entity visible? Can the entity be heard?
If an entity passes all of these checks, it is then added to the `VISIBLE_ENTITIES` memory. If it didn't, then
it will be removed from the memory.

## Behaviors
Behaviors are what is actually run and dictates on how NPCs behave. For example, the `FollowPlayerSink`
behavior checks if the NPC's `FOLLOW_TARGET` memory is populated. If it is, then it starts following the target
entity, if it is empty, then it will simply stop.

## Activities
Activities are simply a way to group behaviors and their order of execution. Such as `WORK`, `PANIC`, and `CORE`. And only run under specific conditions, such as whether certain memories are populated, not populated, or simply registered.