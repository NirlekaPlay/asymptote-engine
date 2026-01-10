# Setting up your NPCs
What's a stealth game without its NPCs? A ghost town. A lifeless, empty sandbox where nothing moves except your shame.

You can create your own NPCs with their own outfits, gear, and *maybe* personalities. Assuming you can resist naming one "TestDummy" like a lazy degenerate.

## Structure

In your `Level` folder, create a folder named `Npcs` or `Bots`.

Then, add your NPCs as `BoolValue`s or `Configuration` instances. *(fig. 1)*

The engine has no limit on how deep it'll traverse. You can bury your NPC configs fifteen folders deep like a digital graveyard of your sanity, and it'll still find them. Not that you should, it's a level, not an archaeological site.

## Nodes
NPCs need to **spawn** and **go somewhere.** They don't just stand there waiting for meaning in their artificial lives, that's your job.

Create a `Nodes` folder in your `Level` folder *(fig. 2)*. Inside, start adding your nodes as `Part`s. Recommended size is `4, 0.2, 2`, because apparently people still think making nodes the size of a fingernail is a good idea.

Place them around your map *(fig. 3)*. Give them purpose. Let your NPCs have a path, a routine, something to do besides staring into the void.

Nodes must be parented to a folder. That folder becomes a **node group**, which lets different NPCs patrol,different areas, guards in the building, workers outside, and the one weird guy in the bathroom who doesn't move but still counts as a character.

## NPC Attributes
These tell the engine who your NPCs are, what they do, and how much pain they'll cause you when debugging.

Available attributes for **Biopsy 095** include:

* **`CharName`**
  The NPC's name. Non-unique, because god forbid two people can't be named “Bob.” It's used in dialogue and AI chatter. For example, when a guard finds another guard knocked out:

  > “Control! Someone took down Kelly!”
  > See? Instant drama.

* **`Nodes`**
  A string pointing to the name of the node group. If your nodes are in a folder named `OutsidePatrol`, set this attribute to `OutsidePatrol`. The NPC will spawn in one of those nodes and start wandering around like they've got somewhere important to be.

* **`Outfit`**
  A string that defines what your NPC's wearing. Because yes, apparently we need to spell this out. Available outfits include:

    * `PsdPlainColourable`: The PSD uniform that matches the NPC's limb colors.
    * `PsdPlain`: The basic PSD uniform, for when you've completely given up on fashion.

* **`SkinColor`**
  ~~racism~~
  Can be a `Color3` or `BrickColor`. It sets the color of all limbs. Don't make them all bright neon green unless your story involves radiation poisoning.

* **`Asset0`, `Asset1`, `Asset2`, ...**
  These are Roblox catalog asset IDs for accessories. You want a hat? Backpack? Tactical gear? You slap the asset ID here, and it'll get parented to the NPC automatically.