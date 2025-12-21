# Proximity prompts

## The problem
Roblox's current Proximity Prompts *works* but also ***doesn't.***
The current problems are we cannot disable player interactions for proximity prompts or otherwise
that will fuck up the PromptShow and PromptHidden, leading to us having to implement our own check
wether or not a proximity prompt should show or not based on distance, if its on screen or not, etc.

Second is condition evaluation. How do you know if a prompt should be shown and interactible to a player?
Without hardcoding the shit out of everything? Some conditions requires stuff that the server knows or stuff
that the client knows.

## Bugs
There's a slight bug that if a player's camera is at a certain rotation, it will show the prompt
from the other side of the goddamn door.

## Current shit in needs

### Disguise prompt

#### Expected behaviors
Show's the normal prompt if the player currently doesn't have a disguise,
show **"You're already disguised"** if they do.

<figure markdown="span">
  ![Disguise props](/asymptote-engine/assets/images/screenshots/prox-prompt-disguise-false.png){ width="600" }
  <figcaption>Disabled disguise prompt.</figcaption>
</figure>

### Doors (oh boy)
Doors have "Open" and "Close" prompts, right? Currently, when a door is *locked* and *closed*,
the "Open" prompt still shows and players can still interact with it.

<figure markdown="span">
  ![Disguise props](/asymptote-engine/assets/images/screenshots/prox-prompt-door-open.png){ width="600" }
  <figcaption>Door open prompt</figcaption>
</figure>

#### Expected behaviors
If a player doesn't have a way to open the door if it's locked, simply show "Locked".
If the player DOES have a way to open it, such as a key, it will display a
secondary prompt "Unlock", which will unlock the door, and since it's now unlocked,
the normal "Open" prompt appears and the player can open it.

<figure markdown="span">
  ![Disguise props](/asymptote-engine/assets/images/screenshots/prox-prompt-door-locked.png){ width="600" }
  <figcaption>Door locked prompt</figcaption>
</figure>

### Keycard readers

#### Expected behaviors
Just say a message with the object text "Keycard reader" and the message "You don't have the required keycards."
and also when the keycard is in its "unlocked" state, just don't show a prompt.

## Current implementations (still shit)
Proximity prompts are always parented to attatchments. We can add attributes to those attatchments to dictate their
behaviors.

<figure markdown="span">
  ![Disguise props](/asymptote-engine/assets/images/screenshots/prox-prompt-attributes.png){ width="600" }
  <figcaption>Properties of an attatchment that a Proximity prompt will be parented to.</figcaption>
</figure>

### Global and local states
These are basically datas. Global states exist on the server replicated to all clients, while local states
are variables that exist on the client.

### Evaluating conditions
Conditions are evaluated through [*expressions*](https://nirlekaplay.github.io/asymptote-engine/engine/conditional-expressions/) and variables inside those expressions can reference to [other states.](#global-and-local-states)

For example, in this trigger attatchment `HasDisguise` is a local states that is true or false if a player is wearing any disguises.
Using the not operator `!` the condition basically says "Only show this prompt if the player is not disguised."

Still, this still doesn't solve most of the [problems](#the-problem).