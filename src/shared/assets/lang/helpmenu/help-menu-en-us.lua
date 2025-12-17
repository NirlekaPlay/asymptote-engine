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
		Title = "Detection",
		Body = [=[
			Currently the only things that can detect are NPCs. NPCs can detect entities
			such as players and placed C4 explosives. If an NPC is detecting you wether
			you are doing anything suspicious or just straight up have a gun, the
			detection meter appears pointing at the NPC. In order for detection to be registered,
			the meter would need to be fully filled. If an NPC is close enough to the
			entity, the detection will be made instantly.

			\n\nYou cannot see the detection meter if the NPCs are not exactly detecting YOU specifically.
			This goes for placed C4s and dead bodies.
		]=],
		ButtonText = "Detection"
	}
}