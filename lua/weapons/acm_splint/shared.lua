SWEP.Author = "ap6"
SWEP.Contact = "@apollomakesmusic on Discord"
SWEP.Purpose = "The Field Medic's best friend"
SWEP.Instructions = "Left Click: Splint Player, Right Click: Splint Self"
SWEP.Category = "Apollo's Combat Medic Mod"
SWEP.Spawnable = true -- Whether regular players can see it
SWEP.ViewModel = "models/weapons/c_acm_splint.mdl" -- This is the model used for clients to see in first person.
SWEP.WorldModel = "models/weapons/w_acm_splint.mdl" -- This is the model shown to all other clients and in third-person.
SWEP.UseHands = true

if SERVER then
	util.AddNetworkString("aCMSplint.ActionSucceeded")
end

game.AddAmmoType( {
	name = "ACM_SPLINT",
	dmgtype = DMG_GENERIC, 
	tracer = TRACER_NONE,
	plydmg = 0,
	npcdmg = 0,
	force = 0,
	maxcarry = 50,
	minsplash = 0,
	maxsplash = 0
} )

-- Splints
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ACM_SPLINT"
SWEP.PrimaryTime = 0
SWEP.PrimaryDelay = 2.5

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo        = "none"
SWEP.SecondaryTime = 0
SWEP.SecondaryDelay = 2.5

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

		for location, state in pairs(ply.aCM.brokenBones) do
			if state == true then
				nextLocTarget = location
				break
			end
		end

		if nextLocTarget == 0 then return end

		aCM.FixBone(ply, nextLocTarget)

		self:DoAnimation("anim_fire")
		self:TakePrimaryAmmo(1)
		timer.Create("aCM.Splint.BoneSnap"..self.Owner:SteamID(), 0.76, 1, function()
			if self.Owner == nil or !IsValid(self.Owner) or !self.Owner:Alive() then return end
			self.Owner:EmitSound("acm/snap.mp3")
		end)
	end

	self:SetNextPrimaryFire(5)
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

		for location, state in pairs(self.Owner.aCM.brokenBones) do
			if state == true then
				nextLocTarget = location
				break
			end
		end

		if nextLocTarget == 0 then return end

		aCM.FixBone(self.Owner, nextLocTarget)

		self:DoAnimation("anim_fire")
		self:TakePrimaryAmmo(1)
		timer.Create("aCM.Splint.BoneSnap"..self.Owner:SteamID(), 0.76, 1, function()
			if self.Owner == nil or !IsValid(self.Owner) or !self.Owner:Alive() then return end
			self.Owner:EmitSound("acm/snap.mp3")
		end)
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
	SWEP.PrintName = "Splint"
end