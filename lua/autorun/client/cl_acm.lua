aCM = {}

include("apolloscombatmedic/config.lua")

language.Add("ACM_BANDAGE_ammo", "Bandages")
language.Add("ACM_SPLINT_ammo", "Splints")

aCM.Assessing = false
aCM.TimeOfAssessment = nil
aCM.Patient = nil
aCM.TimeOfDeath = 0
aCM.TimeUntilDeath = 0

aCM.HitGroupDictionary = {
	[HITGROUP_GENERIC] = "Body Overall",
	[HITGROUP_HEAD] = "Head",
	[HITGROUP_CHEST] = "Ribs",
	[HITGROUP_STOMACH] = "Torso",
	[HITGROUP_LEFTARM] = "Left Arm",
	[HITGROUP_RIGHTARM] = "Right Arm",
	[HITGROUP_LEFTLEG] = "Left Leg",
	[HITGROUP_RIGHTLEG] = "Right Leg",
	[HITGROUP_GEAR] = "Belt",
}

function aCM.StartAssessment(ply)
	if ply == nil or !IsValid(ply) or (!ply:IsPlayer() and !ply:IsBot()) then return end
	aCM.Assessing = true

	LocalPlayer():ChatPrint("Assessing "..ply:Nick().."...")

	aCM.TimeOfAssessment = CurTime()

	if timer.Exists("aCM.AssessPlayer") then 
		timer.Stop("aCM.AssessPlayer") 
		timer.Remove("aCM.AssessPlayer") 
	end

	timer.Create("aCM.AssessPlayer", aCM.Config.AssessmentTime, 1, function()
		aCM.Assessing = false
		
		if ply == nil or !IsValid(ply) then return end
		local ragdoll = ply:GetNWEntity("aCM.RagdollEntity", nil)
		if ragdoll == nil or !IsValid(ragdoll) then return end

		net.Start("aCM.Assessment")
			net.WriteEntity(ragdoll)
		net.SendToServer()

		ragdoll.wasAssessed = true
	end)
end


gameevent.Listen( "player_activate" )
hook.Add("player_activate", "aCM.PlayerActivate", function(data) 
	net.Start("aCM.Loaded")
	net.SendToServer()

	if BRANCH != "x86-64" then
		LocalPlayer():ChatPrint("aCM :: You are not on the x86-64 branch of Garry's Mod. UI will probably be broken.")
	end
end)

hook.Add("Think", "aCM.Think", function()
	if !LocalPlayer():Alive() then return end

	local ent = LocalPlayer():GetEyeTrace().Entity
	if ent == nil or !IsValid(ent) then return end
	if ent:GetNWBool("aCM.Ragdoll") != true then return end

	-- Assess Player
	if LocalPlayer():KeyDown(IN_USE) and LocalPlayer():GetActiveWeapon():GetClass() == "acm_medkit" then
		if aCM.Assessing == false then
			if ent.wasAssessed != true then
				aCM.StartAssessment(ent:GetNWEntity("aCM.Player"))
			end
		end
	end
end)

net.Receive("aCM.UpdatePlayer", function()
	LocalPlayer().aCM = nil
	
	LocalPlayer().aCM = net.ReadTable()
end)

net.Receive("aCM.Assessment", function()
	local aCMTable = net.ReadTable()
	local target = net.ReadEntity()

	target.aCM = aCMTable

	target.aCM.totalBleeds = 0

	local bleeds = 0
	for _,amount in pairs(target.aCM.bleeds) do
		if aCM.Config.BandageFixesWholePart == true then
			if amount != 0 then
				bleeds = bleeds + 1
			end
		else
			bleeds = bleeds + amount
		end
	end

	local brokenBonesString = ""
	local bones = 0
	for loc,_ in pairs(target.aCM.brokenBones) do
		brokenBonesString = brokenBonesString..(bones != 0 and ", " or "")..aCM.HitGroupDictionary[loc]
		bones = bones + 1
	end

	target.aCM.totalBrokenBones = bones
	target.aCM.totalBleeds = bleeds

	aCM.Patient = target
	aCM.SetPatientHTML()

	LocalPlayer():ChatPrint("Assessment Complete:")
	LocalPlayer():ChatPrint("	Bleeds: "..bleeds)
	LocalPlayer():ChatPrint("	Broken Bones: "..brokenBonesString)
	LocalPlayer():ChatPrint("	Seconds until death: "..math.Round(target.aCM.TimeUntilDead-SysTime()))
end)

net.Receive("aCM.IsDead", function()
	local state = net.ReadBool()
	aCM.TimeUntilDead = net.ReadInt(32)

	if state == true then
		aCM.TimeOfDeath = CurTime()
		aCM.DeadScreen()
	else
		if aCM.DeadScreenFrame != nil then
			aCM.DeadScreenFrame:Remove()
			aCM.DeadScreenFrame = nil
		end
	end
end)

net.Receive("aCM.CanRespawn", function()
	aCM.CanRespawn = true
end)

net.Receive("aCM.PlayerRevived", function()
	local ply = net.ReadEntity()

	if aCM.Patient == ply then
		aCM.Patient = nil
		aCM.SetDownedHTML()
	end
end)