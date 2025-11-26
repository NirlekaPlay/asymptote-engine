# Props Reference
Some props may not be static and will actually hold specific functions.

## SpawnLocation
If there are placeholders named `SpawnLocation` it will be replaced with an actual
[SpawnLocation](https://create.roblox.com/docs/reference/engine/classes/SpawnLocation) instance,
completely transparent and without the default decal.

## GuardCombatNode
If the alert level went to **Searching** or **Lockdown**, guards will retreat to these
positions.

This is also what guards use when attempting to flee.

## SoundSource
Sound source are sources of sounds. Wow no shit.

### Attributes
 * `Active` (string) This is an [*expression*](../engine/conditional-expressions.md) that determines when the sound will play.
 If this returns a *falsy value* (`nil` / `false`), the sound will not play or stop if it's already playing.
 * `Looped` (boolean) This sets if the sound loops or not. Mindblowing.
 * `SoundId` (number | string) No shit you will need this, this is the asset id of the sound
 you want to play.
 * `Volume` (number) The volume of the sound. Do i need to explain all of this shit to you????