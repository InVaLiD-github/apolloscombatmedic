aCM.Config = { -- Don't touch

	 -- Set to false to remove leg damage completely. This won't make you not take damage when shot in the leg, it just makes the script not apply status effects to you.
	LegDamage = true, 
		-- How much speed should the player lose every time they get shot in the leg? by default, the run speed is 240 and walk speed is 160.
		-- When a leg is broken, this will be subtracted from both their run speed and walk speed, this should be around half the run speed
		DamagedLegPenalty = 120,
		MinimumWalkSpeed = 20,

	-- Should the breaking of bones be enabled? This only happens to the legs and arms.
	BrokenBones = true,
		-- When taking damage in the legs and arms, there will be x amount of chance you break a bone.
		BrokenBoneChance = 50,
		FallDamageBreaksLegs = true,
		BrokenRibsPreventSprint = true,

	-- Should bleeding (and blood loss) be enabled?
	Bleeding = true,
		-- If the below is set to false, one bandage will be required for every bleed (every gunshot, etc.)
		BandageFixesWholePart = true,
		-- May be too gruesome for the queasy, just stops the script from making blood decals.
		BloodVisuals = true,

	-- In seconds, how long should the player stay ragdolled? (after this time, they die)
	TimeUntilDeath = 120,
		-- How many seconds off the death timer should each bleed take? Set to 0 to disable.
		DeathTimerBleedPenalty = 5,
		-- If there's so many bleeds that the player would die instantly, what's the time they should live for instead? Set to 0 to make them die immediately in this case.
		DeathTimerMinimumTime = 30,
		-- How many seconds are players locked into being a ragdoll? After this time, players can press any key to respawn (Essentially forfeiting their life).
		-- For example, players must wait 30 seconds as a ragdoll before they can respawn themselves.
		TimeUntilForfeitAllowed = 30,

	-- In seconds, how long should it take medics to assess a player?
	AssessmentTime = 5,

	-- How much health should players get revived with?
	RespawnHealth = 30,

	-- If set to true and the killing blow was to the players head, they do not ragdoll and thus do not have the chance to be revived. They will be fully dead.
	-- This doesn't change the amount of damage to the player, and only counts the damage that killed the player (so if a player gets shot in the head and lives, it won't count)
	InstaDeathHeadshots = true
} -- Don't touch
