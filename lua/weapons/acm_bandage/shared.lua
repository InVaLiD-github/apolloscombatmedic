SWEP.Author = "ap6"
SWEP.Contact = "@apollomakesmusic on Discord"
SWEP.Purpose = "The Field Medic's best friend"
SWEP.Instructions = "Left Click: Bandage Player, Right Click: Bandage Self"
SWEP.Category = "Apollo's Combat Medic Mod"
SWEP.Spawnable = true -- Whether regular players can see it
SWEP.ViewModel = "models/weapons/c_acm_bandage.mdl" -- This is the model used for clients to see in first person.
SWEP.WorldModel = "models/weapons/w_acm_bandage.mdl" -- This is the model shown to all other clients and in third-person.
SWEP.UseHands = true

if SERVER then
	util.AddNetworkString("aCMBandage.ActionSucceeded")
end

game.AddAmmoType( {
	name = "ACM_BANDAGE",
	dmgtype = DMG_GENERIC, 
	tracer = TRACER_NONE,
	plydmg = 0,
	npcdmg = 0,
	force = 0,
	maxcarry = 50,
	minsplash = 0,
	maxsplash = 0
} )

-- Bandages
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ACM_BANDAGE"
SWEP.PrimaryTime = 0
SWEP.PrimaryDelay = 2

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo        = "none"
SWEP.SecondaryTime = 0
SWEP.SecondaryDelay = 2

function SWEP:DoAnimation(anim)
	if self.Owner == nil or !IsValid(self.Owner) then return end
	local vm = self.Owner:GetViewModel()
	if vm == nil or !IsValid(vm) then return end
	
	local sequence = vm:LookupSequence(anim)
	vm:SendViewModelMatchingSequence(sequence)
end

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then return end
	if CurTime() < self.PrimaryTime then return end

	if DarkRP != nil and aCM.Config.StrictMedicRules and aCM.Config.MedicRolesEnabled then
		if !table.HasValue(aCM.Config.MedicRoles, self.Owner:Team()) then
			return
		end
	end

	local ply, ragdoll = aCM.FindTarget(self.Owner)
	if ragdoll != nil then return end -- Don't perform actions on ragdolls. Assessment UI will heal downed players.
	if ply == nil or !IsValid(ply) then return end
	
	if SERVER then
		local nextLocTarget = 0

		for location, amount in pairs(ply.aCM.bleeds) do
			if amount != 0 then
				nextLocTarget = location
				break
			end
		end

		if nextLocTarget == 0 then return end

		if aCM.Config.BandageFixesWholePart == true then
			aCM.FixAllBleeds(ply, nextLocTarget)
		else
			aCM.FixBleed(ply, nextLocTarget)
		end

		if ragdoll != nil then
			ragdoll:EmitSound("acm/bandage.mp3")
		else
			ply:EmitSound("acm/bandage.mp3")
		end

		self:DoAnimation("anim_fire")
		self:TakePrimaryAmmo(1)
	end
	
	self.PrimaryTime = CurTime()+self.PrimaryDelay
end

function SWEP:SecondaryAttack()
	if self:Clip1() <= 0 then return end
	if CurTime() < self.SecondaryTime then return end

	if DarkRP != nil and aCM.Config.StrictMedicRules and aCM.Config.MedicRolesEnabled then
		if !table.HasValue(aCM.Config.MedicRoles, self.Owner:Team()) then
			return
		end
	end

	if SERVER then
		local nextLocTarget = 0

		for location, amount in pairs(self.Owner.aCM.bleeds) do
			if amount != 0 then
				nextLocTarget = location
				break
			end
		end

		if nextLocTarget == 0 then return end


		if aCM.Config.BandageFixesWholePart == true then
			aCM.FixAllBleeds(self.Owner, nextLocTarget)
		else
			aCM.FixBleeds(self.Owner, nextLocTarget)
		end

		self.Owner:EmitSound("acm/bandage.mp3")

		self:DoAnimation("anim_fire")
		self:TakePrimaryAmmo(1)
	end

	self:SetNextSecondaryFire(5)
	self.SecondaryTime = CurTime()+self.SecondaryDelay
end

function SWEP:Reload()
	-- Do nothing.
end

function SWEP:Initialize()
	if self.Owner == nil then return end
	self:DoAnimation("anim_draw")
	self:SetHoldType("slam")
end

function SWEP:Deploy()
	self:DoAnimation("anim_draw")
end

if SERVER then
	AddCSLuaFile()
elseif CLIENT then
	SWEP.PrintName = "Bandage"
end