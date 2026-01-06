SWEP.Author = "ap6"
SWEP.Contact = "@apollomakesmusic on Discord"
SWEP.Purpose = "The Field Medic's best friend"
SWEP.Instructions = "E: Assess Player, Left click: Bandage Player, Right Click: Splint Player, R: Revive Player"
SWEP.Category = "Apollo's Combat Medic Mod"
SWEP.Spawnable = true -- Whether regular players can see it
SWEP.ViewModel = "models/weapons/c_acm_kit.mdl" -- This is the model used for clients to see in first person.
SWEP.WorldModel = "models/weapons/w_acm_kit.mdl" -- This is the model shown to all other clients and in third-person.
SWEP.UseHands = true

-- Bandages
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.PrimaryTime = 0
SWEP.PrimaryDelay = 1

--Splints
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.SecondaryTime = 0
SWEP.SecondaryDelay = 1

--Revive
SWEP.ReloadTime = 0
SWEP.ReloadDelay = 1

if SERVER then
	util.AddNetworkString("aCMKit.ActionSucceeded")
	util.AddNetworkString("aCMKit.ReviveSuccess")
end

function SWEP:DoAnimation(anim)
	local vm = self.Owner:GetViewModel()
	local sequence = vm:LookupSequence(anim)
	vm:SendViewModelMatchingSequence(sequence)
end

function SWEP:PrimaryAttack()
	if aCM.Config.MedicRolesEnabled and aCM.Config.StrictMedicRules then
		if aCM.Config.DarkRPEnabled then
			if !table.HasValue(aCM.Config.MedicRoles, self.Owner:Team()) then
				return
			end
		else
			local customCheck = aCM.Config.MedicRoleCustomCheck(self.Owner)
			if customCheck != true then return end
		end
	end

	local ply, ragdoll = aCM.FindTarget(self.Owner)
	if ply == nil or !IsValid(ply) then return end
	if ragdoll == nil or !IsValid(ragdoll) then return end
	if CurTime() < self.ReloadTime then return end

	if SERVER then
		if aCM.DoctorCache[self.Owner] != ply then return end

		local bleeding = false
		for loc, amount in pairs(ply.aCM.bleeds) do
			if amount != 0 then 
				bleeding = true 
				break
			end
		end

		if bleeding == false then
			aCM.RevivePlayer(ply)
			self:DoAnimation("anim_fire")
			net.Start("aCMKit.ReviveSuccess")
			net.Send(self.Owner)
		end
	end

	self.ReloadTime = CurTime()+self.ReloadDelay

	return
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Reload()

end

function SWEP:Initialize()
	
end

if SERVER then
	AddCSLuaFile()
elseif CLIENT then
	SWEP.PrintName = "Trauma Kit"

	function SWEP:Holster()
		if self.Frame != nil then 
			self.Frame:Remove() 
			self.Frame = nil 
		end
	end

	function SWEP:DrawHUD()
	    local vm = self.Owner:GetViewModel() -- Get the viewmodel
	    if not IsValid(vm) then return end

	    pos, ang = vm:GetBonePosition(vm:LookupBone("medkit_bone"))
		
	    local html = [[
	    	<div id="body">
		    	<h1>TRAUMA KIT</h1>

		    	<div id="content">
		    		<p><b>E</b>: ASSESS PLAYER</p>
			    	<p><b>M1</b>: REVIVE PLAYER</p>
		    	</div>
		    </div>

			<style>
				body {
					color: #fff;
					font-family: Arial;
					
					background-color: #0000;
					overflow: hidden;
					font-size: 10vh;
					margin: 0;
					padding: 0;
				}

				#body {
					
					text-align: center;
					width: 98%;
					height: 90%;
					
					margin-bottom 10%;
					border: 1vh solid #fff;
				}

				h1 {
					font-weight: 1000;
					margin-bottom: 0;
					margin-top: 0;
				}

				#content {
					background-color: #0000;
					width: 100%;
					height: 100%;
					overflow: hidden;
					float: right;
					text-align: center;
					margin-bottom: 0;
				}
			</style>
	    ]]

		if self.Frame == nil then
			self.Frame = vgui.Create("DFrame")
			local frame = self.Frame

			frame:SetTitle("")
			frame:SetSize(ScrW()/8, ScrH()/8)
			frame:SetPos(ScrW()-(frame:GetWide()), 0)
			frame:ShowCloseButton(false)

			function frame:OnRemove()
				self.Frame = nil
				frame = nil
			end

			function frame:Paint() 
			end

			frame.panel = vgui.Create("DPanel", frame)
			local panel = frame.panel
			panel:SetSize(frame:GetWide(), frame:GetTall()-30)
			panel:SetPos(0, 30)

			function panel:Paint(w,h)
				aCM.BlurPanel(panel, 10, 50, Color(0,0,0))
				draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,200))
			end

			frame.html = vgui.Create("DHTML", panel)
			frame.html:SetSize(frame:GetSize())
			frame.html:SetPos(0,0)
			frame.html:SetHTML(html)
		end

		local screenData = pos:ToScreen()
		local frame = self.Frame
		frame:MoveToBack() -- always keep it under everything else
	end

	net.Receive("aCMKit.ActionSucceeded", function()
		surface.PlaySound("HealthKit.Touch")
	end)

	net.Receive("aCMKit.ReviveSuccess", function()
		surface.PlaySound("Buttons.snd1")
	end)
end