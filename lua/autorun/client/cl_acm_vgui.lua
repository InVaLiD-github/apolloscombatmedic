if aCM == nil then
	aCM = {}
end

aCM.DeadScreenFrame = nil
aCM.CanRespawn = false
aCM.HTML = nil

local matBlurScreen = Material( "pp/blurscreen" )
function aCM.BlurPanel(panel, amount, opacity, color)
	local x, y = panel:LocalToScreen( 0, 0 )
	surface.SetMaterial( matBlurScreen )
	surface.SetDrawColor( 0, 0, 0, 255 )
	for i = 0.33, 1, 0.33 do
		matBlurScreen:SetFloat( "$blur", amount * i ) -- Increase number 5 for more blur
		matBlurScreen:Recompute()
		if ( render ) then render.UpdateScreenEffectTexture() end
		surface.DrawTexturedRect( x * -1, y * -1, ScrW(), ScrH() )
	end

	if opacity == nil then
		opacity = 50
	end

	if color == nil then
		color = Color(0,0,0)
	end

	surface.SetDrawColor( ColorAlpha(color, opacity) )
	surface.DrawRect( x * -1, y * -1, ScrW(), ScrH() )
end

function aCM.DeadScreen()
	if aCM.DeadScreenFrame != nil then aCM.DeadScreenFrame:Remove() end

	aCM.DeadScreenFrame = vgui.Create("DFrame")
	local frame = aCM.DeadScreenFrame
	frame:SetSize(ScrW(), ScrH())
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetBackgroundBlur(true)
	function frame:Paint(w,h) 
		aCM.BlurPanel(self, 40, 50, Color(0,0,0))
		draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,200))
	end

	frame.html = vgui.Create("DHTML", frame)
	local html = frame.html
	html:SetSize(frame:GetSize())
	html.onDeadScreen = false

	local deadHTML = [[
		<h1>YOU ARE UNCONSCIOUS</h1>
		<p id="info">WAIT FOR A MEDIC</p>
		<div id="deathTimer">
			<p id="deathTimerLeft">(YOU CAN RESPAWN IN </p><p id="deathTimerNumbers">UNKNOWN</p><p id="deathTimerRight"> SECONDS)</p>
		</div>
	]]

	local respawnHTML = [[
		<h1>PRESS ANY KEY TO GIVE UP</h1>
		<p id="info">OR CONTINUE WAITING FOR A MEDIC.</p>
		<div id="deathTimer">
			<p id="deathTimerLeft">(YOU WILL DIE IN </p><p id="deathTimerNumbers">UNKNOWN</p><p id="deathTimerRight"> SECONDS)</p>
		</div>
	]]

	local css = [[<style>
		body {
			color: #fff;
			font-family: Arial;
			text-align: center;
			font-size: 1vw;
			overflow: hidden;
		}

		h1 {
			width:fit-content;
			font-weight: 1000;
			font-size: 4vw;
			border-bottom: 0.5vh solid #fff;
			text-align:center;
			margin: auto;

			margin-top: 45vh;
		}

		#info {
			text-align:center;
			font-weight: 600;
			font-size: 2vw;
			margin-top: 2vh;
			margin-bottom: 0vh;
		}

		#deathTimer {
			font-weight: 200;
			width: 100vw;
			height:fit-content;
			display: flex;
			flex-direction: row;
			justify-content: center;
			margin-top: 30vh;
		}

		#deathTimerLeft {
			margin-right: 0.35vw;
		}
		#deathTimerRight {
			margin-left: 0.35vw;
		}

	</style>]]

	local documentReady = false
	function html:OnDocumentReady()
		documentReady = true
	end

	local timeUntilRespawn = aCM.TimeOfDeath+aCM.Config.TimeUntilForfeitAllowed

	function frame:Think()
		if frame == nil or !IsValid(frame) or !ispanel(frame) then return end
		if LocalPlayer().aCM.RagdollData == nil then frame:Remove() end

		if aCM.CanRespawn == false then
			if html.onDeadScreen == false then
				html:SetHTML(deadHTML..css)

				html.onDeadScreen = true
			end

			if documentReady == true and aCM.TimeOfDeath != nil then
				html:RunJavascript([[
					var timer = document.getElementById("deathTimerNumbers");
					timer.innerText = " ]]..math.Round(timeUntilRespawn-CurTime())..[[ ";
				]])
			end
		else
			if html.onDeadScreen == true then
				html:SetHTML(respawnHTML..css)
				
				html.onDeadScreen = false
			end

			if documentReady == true and aCM.TimeUntilDead != nil then
				html:RunJavascript([[
					var timer = document.getElementById("deathTimerNumbers");
					timer.innerText = ]]..math.Round(aCM.TimeUntilDead-SysTime())..[[;
				]])
			end
		end

		frame:MoveToFront() -- Keep behind everything
	end

	function frame:OnRemove()
		if aCM.CanRespawn == true then
			aCM.CanRespawn = false
		end
	end
end

function aCM.FindTarget()
	local ent = LocalPlayer():GetEyeTrace().Entity
	if ent == nil or !IsValid(ent) then return end

	if type(ent) == "Player" then
		return ent
	else
		if ent:GetNWBool("aCM.Ragdoll") != true then return end
		local ply = ent:GetNWEntity("aCM.Player")

		return ply, ent
	end
end

function aCM.FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function aCM.SetDownedHTML()
	if aCM.HTML == nil or !ispanel(aCM.HTML) then return end

	aCM.HTML:SetHTML([[
		<img src="https://i.imgur.com/TkffGp0.gif" id="heart"/>
		<div id="wrapper">
			<h1>THIS PLAYER HAS BEEN DOWNED!</h1>
			<p id="info">(+USE THEM WITH THE MEDKIT TO VIEW THEIR AILMENTS</p>
			<p id="info">OR +USE THEM WITHOUT HOLDING THE MEDKIT TO DRAG THEM)</p>
		</div>
	]]..aCM.HTML.aCMCSS)
end

function aCM.SetPatientHTML()
	if aCM.HTML == nil or !ispanel(aCM.HTML) then return end
	if aCM.Patient == nil or !IsValid(aCM.Patient) then return end
	if aCM.Patient.aCM == nil then return end

	local ply = aCM.Patient

	aCM.HTML:SetHTML([[
		<img src="https://i.imgur.com/TkffGp0.gif" id="heart"/>
		<div id="wrapper">
			<h1 id="tod">ESTIMATED TOD: ]]..[[</h1>
			<div id="vital-div">
				<img src="https://i.imgur.com/CfToSfM.png" id="vital-img" /><p class="vital-p" id="bleeds">0</p>
			</div>
			<div id="vital-div">
				<img src="https://i.imgur.com/jNYIFVh.png" id="vital-img" /><p class="vital-p" id="breaks">0</p>
			</div>
		</div>
	]]..aCM.HTML.aCMCSS) --..aCM.FormatTime(ply.aCM.TimeUntilDead-SysTime())
end

hook.Add("PostDrawOpaqueRenderables", "aCM.DrawOverlay", function()
	local ply, ragdoll = aCM.FindTarget()
	if ply == nil or !IsValid(ply) then return end
	if ragdoll == nil or !IsValid(ragdoll) then return end

    if aCM.HTML == nil then
    	aCM.HTML = vgui.Create("DHTML")
    	aCM.HTML:SetSize(600,170)
    	aCM.HTML:SetPos(-300,(170/2)) 
    	aCM.HTML:SetVisible(false)
        aCM.HTML:SetPaintedManually(true)

        aCM.HTML.aCMCSS = [[
    		<style>
    			body {
    				color: #fff;
    				font-family: Arial;
    				background-color: #0000;
    				overflow: hidden;
    				text-align: center;
    				margin: 0;
    				padding: 0;
    				display: flex;
    				flex-direction: row;
    			}

    			#wrapper {
    				background-color: #000a;
    				overflow: hidden;
    				border-radius: 10vw;
    				padding-left: 5vw;
    				padding-right: 5vw;
    				height: 100%;
    				align-self: center;
    				display: flex;
    				flex-direction: column;
    				justify-content: center;
    			}

    			h1 {
    				width: fit-content;
    				color: #f00;
    				margin: auto;
    				margin-top: 5vh;
    				margin-bottom: 3vh;
    				border-bottom: 2vh solid #f00;
    				font-size: 3vw;
    			}

    			img {
    				width: 75px;
    				height: 75px;
    				object-fit: contain;
    				float: left;
    				align-self: center;
    				margin-right: 4vw;
    			}

    			#downed {
    				font-weight: 600;
    				font-size: 3vw;
    				margin-top:0;
    			}

    			#info {
    				font-weight: 0;
    				font-size: 2vw;
    				margin: 0;
    				padding: 0;
    			}

    			#vital-div {
					display: flex;
					flex-direction: row;
					justify-content: space-evenly;
				}

				.vital-p {
					align-self: center;
					font-size: 5vw;
					margin: 0;
				}

				#vital-img {
					align-self: center;
					width: 10vw !important;
					height: 10vw !important;
					object-fit: contain;
				}

				#heart {
					filter: brightness(0) saturate(100%) invert(21%) sepia(82%) saturate(5594%) hue-rotate(354deg) brightness(90%) contrast(126%);
				}
    	
    	</style>
    	]]

        if aCM.Patient == ply then
        	aCM.SetPatientHTML()
        else
        	aCM.SetDownedHTML()
        end

        aCM.HTML.documentReady = false
        function aCM.HTML:OnDocumentReady()
        	aCM.HTML.documentReady = true
        end
    end

    local function updateHTML()
    	if aCM.HTML.documentReady == false then return end
    	if aCM.HTML == nil or !IsValid(aCM.HTML) or !ispanel(aCM.HTML) then return end
	    if aCM.HTML == nil or !ispanel(aCM.HTML) then return end
		if aCM.Patient == nil or !IsValid(aCM.Patient) then return end
		if aCM.Patient.aCM == nil then return end

    	aCM.HTML:RunJavascript([[
			var timer = document.getElementById("tod");
			if (timer) {
				timer.innerText = "ESTIMATED TUD: ]]..aCM.FormatTime(ply.aCM.TimeUntilDead-SysTime())..[[";
			}

			var bleeds = document.getElementById("bleeds");
			if (bleeds) {
				bleeds.innerText = ]]..aCM.Patient.aCM.totalBleeds..[[;
			}

			var breaks = document.getElementById("breaks");
			if (breaks) {
				breaks.innerText = ]]..aCM.Patient.aCM.totalBrokenBones..[[;
			}
		]])
    end

    updateHTML()

    local pos = ragdoll:GetPos()
	local forward = Entity(1):GetForward()
	local forwardAngle = forward:Angle()

	cam.Start3D2D(pos+Vector(0,0,40), Angle(0, forwardAngle.y - 90, forwardAngle.r + 90), 0.1)
		if aCM.HTML:IsVisible() == false then aCM.HTML:SetVisible(true) end
		aCM.HTML:PaintManual()
	cam.End3D2D()
end)