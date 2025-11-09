# Props
Props are what make your levels feel ***alive***, some props are static and
some props are gameplay objects.

## Level structure
    Level (Folder)
    └── Props (Folder)
        └── ...
Your props should all go to the `Props` folder. Shocking, I know.
The engine only traverse `Folder`s, so props inside instances that are not folders
will not get proccessed.

Meanwhile in `ReplicatedStorage`...

    Assets
    └── Props (Folder)
        └── ... (Models)

You place your actual prop models here. Know how to set your own prop models in [Making your own props](#making-your-props).

## Clutter system
The *clutter system* refers to the engine replacing placeholders in the `Props`
folder with the actual asset.

### Placeholders
You do not directly place your prop assets inside the `Prop` folder otherwise that will defeat
the purpose of a clutter system.

Instead, you place *placeholders* around the map, placeholders are `BasePart`s that will be replaced
with their actual props when the level starts.

### Making your props
All props must be a `Model`. And it must have a `BasePart` named `Base` which acts as the pivot.

### Recoloring
To reduce redundancy and making all the devs go insane, you can create color variations of your props
without needing to change every goddamn parts of your prop to that color.

With the placeholder, set attributes like `Color0` `Color1` `Color2` etc, and in your prop model
have parts you want to recolor with `Part0` `Part1` `Part2` etc.

Attributes can be `Color3`, `BrickColor` and `string`. If you wan't string, you need to set them up
in `MissionSetup` and have a field named `Colors` which contains your colors.

::: warning

    If there's a gap in your attributes, like `Color0` `Color4` the engine will not
    proccess `Color4` and only proccess `Color0`.

```lua
Colors = {
    Metal = Color3.fromRGB(20, 20, 20)
}
```