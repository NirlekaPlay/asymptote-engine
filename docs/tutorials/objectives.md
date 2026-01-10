# Objectives
These are the main juice of your mission. You can't expect the player to know
what the hell they're supposed to do. Let alone remember them. That's what objectives are for.

## MissionSetup
In your `MisionSetup` ModuleScript, add a new table `Objectives`, this is where you store
your objectives. No shit.

## Setting up Objectives
Each *objective* has 4 components:

* `Active` ([expression](../engine/conditional-expressions.md))
* `Text` (string) These points to a localized string, either a localized string inisde the engine itself
or strings defined in the `CustomStrings` table in `MissionSetup`.
* `Tag` ([expression](../engine/conditional-expressions.md)) A conditional expression that returns
a string which is a *tag*. Note that this is a goddamn expression, so if you simply just put in your
localized string direct (e.g. "AssTarget") the expression parser will treat it as a variable and not a string
Instead, use quotes or double quotes. (e.g. "'AssTarget'"). You can learn more about tags [here](#objectives-tagging).
* `SubState` (table) Another table that contains an array of objectives to be evaluated.

## How Objectives are evaluated
Only *one* objective can be shown per header. If a header has all objectives where the `Active` component
returns a falsy value, the entire header is not shown. Objectives are evaluated top to down. You realise
that the objectives of each header are arrays right? Yeah it iteares through all objectives and stops
and shows the first objective where the `Active` component returns a truthy value.

## Objectives Tagging
<figure markdown="span">
  ![Disguise props](/asymptote-engine/assets/images/screenshots/objectives-tags-keycard.png){ width="10000" }
  <figcaption>Fig. 1. A tagged keycard under the Stealth header.</figcaption>
</figure>
You know *tags* right? The little icons on your screen that points towards the objectives' object?
It can be a keycard, an NPC, a trigger zone, anything. Or, almost anything.

You can add tags to any props' placeholders by simply adding the `Tag` attribute and then
put in the tag you want. If the object you're trying to tag is not inherinetly the object itself, such
as the `ItemSpawn` prop, it has its own tag attribute like `ItemTagString` that tags the item it spawns.

Tags' icons and color is tied to their specific headers. `Mission` header will be a simple purple circle.
While the `Stealth` header is a blue circle with a disk inside it.