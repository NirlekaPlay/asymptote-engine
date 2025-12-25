return {
	{
		Title = "Welcome!",
		Body = [=[
			Welcome to the Asymptote Engine demo!
			\nThis is a passion project of mine which has been going on for years now.
			But actual development began around July 2025.
			\n\nIt is basically Entry Point and its successor,
			Operators (both made by Cishshato) but with Plasma lore.
		]=],
		ButtonText = "Welcome"
	},
	{
		Title = "Alert Level",
		Body = [=[
			The alert level is the state of alertness the guards in the mission is
			currently in. It goes on a progression Calm -> Normal -> Alert -> Searching -> Lockdown.
			Once the alert level reaches Searching or Lockdown, you are out of stealth mode
			and there is no coming back. In this state, all guards will retreat to their
			choosen post and will arm their weapons and shoot anyone on sight which they
			find suspicious or a threat.
			
			\n\nCurrently the alert level will only affect wether or not guards or other NPCs
			can see through disguises.
		]=],
		ButtonText = "Alert Level"
	},
	{
		Title = "The Brain System",
		Body = [=[
			Asymptote Engine uses a complex AI system for its NPCs, that uses memories,
			sensors, behaviors, and activities. The system is based on Minecraft Java's
			entity AI system. You can view the inner workings of NPCs in real time
			by pressing the `N` key to the brain debug renderer and point your cursor
			on an NPC thats alive.
		]=],
		ButtonText = "AI"
	},
	{
		Title = "NPCs Reactions and Behaviors",
		Body = [=[
			NPCs can react to all sorts of things. Currently, it can react to
			players' statuses, such as Armed, Trespassing, and Suspicious.
			It can also react to placed C4 explosives.
		]=],
		ButtonText = "AI - Reactions"
	},
	{
		Title = "Commands",
		Body = [=[
			Oh ja, commands. You know 'em, you love 'em. Currently, everyone
			has access to them. Yes. Everyone. Even plebeians like you in a
			public server. I haven't implemented an access restriction on them yet,
			so I will just assume that you are a normal, sane, totally responsible
			person with a system that will probably cause many shenanigans if used unwisely.

			\n\nYou can view the available commands by typing /help in the chat.
			Yeah, we don't have a dedicated UI for that, sorry.

			\n\nThe syntax is Minecraft Java syntax, why? Because the command parser
			is Brigadier! Developed by Mojang themselves for Minecraft Java.
			That means you can input positions like ~2~4~8, entity selectors like
			@e, @e[type=!player], and many more!
		]=],
		ButtonText = "Commands"
	},
	{
		Title = "Detection",
		Body = [=[
			Detection is the main heart of social stealth, and understandingly
			one of the most complicated mechanics of this game.
			
			\n\nCurrently the only things that can detect are NPCs. NPCs can detect entities
			such as players and placed C4 explosives. If an NPC is detecting you wether
			you are doing anything suspicious or just straight up have a gun, the
			detection meter appears pointing at the NPC. In order for detection to be registered,
			the meter would need to be fully filled. If an NPC is close enough to the
			entity, the detection will be made instantly.

			\n\nWhen detecting a player, they will detect you based on your highest *detectable*
			status by priority. If you are trespassing but you are waving around your gun,
			NPCs seeing you will detect with you based on your Armed status. However, if they do
			not see you but you're close enough to the them, they will detect you based on your Trespassing
			status through hearing.

			\n\nYou cannot see the detection meter if the NPCs are not exactly detecting YOU specifically.
			This goes for placed C4s and dead bodies.
		]=],
		ButtonText = "Detection"
	},
	{
		Title = "Disguises",
		Body = [=[
			Some disguises allows you to blend in with security or other staff
			members and lower the severeness or completely allowing you to
			enter trespassing areas. But they won't fool everyone.

			\n\nHigher level security personnel may see through your disguises.
			and as the alert level rises, the more people will be suspicious of your
			disguise.
		]=],
		ButtonText = "Disguises"
	},
	{
		Title = "Radio Calls",
		Body = [=[
			Before the alert level can be raised when someone witnessed something suspicious
			or illegal, they have to make a radio or phone call in order to do so.

			\n\nYou can interrupt these calls by just simply killing them, or have them
			see something of higher priority. Interrupting a radio call will prevent the
			alert level from rising.
		]=],
		ButtonText = "Radio Calls"
	},
	{
		Title = "Sounds — General",
		Body = [=[
			Certain sounds can be detected by NPCs, as of Biopsy 124, gunshots are the only
			sources of sounds detectable by NPCs.

			\n\nThe engine uses a voxel-based pathfinding algorithm, implementing a modified
			version of the A* algorithm. Sounds can travel at vast or short distance depending
			on the type. They can penetrate through walls based on their power, the walls' thickness
			and material.

			\n\nWhen NPCs detect a sound, they do not turn towards the sound's actual position,
			instead they turn towards the perceived direction on where the sound came from.
		]=],
		ButtonText = "Sounds — General"
	},
	{
		Title = "Sounds — Movement",
		Body = [=[
			If you are trespassing, even if the guards can't see you, they can still hear you walking
			around if close enough. Make sure to stay quiet, and running only makes them
			detect you more faster.
		]=],
		ButtonText = "Sounds — Movement"
	},
	{
		Title = "Joining Experimental Version",
		Body = [=[
			Now, we have an inside joke where the 'stable version', the version you mere
			mortals join, are more unstable than experimental version. Shocking right?
			Well, actually, it makes sense since I update the experimental version
			daily, which leads to bugs getting fixed early before being pushed to
			public versions.

			\n\nNow you might be asking. "But Isa!!1! How do I join those cool,
			chaotic experimental serve-" Well shut up cuz I'm gonna tell that to you!

			\n\nFirst, go to a lobby. If you're not in it already. Assuming you're not
			reading this help menu while already in a mission. Are you absolutely flabbergasted
			that you need to open the help menu mid-game or whut?

			\n\nSecond, see that engine version text at the top-right of your screen?
			Yeah, hold on that for more than 3 seconds, and voilà! There's
			the 'Join Testing Button', which, upon getting clicked, will send you to
			the realm where our testers do many shenanigans to the game.

			\n\Anything besides actual testing for those people.
		]=],
		ButtonText = "Joining Experimental"
	},
}