# Level system
To create a level system that is hopefully expandable, maintainable, and of course simple while holding several complex systems.

## What We Have
Before anything turns into an active, living level we must start on what we see in the Studio:

A Map have atleast this structrure:
- Cells. A flat folder with Models. Each model represents a Cell. Each cell has ATLEAST 1 Roof and 1 Floor. Anything BETWEEN the Roof and the Floor is inside the Cell. Each cell can have an attribute named "Location" and filled with a localized string. For example a Cell's Location attribute is set to "cell.office.lower" which in English will be "lower office". This is only used for character dialogues. A model's name is what's used to set their behavior defined in MissionSetup.
- Geometry. The actual meat and flesh of the folder. It's just that, doesn't really do much.
- Nodes. Should realistically be called Posts. But oh well. It is a tree of Folders which contains Parts that represents a post when a guard wants to patrol around. It can be nested. For example a folder named "Office" can have folders named "LowerOffice" and "UpperOffice" which has their own children of posts and sub-folders. If an NPC's set Nodes is "Office" then his patrol scope would be all nodes descending from Office.
- Props. The soul. Each Prop is really represented by a Part with attributes and its name stating what Prop a part's is supposed to represent. Some Props are just models, some are functionable, and some are functionable but don't really need a specific model.
- StateComponents. Basically the flavorings. Represented by BoolValues with attributes setting a component's behavior. For example:
"MusicController" control's the current playing music.
Attributes:
ActivePriority (String: Expression): "Mission_AlarmRaised ? 2 : 0"
TrackId (Number: AssetId): 1842802436
Volume (Number): 0.5
StateComponents should have the most access to the level as components cover and configure so many things. For example MissionEndTrigger ends the mission immediately if specific conditions are met.
- MissionSetup. Without this everything is pretty much meaningless. Here's a sample:

```lua
return {
	LightingSettings = "DENNIS",
	StarterPack = {
		"SuppressedFBBeryl"
	},
	CustomStrings = {
		["cell.lower_offices"] = "the lower offices",
		["cell.upper_offices"] = "the upper offices",
		["cell.lower_stairs"] = "the lower stairs",
		["cell.cafeteria"] = "the cafeteria",
		["cell.locker_room"] = "the locker room",
		["cell.server_room"] = "the server room",
		["name.disguise.security"] = "Security",
		["name.disguise.executive"] = "Executive",
		["texts.stairs_here"] = "Stairs here idk",
		["objective.find_upstairs"] = "Find a way upstairs.",
		["objective.well_shit"] = "Well shit. Run.",
		["objective.loud"] = "Systems are locked down. Find the security room and lift the lockdown.",
		["objective.get_to_penthouse"] = "Get up to the penthouse.",
		["objective.eliminate_target"] = "Eliminate the target.",
		["objective.stealth.keycard"] = "Get a Keycard.",
		["objective.stealth.keycard.open"] = "Open the door.",
		["objective.stealth.second_elev"] = "Find a way to get to the elevator.",
		["objective.stealth.go_to_third_elev"] = "Go to the 6th floor.",
		["text.server_room"] = "Server Room",
		["objective.stealth.hack_elev"] = "Find the server room to hack the elevator.",
		["objective.loud.hack_elev"] = "Find the server room and hack the elevator systems.",
		["object.seinfield"] = "Seinfield",
		["action.watch"] = "Watch"
	},
	Cells = {
		LowerOffice = {
			Trespass = true,
			MinorTrespass = {
				None = true
			},
			Allow = {
				Security = true,
				Executive = true
			},
			EnforceMinor = {
				NotVeryGoodAtJob = true,
				SomewhatGoodAtJob = true
			}
		},
		UpperOffices = {
			Trespass = true,
			Allow = {
				Security = true
			},
			Enforce = {
				NotVeryGoodAtJob = true,
				SomewhatGoodAtJob = true
			}
		},
		ServerRoom = {
			Trespass = true,
			MinorTrespass = {
				Security = true
			},
			Enforce = {
				Jeia = true
			},
			EnforceMinor = {
				Jeia = true
			}
		},
		Penthouse = {
			Trespass = true,
			Enforce = {
				NotVeryGoodAtJob = true,
				SomewhatGoodAtJob = true,
				Dean = true
			},
			Allow = {
				Security = true,
				Executive = true
			}
		}
	},
	Globals = {
		SystemLockdown = "Mission_AlarmRaised",
		ElevatorShaftHacked = "false",
		PlayersInLockerRoom = "0",
		PlayersInLowerStairs = "0",
		PlayersInPenthouse = "0",
		PlayersNearSecondElev = "0",
		PlayersInSecondElev = "0",
		PlayersInDeanRoom = "0",
		PlayersInBathroom = "0",
		ReceptionAreaDoorOpened = "ReceptionAreaUnlock ? true : ReceptionAreaDoorOpened",
		DeanDead = "AssTargetDeathCounter >= 1",
		MissionComplete = "DeanDead",
		PlayersWatchedTV = "false"
	},
	CustomDisguises = {
		Security = {
			Name = "name.disguise.security",
			Outfits = {
				{ 4893814518, 4893808612 },
			},
		},
		Executive = {
			Name = "name.disguise.executive", 
			Outfits = {
				{ 10268730314, 730003802 },
			},
			DisguiseClass = 1
		},
	},
	Colors = {
		DarkBlue = Color3.fromRGB(55, 114, 165),
		Metal = Color3.fromRGB(122, 122, 122),
		Metal0 = Color3.fromRGB(91, 93, 105), -- Blueish
		Metal1 = Color3.fromRGB(152, 155, 175),
		Metal2 = Color3.fromRGB(49, 51, 57),
		Metal3 = Color3.fromRGB(159, 163, 173), -- Lobby/Exterior
		Metal4 = Color3.fromRGB(77, 79, 84),
		Blue0 = Color3.fromRGB(42, 63, 102),
		Wood0 = Color3.fromRGB(156, 150, 155),
		Wood1 = Color3.fromRGB(124, 119, 123),
	},
	EnforceClass = {
		None = {},
		["NotVeryGoodAtJob"] = {
			Security = 1 
		},
		["Jeia"] = {
			Jeia = 3,
			Security = 3
		},
		["SomewhatGoodAtJob"] = {
			Security = 2,
			Jeia = 2
		},
		["Dean"] = {
			Executive = 3
		}
	},
	Objectives = {
		Mission = {
			{
				Active = "DeanDead",
				Text = "ui.objectives.body.exfiltrate",
				Tag = "'ExfiltrateTag'"
			},
			{
				Active = "PlayersInLowerStairs < 1", 
				Text = "objective.find_upstairs",
				Tag = "'LowerStairTag'"
			},
			{
				Active = "PlayersInLowerStairs >= 1 && PlayersInPenthouse <= 0", 
				Text = "objective.get_to_penthouse",
				Tag = "",
			},
			{
				Active = "PlayersInPenthouse > 0",
				Text = "objective.eliminate_target",
				Tag = "'AssTarget'"
			},
		},
		Stealth = {
			{
				Active = "!Mission_AlarmRaised",
				SubState = {
					{	
						Active = "!ReceptionAreaKeycardPicked",
						Text = "objective.stealth.keycard",
						Tag = "'ReceptionAreaKeycard'"
					},
					{	
						Active = "ReceptionAreaKeycardPicked == true && !ReceptionAreaDoorOpened",
						Text = "objective.stealth.keycard.open",
						Tag = "'ReceptionAreaUnlock'"
					},
					{	
						Active = "PlayersNearSecondElev > 0 && !(PlayersInSecondElev > 0)",
						Text = "objective.stealth.second_elev",
						Tag = "'SecondElevTag'"
					},
					{	
						Active = "PlayersInSecondElev > 0 && PlayersInPenthouse <= 0 && !ElevatorShaftHacked",
						Text = "objective.stealth.hack_elev",
						Tag = "'ThirdElevButton'"
					},
					{	
						Active = "PlayersInSecondElev > 0 && PlayersInPenthouse <= 0 && ElevatorShaftHacked",
						Text = "objective.stealth.go_to_third_elev",
						Tag = "'ThirdElevButton'"
					},
				},
			},
		},
		Loud = {
			{
				Active = "Mission_AlarmRaised",
				SubState = {
					{
						Active = "Mission_AlarmRaised && !DeanDead && !ElevatorShaftHacked && SystemLockdown",
						Text = "objective.loud",
						Tag = ""
					},
					{
						Active = "!SystemLockdown && !ElevatorShaftHacked",
						Text = "objective.loud.hack_elev",
						Tag = ""
					}
				}
			}
		},
	},
	Dialogues = {
		Speakers = {
			Alice = {
				TextColor = Color3.new(0, 0.441611, 1)
			},
			Operator = {
				TextColor = Color3.new(1, 1, 1)
			}
		},
		Concepts = {
			["DIA_MISSION_ENTER"] = {
				{
					id = "mission_enter_intro",
					condition = "true",
					dialogueSequence = {
						{
							SpeakerId = "Alice",
							Dialogues = {
								{
									Text = "Well, this is as far as you can take with the elevator."
								},
								{
									Text = "Our favorite equipment vendor is at the top floor."
								},
								{
									Text = "There are multiple guards between you and him."
								},
								{
									InitialDelay = 1.2,
									Text = "The guards are not much different from you."
								},
								{
									InitialDelay = 2,
									Text = "Good luck."
								}
							}
						}
					},
					priority = 1
				}
			}
		}
	}
}
```

Currently this is already implemented but the systems are so interwined with eachother its basically a migraine to look at.

```
.
├── entity
│   ├── ragdoll
│   │   └── BodyDraggingService.lua
│   ├── registry
│   │   └── EntityType.lua
│   ├── Entity.lua
│   └── TakedownService.lua
├── level
│   ├── cell
│   │   ├── Cell.lua
│   │   ├── CellConfig.lua
│   │   └── CellManager.lua
│   ├── clutter
│   │   ├── props
│   │   │   ├── triggers
│   │   │   │   ├── interaction
│   │   │   │   │   └── FreeTrigger.lua
│   │   │   │   └── TriggerZone.lua
│   │   │   ├── AmmoBox.lua
│   │   │   ├── CardReader.lua
│   │   │   ├── Door.lua
│   │   │   ├── DoorCreator.lua
│   │   │   ├── DoorHingeComponent.lua
│   │   │   ├── DoorPromptComponent.lua
│   │   │   ├── Elevator.lua
│   │   │   ├── ElevatorCallButton.lua
│   │   │   ├── ElevatorShaftManager.lua
│   │   │   ├── ItemSpawn.lua
│   │   │   ├── MissionEndZone.lua
│   │   │   ├── Prop.lua
│   │   │   └── SoundSource.lua
│   │   ├── util
│   │   │   └── RecolorPlaceholders.lua
│   │   ├── .DS_Store
│   │   └── Clutter.lua
│   ├── components
│   │   ├── registry
│   │   │   ├── StateComponent.lua
│   │   │   ├── StateComponentFactory.lua
│   │   │   └── StateComponentRegistry.lua
│   │   ├── DialogueConceptTrigger.lua
│   │   ├── ElevatorShaftController.lua
│   │   ├── MusicController.lua
│   │   └── NpcStateTracker.lua
│   ├── entity
│   │   ├── EntityInLevelCallback.lua
│   │   ├── EntitySectionManager.lua
│   │   ├── EntityTickList.lua
│   │   └── LevelCallback.lua
│   ├── mission
│   │   ├── reading
│   │   │   ├── readers
│   │   │   │   └── MissionSetupReaderV1.lua
│   │   │   ├── MissionSetup.lua
│   │   │   └── MissionSetupReader.lua
│   │   ├── Mission.lua
│   │   ├── MissionManager.lua
│   │   └── MissionManagerInterface.lua
│   ├── navmesh
│   │   └── NavMesh.lua
│   ├── objectives
│   │   ├── ObjectiveManager.lua
│   │   └── ParsedObjective.lua
│   ├── pathfinding
│   │   ├── NodeEvaluator.lua
│   │   ├── NodePath.lua
│   │   └── Pathfinder.lua
│   ├── props
│   │   ├── registry
│   │   │   ├── handlers
│   │   │   │   └── DisguisePropsHandler.lua
│   │   │   ├── PropHandler.lua
│   │   │   ├── PropHandlerBuilder.lua
│   │   │   └── PropRegistry.lua
│   │   ├── DummyProp.lua
│   │   ├── Prop.lua
│   │   └── Props.lua
│   ├── scene
│   │   ├── props
│   │   │   ├── Clutter.lua
│   │   │   └── PropManager.lua
│   │   ├── Scene.lua
│   │   └── SceneManager.lua
│   ├── sound
│   │   ├── DetectableSound.lua
│   │   ├── SoundDispatcher.lua
│   │   └── SoundListener.lua
│   ├── states
│   │   └── GlobalStatesHolder.lua
│   ├── voxel
│   │   ├── Heap.lua
│   │   └── VoxelWorld.lua
│   ├── .DS_Store
│   ├── Level.lua
│   ├── LevelInstancesAccessor.lua
│   ├── LevelLoader.lua
│   ├── NewLevel.lua
│   ├── PersistentInstanceManager.lua
│   └── ServerLevel.lua
└── lighting
	├── configs
	│   ├── DaytimeLightingConfig.json
	│   ├── DennisLightingConfig.json
	│   ├── SpookyLightingConfig.json
	│   └── WinterLightingConfig.json
	├── LightingNames.lua
	└── LightingSetter.lua

```

## What I'm Thinking and Its Problems
Everything seems simple, they within their responsibilities, but they all collapse as soon as they need something:

CellManager:
Responsibility: Know which player is in a specific cell, and as configured in MissionSetup, give them a PlayerStatus of MINOR_TRESPASSING or MAJOR_TRESPASSING based on their disguise.

Requires:
- PlayerStatusTypes. The statuses enum.
- PlayerStatusRegistry. Holds PlayerStatusHolder for each player.
- CellConfig. Interface of a config for a cell, parsed result from MissionSetup.
- Cell. Simple interface for a single cell.

Entity management:
These systems also needs a callback or signal so they know if an entity has moved and needs to be removed.

EntitySectionManager. A spatial hash grid. For querying entities from the world.
Requires:
- Entity. Interface.
EntityTickList. A simple class that A CLASS would need in order to properly tick every entities and avoid ticking entities that got added mid ticking proccess.
Requires:
- Entity. Interface.
- LinkedHashMap.

Prop system:
- Prop. A simple interface.
- PropHandler. A simple interface where a registered prop would handle the placeholders.
- PropRegistry. Holds all of the registered props.
- PropManager. Responsible for updating these props and also propper destroying and restarting if the level got restarted.

Scenes.
Here's what I've been thingking. Maybe we should make a Scene class that holds all the important shit.

Scene class must hold:
- CellManager.
- Entity management???
- PropManager.
- StateMap.
- StateComponentsManager.

## What Does Each System Actually Needs???

Entities:
Some entities like Guards obivously need to know what the hell they're detecting. So they need:
- Some fields in MissionSetup that govern their behavior.
- A way to retrieve entities.
- A way to know what cell they're in.
- Know the current alert level so they know which disguised players they will detect.
- Of course the nav meshesh, the posts and shit.
- Listen to the SoundDispatcher to know if they hear a sound.
- Idk register specific runtime world instances so when the level restarts they get properly cleaned up.
- Props. All Npcs' InteractWithDoor behavior needs to know if they're walking THROUGH a door so they can open it.

Props & StateComponents:
- The states. So they can properly parse something like "Mission_AlertLevel >= 0" or something. And know what to do if a specific state has changed.
- Entities. Props like TriggerZone need to know if specific entities is in the defined zone and set a state accordingly.
- Cells. Props like TriggerRoom need to know if specific entities is in a specific cell and set a state accordingly.

## Specific problems
Worlds. Which belongs to who?

Missions/maps are:
 * Restartable. .getLevel().restartLevel()
 * Destroyable. .getLevel().clearActiveLevel()
 * And replaced by another level. .getLevel().loadLevel("mission_killhouse")

If we put everything in Level its just nonsensical.

So I suggest something like:

- Level
  - Scene
    - Entities, props, etc...

# Design notes
 * Please do not overengineer everything. I don't want a simple system needing like 10 classes for the sake of "seperation of concerns"
Keep things simple.
 * Use several Java philosophies.