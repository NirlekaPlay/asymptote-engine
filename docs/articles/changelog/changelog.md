All dates are in DD/MM/YY format.

### A001 (12/07/25)
"Testing the absolute insanity ive just created.
Its an AI system test, expect some jiggles and shit.
This only took me a week
which is acceptable
You can yap about the feedback here or general or i dunno.
anyway ima go to sleep."

```md
# Commit a46aaa6 (13/07/25)
## Commit message *feat: testing chasing trespasser mechanic*
## 5 files changed, 244 insertions(+), 81 deletions(-)
 * Uses SimplePath for pathfinding logic
```

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

###  Experimental Biopsy 054 (24/08/25)
 * C4 now correctly uses Humanoid:TakeDamage().
 * FBB for players uses Humanoid:TakeDamage().
 * Bob now cannot be intimidated. Now behaves similarly to Jeia. Because fuck you, Bob was tortured for too long.

###  Experimental Biopsy 055 (24/08/25)
 * Testing the new trespassing system to see if there's any issues.
 * This should fix your trespassing status not retaining when crossing to another zone that gives you the same penalty status.

###  Experimental Biopsy 057 (25/08/25)
 * New trespassing system (cells!) is now live and has been polished.
 * Fix players still getting trespassing status when in disguise in a minor trespassing zone.
 * Fix pathfinding trails not removed after the NPCs death is now fixed. By disabling it entirely.
 * Fix Bob getting stuck in some occassion, and in some specific spots.

###  Stable - Published Commit 044 (24/08/25)
 * New intro screen.

###  Experimental - Biopsy 063 (27/08/25)
Late change log. Cuz it was supposed to be later earlier, but, oh well.
 * Add instant detection. Actions that will lead to instant detection includes:
  * Pulling it your gun within 20 suds from an NPC.
  * Pulling out your C4 within 12.5 studs from an NPC.
  * Having the ARMED status within an NPC's quick detection range.
 * Behavioral changes to fleeing NPCs and I forgot how they changed.
 * Changes to FBB for both Players and NPCs.
  * Player's FBB uses Roblox's new Input Action System. (its shit.)
    * This fixes shift-lock bugs getting you stuck.
  * NPCs will shoot less if you're farther away but the bullets are accurate. The more closer you are, the faster they will shoot, and the more inaccurate the bullets are.
 * Some other shits that my puny little brain cant comprehend.

###  Experimental - Biopsy 064 (28/08/25)
 * Map changes. Cuz I was bored. And I don't want you to be bored also.
 * Thanks to Cish and other devs contributing to the Operators game for sharing the assets!
 * See it for yourselves <:NirlekasPlushCat:1115266331009351740>

###  Experimental - Biopsy 065 (28/08/25)
 * Another update. Have fun. Cuz I wont be updating for a week maybe,

# Experimental - Biopsy 066 - "An Attempt was Made" (01/09/25)
# [Major Update]
## Map Changes
 * I changed the map. Again. You either missed the old map or not.
 * Changed the map to a location no referred to as "The Killhouse" this is the original map on the alpha version.
  * It is made for Players to focus on the game features instead of turning the whole server into a battle royale.
  * Kinda ironic considering this is the combat update.
 * This is also gonna be used for the tutorial level demo.
 * The old map, which should now be reffered to simply as "The Baseplate" (very original I know) will be restored later.
 * Cells and posts data may be fucked up, affecting NPC patrols.
## AI Changes
 * Spent a whole fucking 2 days on this shit. Fixed NPCs not truning around properly.
 * Fix NPCs not turning upon instantly detecting a Player.
## Internal Engine Changes
 * Alert level is technically implemented. But it doesn't actually do anything. The alert level status will now change accordingly. In this current version, the only thing that raises the alert level are trespassing players.
 * Changed how statuses are internally handled. (which both made my life more easier and also heavenly shit at the same time.)
 * Other things that I can't list here because my brain right now is fried. See the GitHub commit history if you want to learn more on how much I've suffered.
 * Added new quote of the days.
## Gun System
 * Created a partial gun framework integrated to the engine. Which for now only consists of handlers.
 * The FBB uses the legacy FBB from Stable.
 * Bullet tracers, shell drops, muzzle flashes, and various other shits are now handled on the client.
  * This creates the bullet simulation much more hecking faster what the hell--
 * Added hit markers.
  * Red hit means you killed your intended target.
  * White means keep shooting.
  * And the hit sound also.
 * Brought back bullet holes and particles.
<@&1115292592184242249> <@&1151567805662121995> <@&1354531318775419031>

###  Experimental - Biopsy 067 (02/09/25)
 * Fix cells having collision and other query stuff.
 * The legacy (now new) FBB now uses the same client script used by the previous FBB.
   * I know this may lead to some incompatibilities, so be sure that everything is fine. (its not.)
 * Added client-sided bullet tracers debug mode.

###  Experimental Hotfix - Biopsy 068 (04/09/25)
 * From the Start by Laufey music is back!
   * Fixed a bug where when you disabled music and die, you are unable to toggle the music back.
   * Caused by the severe retarded design of having to put InputContexts inside StarterGui leading to instances getting reset after death.
   * Of course, added back the credits.
 * Fixed Players being able to acquire 2 Bob Spawners by spamming the proximity prompt.
 * Sync internal engine changes.
   * Changed WalkToRandomPost `Optional<T>` handling. May lead to some inconsistencies in patrol states.
 * Added the Killhouse and props assets in Section 3. For testing and reference stuff.
 * Map optimizations and minor tweaks.

###  Experimental Hotfix - Biopsy 069 (04/09/25)
 * ( ͡° ͜ʖ ͡°)
 * Fixed music not playing.
 * Fixed client-sided bullet tracers not showing upon getting enabled.

###  Experimental - Biopsy 070 (21/09/25)
Last update was 16 days ago, or more? Sigh. Where do we even begin? Begin test phase of the new entity detection system and some other stuff I have done for no reason whatsoever. Enjoy.
 * Architectural changes to NPCs. Doesn't show much, but its hell.
   * Added sensors for a many entities.
   * Replaced SuspicionManagement with DetectionManagement. Added to fit with the new entity detection system. Was a pain. Yes. Was it worth it? I don't know.
 * Detection meter.
   * Completely changed how the angle calculation of detection meters to point to world position. It will *exactly* point towards the world position. You will get used to it, don't worry.
   * The rotation is lerped. This fixes stuttering, and the meter rotating in the other way instead of the closest angle.
 * FB Beryl.
   * FB Beryl for NPCs is now embeded to the engine.
   * Some optimizations for it.
   * Fix client side bullet simulation hitting and leaving bullet holes on things such as player accessories, and weapons.
   * Bullet whizz.
   * NPCs will drop the FB Beryl upon death when they have it equipped. Retaining its ammo and can be picked up by players.
   * NPCs will drop the FB Beryl when they run out of ammo, and panic.
 * NPCs themselves.
   * Ignore **Envvy** and **Andrew.** I accidentally added them during testing and other sorts of tomfoolery, but I'm too lazy to remove them.
     * *(note: if you kill them, they're dead for good.)*
   * Jeia can now patrol. Probably.
### Co-authors:
 * <@587928777422798850> for assisting me on the entity detection system.
 * <@1162771914285129769> for dialogue suggestions and writing.

<@&1115292719317782609>  <@&1354531318775419031> <@&1151567805662121995>

###  Experimental - Biopsy 072 (26/09/25)
 * Fixed Bob spawner not working (<#_>)
 * Some internal engine changes I didn't keep track of.
This version is pretty stable for public showcase
although im still experimenting shit for the map

###  Experimental - Biopsy 073 - "The Commands Update" (27/09/25)
This was created in a day. A DAY. DO YOU KNOW WHAT THAT MEANS-

Good evening everyone! I had fun programming this. Minimal suffering, and I'm proud of it.
 * Commands.
   * Commands exist now!!! FINALLY-
   * It is not yet restricted by permission. Everyone can execute commands by typing them out in the chat. (sounds like a recipe for disaster but eh.
   * And of course its in testing phase.
### Commands:
These are commands I made during testing for making an example of how powerful yet simple this command parser and dispatcher is. It is based on Mojang's Brigadier.

The command prefix is `/` and the syntax is similar to Minecraft Java commands. Entity selectors includes:

`@a` all players
`@p` the first player the iterator finds in the Players list
`@r` random players
`@s` yourself
`@m` all humanoids in the workspace
`@e` all humanoids and players

**Teleport**
The most complicated command of them all.
 * Syntax:
  * `/teleport <x> <y> <z>`  Teleports yourself to the destination
  * `/teleport <victim> <target>` Teleports one `victim` to `target`
  * `/teleport <target>` Teleports yourself to `target`
 * Examples:
  * `/teleport mrfox`
  * `/teleport @s mrfox`

**Kill**
Kills another player or entity.
 * Syntax:
  * `/kill <victim>`
 * Examples:
  * `/kill @s` Kills yourself
  * `/kill @e` Kills everyone and NPCs.

**Highlight**
Highlights an entity with red as the fill color and white as the outline color.
 * Syntax:
  * `/highlight <victim> < true | false > Highlights / removes highlights of the victim.
 * Examples:
  * `/highlight @e true` Highlights all players and NPCs

**Give**
Gives a target an item.
 * Syntax:
   * `/give <target> <item_name> <item_data?>` Supports JSON attributes!
 * Examples:
   * `/give @s fbb {"mags":inf,"magCapacity":30}`
   * `/give @s c4`

<@&1115292719317782609>  <@&1354531318775419031> <@&1151567805662121995>

###  Experimental - Biopsy 074 (27/09/25)
 * Added attribute support for C4.
   * `radius` the blast radius;
   * `blastPressure` Roblox Explosion's BlastPressure property;
   * `plantRange` How far can you plant the C4;
   * `maxAmount` the maximum amount of C4 you can have; and
   * `amount` the amount of C4 you currently have.
 * Added the `/summon` command.
   * Syntax: `/summon <entity_name>`
   * Valid entity names includes: `bob`, `jeia`, `envvy`, `andrew`

### Experimental - Biopsy 075 (28/09/25)
This is a simple update, an appetizer for the next update.
 * Added the `/forcefield` command.
  * `/forcefield push <target>` Adds a forcefield to `target`.
  * `/forcefield push <target> <ttl>` Adds a forcefield to `target` that automatically expires after `ttl` seconds. Previously added forcefields are also affected.
  * `/forcefield pop <target>` Removes the forcefield from `target`.

###  Experimental - Biopsy 076 (28/09/25)
Im too burned out. I wont be fully implementing the output pipeline, but here it is.
 * Default Roblox chats commands has been disabled.
 * Introducing command redirects. A command can execute another node. Acting as aliases.
 * `/?` command.
   * Aliases are: `/help`.
   * `/?` Shows you the full list of commands and their arguments. Descriptions not yet supported.
   * `/? <command>` shows you all possible usage of that specific command.
 * Added `/tp` as an alias for `/teleport`
 * Added Vec3 argument similar to Minecraft.
   * Relative syntax `~` e.g. `~ ~50 ~` is 50 studs up relative to your position.
   * And of course the normal XYZ numbers. e.g. `23 4 10`

###  Experimental - Biopsy 077 (28/09/25)
 * Added the `/restartserver` command. 
-# (Not yet restricted by permission so PLEASE DO NOT ABUSE THIS-)

###  Experimental - Biopsy 078 (28/09/25)
This was a rush. Cuz its almost midnight and I need to take a shower. But here it is. Again!
 * Some refactors on the command system.
 * Some bug fixes.
 * Convinience updates:
   * Remove and simplify the verbose commands for `/kill` `/highlight` `/forcefield` for user convinience.
   * `/spawn` is now an alias for `/summon`
 * Added entity selectors and parameters!
 * Add `/destroy` command.
# Entity selectors
Minecraft-style entity selector parser and resolver for Roblox.
If the input does not start with a selector (e.g. @a) then the parser
will resolve by treating it as a player name and search with case-insensitive
partial matching for each players' name and display name.

## Supported Selectors
    * `@a`  - All players
    * `@p`  - Nearest player (excluding source)
    * `@s`  - Self (source player)
    * `@r`  - Random player
    * `@e`  - All entities (players + NPCs with Humanoids)
    * `@m`  - All NPCs (entities with Humanoids, excluding players)

## Parameter Syntax

`@selector[param=value,param2=value2]`

Example: `@e[type=!player,distance=..50,limit=3]`

    * `distance=X`     - Exact distance
    * `distance=..X`   - Less than or equal to X
    * `distance=X..`   - Greater than or equal to X  
    * `distance=X..Y`  - Between X and Y (inclusive)

    * `name=PlayerName`    - Entity with exact name
    * `name=!PlayerName`   - Entity NOT with this name
    * `name="Name Here"`   - Quoted names with spaces

    * `type=player`    - Players only
    * `type=npc`       - NPCs/mobs only  
    * `type=!player`   - Exclude players

    * `team=TeamName`  - Players on specific team
    * `team=!TeamName` - Players NOT on this team

    * `alive=true`     - Alive entities
    * `alive=false`    - Dead entities  

    * `limit=N`        - Maximum number of results

## Negation Syntax

Use `=!` (not `!=`) - this follows Minecraft's convention.<p>
Examples: `type=!player, name=!Noob123, team=!Red`

## Example commands

    * `/kill @e[type=!player,distance=..50]`        - Kill all non-players within 50 units
    * `/tp @p[team=Blue] @s`                        - Teleport nearest Blue team player to self
    * `/give @a[level=10..,limit=5] sword`          - Give sword to first 5 players with level 10+

*NOTE: Distance calculations require HumanoidRootPart or PrimaryPart*

### Experimental - Biopsy 079 (29/09/25)
 * F3X is now added to `/give` command.
 * Fixed `@m` entity selector not working.

### Experimental - Biopsy 080 (04/10/25)
This update mainly consists of internal refactors, sit comfy while we wait for the map to be finished.
 * Updated the `/teleport` command.
   * `Vector3ArgumentType` is added and properly implemented, allowing for a more flexible command syntax tree.
     * `/teleport <location>`
     * `/teleport <destination>`
     * `/teleport <targets> <location>`
     * `/teleport <targets> <destination>`
 * Added the `/quote` command. Made in accordance to <(forum thread suggestion by MrFox)>
   * `/quote list` Lists all the quotes and their respected index.
   * `/quote predict` Gives you the next quote after the current date.
   * `/quote schedule` Gives you the entire list of all quotes that will be shown on their respected date.
 * The "Early Tester" badge is now implemented and should be awarded to players who joined the testing server.
 * `/destroy` command now cannot be used on players.
 * And many others.

### Experimental - Biopsy 081 (04/10/25)
 * Fixed `/give` command not working.
   * Added `ItemArgument` for item arguments with JSON objects.

### Experimental - Biopsy 083 (04/10/25)
 * Added the `/cell` command. You're gonna need this when we're gonna test the map.
 * Remove the input icons for now. I'm gonna make a better one.

### Experimental - Biopsy 084 (04/10/25)
 * Fixed a macOS problem: pressing either Shift or Left Shift while scrolling will result in the camera to not zoom in or out like normal but rather rotates left to right.
 * <_> related

### Experimental - Biopsy 085 (04/10/25)
 * Added Sided to the game cuz why the fuck not at this point.

### Experimental - Biopsy 087 (10/10/25)
A ***fuckton*** of internal refactors and features to keep shit going. This was supposed to be a mission update, for the dialogues and shit, but then I realised "why not just apply this to the command system?"
 * Commands now have propper feedback! It still uses the Roblox chat UI, but internal changes fixes some bugs.
 * Rich text marking. And no, I am not a masochist and put the colors, bold, italic, etc manually, I made an entire new class to do it for me. Also its for the sake of your eyes.
  * This will soon be used in mission dialogues and other stuff.
 * Spelling correction suggestions on some commands. (e.g. *"Did you mean (...)?"*)
 * I forgot the others... See the github commits as theres 44 of them..

### Experimental - Biopsy 088 (11/10/25)
 * Parsing refactors. (kill me.)
 * Some other stuff I cant remember.

### Experimental - Biopsy 089 (15/10/25)
Some small changes. Nothing more. I was doing this as a sidequest as I was bored with my homework.
 * `/help` command now uses the *smart usage* generation. It will display commands in their *"smart"* form, instead of using all usages from the tree.
   * Using `/help <command>` will extend that usage tree even more.

## Experimental - Biopsy 090 - "Hollow Nights" (19/10/25)

*"Jeia… I don’t know who else to tell. Something's wrong. Ever since… that day with the equipment vendor, I feel it behind me. Always. Not like a shadow or a shape, like it's pressing into me. I can't look away, well, I do look away, but the second I blink, it's there. I swear I can hear his breathing in the silence.. we need to tell the trainers, I- (...) what was that? Is that the guy? Oh- HELP-"*
**~ Bob, Plasma Security Division, Tier-1, sudden termination of his call log**

Good afternoon everyone. It's that time of the year again so might as well do this.
We've been getting trouble contacting Bob, so he's not here for now.
 * Map changes
   * Small prop clutterings and spooky elements.
   * Changed lighting.
 * Commands
   * Added the `/lighting` command.
 * Reimplemented trespassing responses.
 * Various other things that won't be documented in this changelog for a surprise.

<@&1115292719317782609> <@&1151567805662121995> <@&1354531318775419031>

(Developer's commentary: This is where the Dean Haunt feature was added. Dean will appear behind you at rare times, playing a horror ambience and heartbeat, and disppaears when you turn around try to look at them.)

### Experimental - Biopsy 096 (27/10/25)
 * Previous untracked changes
 * NPCs animations are back with sprinting animation!

### Experimental - Biopsy 097 (27/10/25)
 * Some internal engine changes.
 * Fixed broken pathfinding for patrols.
 * Added a guarding animation when a guard is at their post!

## Experimental - Biopsy 099 - "9 More Shits to Go" (01/11/25)
-# *HOLY SHIT WE'RE REACHING 3 DIGITS-*
I'm releasing this early because honestly I'm drowned, and I don't want you to lose patience or anticipation. And yes it is quite the big update.
 * Internal engine changes.
 * Introducing **Marso.** The recogniseable orange security guy.
 * NPCs now have lip syncing when talking!
    * They can now properly report and the alert level now has a purpose.
 * Guards now have functioning radios!
 * Animations:
   * Guard animations when they're at their post.
   * Running animation.
   * Walking animation.
   * Radio animation.
 * Fully developed responses to most events and statuses:
   * Armed players
   * Placed C4s
   * Players with C4s
   * Players trespassing in both minor and major trespassing zones.
   * Disguised players.
     * Alert level affects how different NPCs can see through different disguises.
 * NPCs will retreat to their combat spots upon lockdown.
 * NPCs have a newly refined logic to choose escape points when trying to flee.
 * And many more!

<@&1115292719317782609> <@&1151567805662121995> <@&1354531318775419031>

### Experimental - Biopsy 100 - "Disappointment, but still satisfied" (02/11/25)
-# *wait no i thought B100 is gonna be the most epic update ever-*
Again, I'm releasing this early cuz tommorow's Monday. Also a lot of bug fixes that I cant even track of.
 * Fixed some bugs where NPCs stutter when trying to confront trespassers.
 * Fully implemented support for detecting and reporting suspicious players.
 * Implementations on how behaviors retrieves detected entities are changed. This should fix some bugs and unnatural stuff.
 * Fix NPC's vision raycast seeing through some props as a side effect to the new vision logic of passing through transparent objects. This is caused by transparent and non transparent parts overlapping with eachother.
 * Fix a long standing bug of agents turning in a weird way when equipping their guns.
 * Made the agents not jump. Cuz weird Roblox shit when you put C4 explosives on specific parts of their body causing them to jump.
 * Fix agents turning in circles when a C4 is placed on their bodies. Agents will only turn their body if the target entity is far enough. Otherwise, just look with their head.

<@&1115292719317782609> <@&1151567805662121995> <@&1354531318775419031>

### Experimental - Biopsy 101 (08/11/25)
-# *where da big update-*
-# Later.
 * Internal engine changes.
 * Fixed some bugs.
 * Trespassing responses:
    * The usual 3 warnings.
    * Dialogues for repeated encounters.
 * Refactored AGAIN on how NPCs retrieve the current prioritized entities.
    * There shall be no race condition bullshit ever again!

<@&1115292719317782609> <@&1151567805662121995> <@&1354531318775419031>

## Experimental - Biopsy 102 - "Doors and Interaction" (15/11/25)
 * Internal engine changes.
 * Proximity prompts:
   * The appearance of proximity prompts have been changed.
   * Omni direction (those that aren't flat) does not use a BillboardGui but instead a flat proximity prompt using SurfaceGui that faces the camera. This makes the prompt not look weird and change size depending on your camera distance.
   * Some stuff that makes them smoother and more robust against interruptions.
 * Doors.
   * ***DOOOOOOOORS-***
   * After 3 months, we have *Doors.*
   * There's only one door that you can test, on later updates, we will add stuff like locking, unlocking, lockpicking, and electronic doors that uses keycard scanners. For now, just stress test the shit out of it.

<@&1115292719317782609> <@&1151567805662121995> <@&1354531318775419031>

### Experimental - Biopsy 103 - "Doors and Interaction" (15/11/25)
Another test update for the doors
 * Internal engine changes.
 * Doors:
    * Added electronically locked door for the armoury, utilising a keycard scanner.
    * A keycard can be found on one of the tables.
 * AI Behaviours:
    * Added `ReportSuspiciousPlayer` behavior, as interacting with the keycard scanner gives you the minor suspicious status.

### Experimental - Biopsy 104 - "Doors and Interaction" (16/11/25)
Evening. Is it evening? I think it is.
I am testing double doors now, and some internal changes on doors.
 * Internal engine changes.
 * Map changes.
 * Proximity prompt visual changes.
 * Added double doors.

### Experimental - Biopsy 105 - Interactions (22/11/25)
This update has changed a lot stuff on the interaction system. We are no longer using Roblox's native proximity prompt shown/hidden logic, and we are manually calculating the conditions for full control.

And also an attempt to fix other stuff we [planned.](https://nirlekaplay.github.io/asymptote-engine/planning/proximity-prompts/)
 * Internal engine changes.
 * Map changes. (restored the invisible barriers, and other stuff.)
 * Proximity prompts. Now called Interaction prompts:
     * Fix interaction prompts appearing through doors.
     * Manual, per-frame distance calculation, obsturction, on-screen, etc, replacing native functions.
     * Conditional interaction prompts! Right now, it's only implemented to the disguise trigger. If you're already disguised, there will be a message showing you're already disguised, and you cannot interact with the prompt.

Expect performance changes, either negative or positive. If you experience lag, memory spikes, please inform me in <#1401319093243609189> , and provide the necessary information in F9 menu. (recommend go to Memory -> LuauHeap)

<@&1354531318775419031> <@&1151567805662121995>

### Experimental - Biopsy 106 - ***"IT'S ALL A SIMULATION-"*** (23/11/25)
*Let's see how robust the engine is.*
 * Internal engine changes.
 * Interaction prompts:
    * Created conditional prompts for both FB Beryl loot and ammo box.
 * New command: `/restartlevel`
    * Yes. An actual way to restart a level without restarting the server.
    * I need everyone, ***everyone***, to stress test the shit out of this and see how well can my state of the art piece of code (*it's still shit*) can handle it.
 * Keycard spawning is now randomized.

<@&1354531318775419031> <@&1151567805662121995>

### Experimental - Biopsy 107 (24/11/25)
 * Added `PersistentInstanceManager`. This allows certain instances to be cleared upon level restart:
    * FB Beryls.
    * Dead bodies.
    * Dropped radios.
 * Keycards are not cleared upon level restart as they're not fully implemented inside the engine yet.
 * Faze's C4 will not be implemented to the actual engine until further notice.

## Experimental - Biopsy 109 (and counting) - "We're comin' for you Dean..." (30/11/25)
**If you don't wanna get spoiled, don't read this message and instead wait for it to be fully released :)**

I don't wanna spoil but... Here it is. I am just testing some major reconstruction here. This is just the *BARE MINIMUM* and some things might change.

I've been publishing this since Saturday. And nobody noticed somehow... <:NirlekasPlushCat:1115266331009351740> 

 * ||Internal engine changes.||
 * ||A ***FUCKTON*** of internal engine changes.||
 * ||For the Killhouse map changes:||
    * ||Add 2 laptops that give you options to join the Dean Assasination map.||
 * ||Dean assasination map! Not fully developed yet. Just the barebones.||
 * ||Objective system tests!||
 * ||And many more internal stuff I forgot to list cuz there's so much insiginifficant to the player yet signifficant to development.||
 * ||The engine doesn't have a restart screen yet. To restart the map once you finished it or fucked it up, run the `/restartlevel` command.||

## Experimental - Biopsy 110 - Dean Assasination Map (02/12/25)
 * Fix engine version UI.
 * Map changes that extend trespassing zones.
 * Add a mission end zone similar to Entry Point and Operators for when you complete the mission.
 * **Added a mission conclusion screen for testing.**
    * This allows you to restart the mission, and also:
    * Return back to lobby.

<#1408152868481007708> <#1401319093243609189>

## Experimental - Biopsy 111 - Dean Assasination Map (03/12/25)
 * Internal engine changes.
 * Add transitions between mission conclusions.
 * Add blur to mission conclusion screen.
 * **Mission can fail if all Players are invalid. (Dead, no character, etc.)**

### Experimental - Biopsy 112 (03/12/25)
 * Published to both Killhouse and Dean Assasination map.
 * Attempt to fix localization race condition issues.
 * Added back a more polsihed and ***pristine*** input keys UI.
 * Fix "Back to lobby" teleporting to the old testing server.

### Experimental - Biopsy 115 (05/12/25)
I spent a lot of time working and debugging this. Someone better playtest it. 
Especially multiplayer. Published to both testing server and the Dean assasination map.
 * Mission conclusion screen:
     * More polished.
     * Now handles players joining while the mission hasn't been restarted yet.
     * Shows a subtitle whenever theres more than one players required to replay the mission.
     * Fix streaming issues caused by Roblox's default streaming behavior, causing players to see an endless void when they join and the mission hasn't started yet.
 * Slightly lower the darkness intensity of the health saturation effect.
 * Fix players having collision in the Dean Assasinaton map.
 * Fix an issue where players will linger after dying and another player left. Leaving to softlock.
 * Teleportation:
    * Teleports are faster now. To keep you sane.
    * Failed teleports will automatically cancel it and the teleport screen wont stick for eternity and instead fades out.
 * Minor bugs:
    * Fixed style: fix `TRESPASSERS_ENCOUNTERS` memory incorrectly named with `trespassers_warns` in the debug renderer.
   * Fix players' viewmodel causing proximity prompts to not appear due to obstruction.
         * Minor performance gain.
   * Disable automatic translation for the engine version text.

## Experimental - Biopsy 119 - "Quality of Nine Lives" (09/12/25)
This update and the following updates will focus more on bug fixing and Quality of Life features. Which is to make the game more playable and appropriate enough for public release.
 * Small changes to the Dean Assassination map:
    * Fix a cell gap for the upper floors trespassing area.
    * Add Plasma Security Division group photos, and the unhanged 2024 group photo.
    * Add a small barrier in the upper floor for hiding.
 * Objectives tagging.
    * Objectives now have tags. Icons that points towards objects and areas essential to complete the objective. With different icons and colors, and also it sticks to the edge of your screen if it goes off-view.
 * Bubble chats.
     * Finally removed Roblox's shitty bubble chat rendering issues for NPCs.
     * Replaced with a custom bubble chat system.
     * It now has typing animation which syncs with the NPCs' lip-sync.
     * Just like the objectives tags, it sticks to the edge of your screen if it goes off-view. This is important for cases like you're doing your evil deeds, completely oblivious to the NPC behind you, as they run and make their radio call you don't even know until the alarm is raised.
 * Add spectating.
    * You can now spectate players when you're dead.
 * Fix input problems with the FB Beryl not firing or accepting input after restarting the level.
 * And other very small and subtle issues that you likely wouldn't notice, but still important for the sheer ***vibes.***

Make sure to report bugs issue a suggestion in <#1401319093243609189>  and <#1408152868481007708> 

Thank you.

<@&1151567805662121995> <@&1354531318775419031>

### Experimental - Biopsy 120 (10/12/25)
 * Fix the wooden doors having fucked up orientation.
 * Doors now uses client-sided tween. This makes them have smoother animations when opening and closing, and also increases a slight performance.

### Experimental - Biopsy 121 (11/12/25)
 * Fix some very legacy shit on the detection system. Now it correctly applies the speed multiplier.
 * Fix the detection system inconsistently not instantly detecting under similar circumstances.
 * Add a help menu. Yes. Help menu. After all of these dev'ing, we finally have it. And no, it aint finished. The contents that is. Someone else will probably write them.
 * Add sprinting. Ladies and gentlemen, we've done it. SPRINTING. Its client sided. So I dunno. And also the animation is shit, ill fix it up later.

### Experimental - Biopsy 123 (17/12/25)
 * This update is only available in the lobby at the moment.
 * Bubble chat now waits for the typing animation to finish before counting down its *time to live*. This prevents bubble chats from being hidden too early when the animation is playing.
 * Small changes to the help menu's contents.
 * Players can now send bubble chats through the normal Roblox chat window that will be shown to other receivers.
    * This is temporary for testing purposes. ||***Or is it?***||
    * This is mutual. Only **Testers**, **Developers**, and the **Director** can mutually use the bubble chat.
    * This is the same bubble chat used for NPCs.

## Experimental — Biopsy 124 — "XMas Update" — Part 1 / 2 (25/12/25)
-# *Holy shit there's parts to this update what the fu-*
It's that time of the year lads. Christmas. That's right.
This update is, guess what, experimental! I am testing the new sound detection system. And yes, this update is split to 2 parts cuz there's so much technical debt to this update I can't even comprehend what's going on half the time.
 * This update is only published in the lobby.
 * Sound detection system for all NPCs.
 * That means the only gun in the game, and the only goddamn weapon to kill people, the FB Beryl, can be heard from kilometers away by NPCs. I will add a suppressed gun later.
 * New command: `/packet` controls what packets you receive. Only used for sound pathfinding debug packets.
      * Syntax: `/packet <packetName> <boolean>`
      * `/packet recent_path true` to enable the recently computed path debug renderer.
 * Map updates!
 * Add the Sledge Queen from Decaying Winter cuz why the fuck not at this point.
 * Updates concerning objectives, which won't matter much now.

### Experimental — Biopsy 125 (26/12/25)
 * Fix jittery collisions with the snow piles.
 * Refined and updated the contents of the help menu.
 * Detection:
    * New sound when getting detected.
    * Sound will only play if the focus is a player. Anything else is silent.

### Demo — Apoptosis 128 (26/12/25)
 * Internal engine changes.
 * Add objectives when you raised the alarm.
 * Experimented with the FB Beryl new shoot sound.

(To be completed)