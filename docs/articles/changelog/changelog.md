All dates are in DD/MM/YY format.

### A001 (12/07/25)
"Testing the absolute insanity ive just created.
Its an AI system test, expect some jiggles and shit.
This only took me a week
which is acceptable
You can yap about the feedback here or general or i dunno.
anyway ima go to sleep."

# Commit a46aaa6 (13/07/25)
## Commit message *feat: testing chasing trespasser mechanic*
## 5 files changed, 244 insertions(+), 81 deletions(-)
 * Uses SimplePath for pathfinding logic

### A002 (16/07/25)

[Detection Changes]
 * Detection is calculated differently.
 * Testing wooshing sound upon detection.
 * Improved curious state, Agent will now look at Players, and faces the Player when detection reaches 60%. And will get back to normal when it is not detecting anything for another 2 seconds.

### Published Commit 002 (16/07/25)
 * Testing FaceControl

### Published Commit 003 (16/07/25)
 * Brought back RandomPostGoal
 * Bob now takes 2 seconds to begin patrolling after encountering some sussy players

### Published Commit 004 (16/07/25)
 * Bob only stops patrolling when curious
 * Spaced the GuardPosts a little bit

### Published Commit 005 (16/07/25)
 * Fixed Bob not doing his fucking job

### Published Commit 006 (16/07/25)
 * Upon getting detected, is now handled properly, you have to not be suspicious in order to get detected again
 * Bob will get mad at you if you get detected and stare at you.

### A003 (17/07/2025)
[Major Update]
 * Bob now has bubble chats.
 * Bob will be mad at you and warn you if you trespass.
 * Bob now has a new pew pew toy and will attempt to kill you.

### Published Commit 007 (17/07/25)

 * Brought back avatar for players
 * Changed Bob frown

### Published Commit 008 (17/07/25)
 * Use HDIfy to make the faces HD and not make it look like utter crap

### A004 (17/07/25)
[Major Update]
 * All previous published commits.
 * Bob now has memories. You will be shot on sight if you don't get caught again after 20 secs. If you get caught again within that time frame, Bob's memory on you will be boosted by 20 more secs.
 * Different dialogues for different encounters of repeatedly getting caught.
 * Remove Bob's name tag.

17/07/25 9:29 PM "Source code cuz im nice"
Source code GitHub repo released

### Published Commit 010 (18/07/25)
 * Attempt to fix rotation lags (impossible)
 * Fixed animation being a piece of shit
 * Some other stuff that my puny little brain can't comprehend why I should put it on this list

### A005 (18/07/25)
[Major Update]
 * You have a gun.
 * You can kill Bob.
 * Improved some detection mechanisms.
 * New updates to FaceControl, face can change based on specific events
 * You can now intimidate Bob. WIth your gun.
 * Bob has new drip
 * You are given the Bob Spawner™
 * Various others

### Published Commit 011 (19/07/25)
 * Bob spawner can be spammed
 * Fixed some other bugs

### Published Commit 013 (19/07/25)
 * Fixed statuses stuff.
 * Fixed Bobs patrolling system, such as staying there like a dumbass when spawning.
 * New debug GUI

### A006 (19/07/25)
[Major Update]
 * You have a bastardized C4. (press 9 to detonate, while holding it) 
 * Bob will react accordingly if you are holding one.
 * Various others

"I think this is more less like a stealth game and more of a ***Bullying Bob***"

### Published Commit 014 (19/07/25)
 * Raised Bob's suspicion speed to 1.25 seconds.
 * Add disguise system, affecting your detection speed and makes you access restricted areas without getting detected.

"I'll announce that map design will start once the core mechanics of the game are implemented"

### Published Commit 015 (19/07/25)
 * Add version ui

### Published Commit 022 (20/07/25)
 * Complete rework on the detection system
 * Responses are removed except for being shocked, which can be triggered by pulling out your FBB out of your ass
 * Add quesiton mark icon to curious Bobs

### Published Commit 026 (21/07/25)
 * New proximity prompts
 * New status UI????? (i forgor)
 * Bob will no longer detect you if you are disguised
 * Some slight development changes to Bob but do not bother about it

"I feel sorry to people who havent played versions before *Commit 022*"

### Published Commit 027 (21/07/25)
 * Made detection meter smaller
 * Some performance optimisation
 * New baseplate texture (you'll get used to it.)

### Published Commit 028 (fav) (21/07/25)
 * Status bar GUI got a full make over. Making it easier on the eyes, and not make your eyes squint every time you want to look at it.

### Published Commit 029 (21/07/25)
 * Small changes on the version text.

### Published Commit 030 (22/07/25)
 * Some performance optimization for Bob's rotation control.
 * Fix status bar not updating after death.
 * The wooshing sound upon detection is now unique to every single Agent, and slight pitch variation.

### Published Commit 031 (22/07/25)
 * In an attempt to fix the shitty gun system, I am making a test on the GunControl module.

"I am getting desperate
Help"

### A007 (23/07/25)
[Major Update]
 * Meet Jeia.
   * Can detect through disguises.
   * Cannot be intimidated.
   * Has divine authority.
 * Testing new targeting systems, Agents that can be intimidated (Bob) will not pull out a weapon if the armed player is close to him.
 * Ported Project Gamma killhouse map to the game.
 * Guard posts and trespassing zones are now invisible.
 * New dialogues.
 * Guns have random spray now.
 * Various other things my puny brain cant list here. I think I have amnesia.

"Its gonna get complicated isnt it?"

Shows a screenshot of the `Brain.lua` file.

"If i see another fucking circular dependency bullshit
I will personally commit domestic terrorism"

### Introducing Experimental Servers (30/07/25)

Just like in Operators, You now posses the unholy power that is switching servers. Click the "Join Testing Server" button which is next to the engine version on the top right.

Experimental servers will have silent updates and have different version identifier. (e.g. Absentia 027) and you will have access to up to date, buggy messhole I've been making for the past week.

Note that you need to leave and join again to get back to normal server.

01/08/25
Shows screenshot of the Brain debug renderer, showing Jeia's memories, activites, and behaviors.

### Published Commit 067 (03/08/25)
 * Added loading screen when teleporting to testing server. Go check it out. Spent 45 minutes on that shit. (anticlimactic.)

### Published Commit 040 & Experimental Biopsy 034 (16/08/25)
 * Embed the engine version ui, join server button, loading screen, and teleportation to the engine itself.
 * Internal changes to the engine version ui.
 * Makes teleporting from stable to experimental and vice versa not feel like utter shit. Both stable and experimental have the same engine ui API so that it can handle both version without making me having a migraine.
 * Fixed inconsistencies and loading screen issues not showing the correct quote of the day.
 * Both now have fade animations.

___

### Published Commit 039 (06/08/25 by Alice)

Hello there my little goobers!
Nir the dumbass forgot to tell you that the "join testing server" button is hidden!
Just hold the version text for more than 3 seconds and it should appear.

There has been a lot of silent updates on the experimental server too, Nir is testing the most random things imaginable.

Anyway, have fun!

**Asymptote Engine dev blog** (06/08/25)

Pheee, it appears my progress for development has been blocked by analysis paralysis on how do I implement the new AI architecture to handle all sorts of behaviors.

This has been a major poison for numerous other project I've worked on. But for this project I took a different approach, which is "Fuck it, I program that will produce results" which has made the whole thing running smoothly. Until now. But of course, I wouldn't abandon another project, especially this one where we came this far.

So, I think I should just push the experimental updates to Stable version, maybe add some small updates like bug fixes, goofy stuff like C4s, and other chaotic stuff  you testers love.

While I continue working on the AI architecture, as it may take some time. Maybe too much time.

So yeah, thank you for everyone for testing my goofy little project, may it be completed someday.

___

At this point, the tree looked like this:

```
.
├── client
│   ├── PlayerScripts
│   │   ├── modules
│   │   │   ├── core
│   │   │   │   └── CoreCall.lua
│   │   │   ├── gui
│   │   │   │   └── WorldPointer.lua
│   │   │   └── interpolation
│   │   │       └── RTween.lua
│   │   ├── BubbleChat.client.lua
│   │   ├── CoreGui.client.lua
│   │   ├── Detection.client.lua
│   │   ├── GuiFocusAnimation.client.lua
│   │   ├── HealthSaturationEffect.client.lua
│   │   ├── PlayerHeadRotation.client.lua
│   │   ├── ProximityPrompts.client.lua
│   │   └── Status.client.lua
│   ├── ReplicatedFirst
│   │   └── PreserveLoadingScreen.client.lua
│   └── StarterGui
│       ├── Detection.rbxmx
│       └── Status.rbxmx
├── server
│   ├── ai
│   │   ├── attributes
│   │   │   └── Attributes.lua
│   │   ├── behavior
│   │   │   ├── Activity.lua
│   │   │   ├── Behavior.lua
│   │   │   ├── BehaviorControl.lua
│   │   │   ├── BehaviorWrapper.lua
│   │   │   ├── ConfrontTrespasser.lua
│   │   │   ├── DummyBehavior.lua
│   │   │   ├── FleeToEscapePoints.lua
│   │   │   ├── GuardPanic.lua
│   │   │   ├── LookAndFaceAtTargetSink.lua
│   │   │   ├── LookAtSuspiciousPlayer.lua
│   │   │   ├── PleaForMercy.lua
│   │   │   ├── SetIsCuriousMemory.lua
│   │   │   ├── SetPanicFace.lua
│   │   │   └── WalkToRandomPost.lua
│   │   ├── control
│   │   │   ├── BodyRotationControl.lua
│   │   │   ├── BubbleChatControl.lua
│   │   │   ├── FaceControl.lua
│   │   │   ├── GunControl.lua
│   │   │   ├── LookControl.lua
│   │   │   └── TalkControl.lua
│   │   ├── debug
│   │   │   └── BrainDebugger.lua
│   │   ├── goal
│   │   │   ├── Goal.lua
│   │   │   ├── GoalSelector.lua
│   │   │   ├── LookAtSuspectGoal.lua
│   │   │   ├── RandomPostGoal.lua
│   │   │   ├── ShockedGoal.lua
│   │   │   └── WrappedGoal.lua
│   │   ├── memory
│   │   │   ├── ExpireableValue.lua
│   │   │   ├── MemoryModuleTypes.lua
│   │   │   ├── MemoryStatus.lua
│   │   │   └── Optional.lua
│   │   ├── navigation
│   │   │   ├── GuardPost.lua
│   │   │   └── PathNavigation.lua
│   │   ├── sensing
│   │   │   ├── DummySensor.lua
│   │   │   ├── HearingPlayersSensor.lua
│   │   │   ├── Sensor.lua
│   │   │   ├── SensorType.lua
│   │   │   ├── SensorTypes.lua
│   │   │   ├── SensorWrapper.lua
│   │   │   └── VisiblePlayersSensor.lua
│   │   ├── suspicion
│   │   │   └── SuspicionManagement.lua
│   │   └── Brain.lua
│   ├── disguise
│   │   └── PropDisguiseGiver.lua
│   ├── npc
│   │   └── guard
│   │       ├── Guard.lua
│   │       └── GuardAi.lua
│   ├── player
│   │   ├── PlayerStatus.lua
│   │   └── PlayerStatusRegistry.lua
│   ├── zone
│   │   ├── TrespassingZone.lua
│   │   └── TriggerZone.lua
│   ├── Agent.lua
│   ├── ArmedAgent.lua
│   ├── DetectionAgent.lua
│   ├── PerceptiveAgent.lua
│   ├── PlayerHeadRotation.server.lua
│   ├── Server.server.lua
│   └── TalkingAgent.lua
└── shared
    ├── assets
    │   └── sounds
    │       ├── detection_undertale_alert_temp.rbxmx
    │       ├── detection_woosh.rbxmx
    │       └── disguise_equip.rbxmx
    ├── network
    │   └── TypedRemotes.lua
    └── thirdparty
        ├── Draw.lua
        ├── SimplePath.lua
        └── TypedRemote.lua
```

___

Beginning the updates on Biopsy

### Experimental - Biopsy 018 (07/08/25)
[ C4 Changes ]
 * Faze's C4 has been reworked.
 * Placement will have the C4 placed perpendicular to the surface.
 * Fixed issues where C4s being detonated while arming after the detonator is activated.
 * Fixed dangerous item status discrepancies when holding the C4 in plant mode.
 * Walls can protect you from explosions. (I don't know if you want that or not)
 * Testing a feature where other undetonated C4s will explode when another C4 near its blast radius explodes.

### Experimental - Biopsy 025 (10/08/25)
 * Fixed decaying status' value not being transfered to a higher priority status upon detection.

### Experimental - Biopsy 026 (10/08/25)
 * Fixed detection meter being visibly stuck despite the detection value of zero.

### Experimental - Biopsy 027 (11/08/25)
 * Fixed shit that I can't explain.

### Experimental - Biopsy 028 - "The Shooting and Reactionary Update" (11/08/2025)
I think I had too much fun.
 * Missed the guns and shooting? Or not? Cuz you get spawn camped? Well too bad, Jeia now has a gun.
 * Jeia will attempt to flee at the sight of an armed player or a bomb. And will try to kill you. And don't worry, she won't keep shooting like last time.
 * Unique dialogues for different encounters, for both Jeia and Bob.
 * Added hearing sensors.
 * Several bug fixes and insignificant things I won't list here.
 * *Debug mode is now off by default. Press **N** to toggle it.*

Bugs are to be reported, thank you for your service.

### Experimental - Biopsy 029 (11/08/25)
 * Fixed Jeia's slow body turning.
 * Fixed Jeia's face not properly updating.
 * Fixed debug mode not toggling correctly.

### Experimental - Biopsy 030 (12/08/25)
 * Jeia now properly looks at you with the gun. And also after you die while she's doing her monologue. Yes. Of course.
 * Added reverb cuz why not.

### Experimental - Biopsy 031 (12/08/25)
 * Removed swear words from some dialogues.
 * 🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪🔪

### Experimental - Biopsy 032 (14/08/25)
 * Testing animation controller. Very small update, agents receives animation controllers, which should have animations for walking and running.
 * If it looks like utter shit, report it.

###  Experimental Biopsy 036 (18/08/25)
We're going serious on the reaction heaviors cuz I'm running out of time before school starts again.

[Minor Update]
 * Added an indicator for keybinds you can do.
 * Testing trespassing behavior. Please report any abnormalities in <#1401319093243609189> suggestions and feedback are also appreciated.
  * If you don't know how to join experimental server go to pins on this channel or ask someone.

###  Experimental Biopsy 037 (19/08/25)
 * Internal development on a debug pipeline.
 * Full rework on the brain debug renderer. Brain debug data are dumped from the server to the client if the client is listening. Reducing latency and increase performance.
 * Visual changes on the debug ui itself. Text can now span as long as they can, instead of decreasing its size, and changed the font.
 * Add a UI to show what debug renderer you enabled or disabled.
 * Detailed information of NPCs are only displayed if your cursor is pointed directly at them. Names are always displayed.
 * Pressing `N` will only toggle the brain debug renderer.
 * Testing freecam, which can be toggled by pressing `CTRL + SHIFT + P` or just `SHIFT + P`
 * Planning to remove the server-side rays debugger.
 * This took 2 and a half days to make.

###  Experimental Biopsy 038 (19/08/25)
 * Disabled some raycast debuggers.

###  Experimental Biopsy 039 (20/08/25)
Hello, yes, I'm going insane because I've been working on this shit for 3 days now.
But that's fine. I am a man of ***standards*** and i did a thing. Too many things, Infact.
 * Some internal optmisation on the BrainDebugRenderer. Now you can spawn as many Bobs as you want without causing much of a lag. (but please. Don't do that. Test the AI. Please. Don't use use the C4 and play around like its a ragdoll engine--)
 * Brain dumps (the thing that you see to know what is going on inside the NPCs brain system) are now batched from the server. Instead of firing for each NPC and each update.
 * "Wait, is it all debug renderers--"
 * NPCs gets invalidated upon their death, leading to clean up logic. Making the poor 2008 servers of Roblox not cry whenever you testers spawn too many Bobs.
 * This also fixed the debug renderer throwing an error whenever an NPC dies cuz they haven't got a registered renderer yet.

###  Published Commit 041 & Experimental Biopsy 040 (20/08/25)
 * Added more random backgrounds when teleporting.
 * So you won't get bored as you will use the testing server often now.

###  Experimental Biopsy 043 - "Da Megapatch" (21/08/25)
 * In case you haven't remembered, there has been some *complications* involving our testing place. It has been replaced with a secondary testing server. This doesn't really affect much.
 * Fixed some minor errors of the player head rotation, which involves complete refactoring. Worth it. No seriously, the code now looks like what should be considered modern art.
 * Fixed low health saturation behaving inconsistently. Which may cause effects such as, but not limited to, retaining the grey and vignette effect after respawn.
 * Moved Error's added props from stable to experimental place.
 * Added new quote of the days.

###  Experimental Biopsy 044 (21/08/25)
 * Add forcefield that expires in 10 seconds. So you don't get oblilerated everytime Jeia senses your existence.
 * This is subject to change.

###  Experimental Biopsy 045 (21/08/25)
 * Jeia's FBB now uses Humanoid:TakeDamage(), now players are ACTUALLY protected by the forcefield.

###  Experimental Biopsy 046 (21/08/25)
 * Fixed funni head rotation.

###  Experimental Biopsy 047 (21/08/25)
 * Fixed Bob escaping the matrix or do the funni whenever Bob Spawner is equipped, and also you cannot use Bob Spawner if you're dead anymore.
 * Added music and texts so you won't get bored during testing.

###  Experimental Biopsy 048 (22/08/25)
 * Changed brain debug renderer, memory texts are now white, so its easier to see.
 * Placed C4s will get removed if the player leaves.

###  Experimental Biopsy 049 (23/08/25)
 * Rework on the BrainDebugRenderer! Now has a propper rendering API and does not render flat on the screen unlike previous implementation, so you dont have to get in weird and akward camera angles to see what the hell is going on inside their brains.
 * Jittering text is expected, its more on how Roblox automatically adjusts the text sizes. Will attempt to fix later.
 * As requested in <_> , the map has been added new stuff, along with a bigger patrolling area, added and restored posts. Check it out.
 * NPCs now has different designated posts! Finally, the designated_posts memory getting into use. Jeia and Bob have their respected posts.

###  Experimental Biopsy 050 (23/08/25)
 * *"Oh God is it another debug renderer update--"*
 * ***Yes.***
 * Added suspicion and detected statuses to the BrainDebugRenderer

###  Experimental Biopsy 052 (24/08/25)
Good morning lads.
 * The architectural refactor for the detection meter has been pushed. Please report any abnormalities in <#1401319093243609189> 
 * This refactor includes:
  * Uses a cleaner meter image. Subject to change.
  * Using the same rendering system as the debug renderers.
  * Due to this, may fix some other bugs involving the detection meter, such as not showing after a secondary detection, getting stuck and not updating. and much more.
  * Batched networking, so instead of multiple NPCs sending multiple remote event fires to clients to update the meter, its 1 event per simulation update.

###  Experimental Biopsy 053 (24/08/25)
 * Added the glow for the detection meter fill.
 * Behavioral changes for Jeia.

(To be completed)