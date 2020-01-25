
CreateClientConVar( "AM_Control_HornKey", KEY_H, true, false, "Sets the key for the horn." )
CreateClientConVar( "AM_Control_LockKey", KEY_N, true, false, "Sets the key for locking the doors." )
CreateClientConVar( "AM_Control_CruiseKey", KEY_B, true, false, "Sets the key for toggling cruise control." )
CreateClientConVar( "AM_Config_CruiseMPH", 1, true, false, "Enable or disable displaying cruise speed in MPH. Disable to set to KPH." )

hook.Add( "PopulateToolMenu", "AM_ControlMenu", function()
	spawnmenu.AddToolMenuOption( "Options", "Automod", "AutomodControls", "Controls", "", "", function( panel )
		panel:AddControl( "Header", { --This is deprecated but all default gmod tools still use it?
			Description = "Change your Automod controls here."
		} )
		panel:AddControl( "Numpad", {
			Label = "Horn Key",
			Command = "AM_Control_HornKey",
			Label2 = "Lock Key",
			Command2 = "AM_Control_LockKey"
		} )
		panel:AddControl( "Numpad", {
			Label = "Cruise Control Key",
			Command = "AM_Control_CruiseKey"
		} )
		panel:CheckBox( "Cruise Control: Display in MPH", "AM_Config_CruiseMPH" )
	end )
end )

net.Receive( "AM_Notify", function( len, ply )
	local text = net.ReadString()
	local textcolor1 = Color( 180, 0, 0, 255 )
	local textcolor2 = color_white
	chat.AddText( textcolor1, "[Automod]: ", textcolor2, text )
end )

surface.CreateFont( "AM_HUDFont1", {
	font = "Roboto",
	size = 18
} )

surface.CreateFont( "AM_HUDFont2", {
	font = "Roboto",
	size = 14
} )

local AM_FuelAmount = GetConVar( "AM_Config_FuelAmount" ):GetInt()
local AM_FuelEnabled = GetConVar( "AM_Config_FuelEnabled" ):GetBool()
local HUDPositions = {}
local HUDPhoton = {
	Background = { ScrW() - 180, ScrH() - 450 },
	Health = { ScrW() - 140, ScrH() - 440 },
	Lock = { ScrW() - 140, ScrH() - 410 },
	Cruise = { ScrW() - 170, ScrH() - 380 },
	FuelTitle = { ScrW() - 115, ScrH() - 350 },
	FuelBackground = { ScrW() - 140, ScrH() - 337 },
	Fuel = { ScrW() - 138, ScrH() - 332 },
	AddonName = { ScrW() - 180, ScrH() - 280 },
	AddonInfo = { ScrW() - 180, ScrH() - 265 }
}
local HUDNoPhoton = {
	Background = { ScrW() - 180, ScrH() - 200 },
	Health = { ScrW() - 140, ScrH() - 190 },
	Lock = { ScrW() - 140, ScrH() - 160 },
	Cruise = { ScrW() - 170, ScrH() - 130 },
	FuelTitle = { ScrW() - 115, ScrH() - 100 },
	FuelBackground = { ScrW() - 140, ScrH() - 87 },
	Fuel = { ScrW() - 138, ScrH() - 82 },
	AddonName = { ScrW() - 180, ScrH() - 30 },
	AddonInfo = { ScrW() - 180, ScrH() - 15 }
}

hook.Add( "HUDPaint", "AM_HUDStuff", function() --Main HUD, needs adjusted so it works alongside photon and seat weaponizer mods
	local ply = LocalPlayer()
	if ply:InVehicle() then
		local vehicle = ply:GetVehicle()
		local vehhealth = vehicle:GetNWInt( "AM_VehicleHealth" )
		local vehmaxhealth = vehicle:GetNWInt( "AM_VehicleMaxHealth" )
		local fuellevel = vehicle:GetNWInt( "AM_FuelAmount" )
		local godenabled = vehicle:GetNWBool( "GodMode" )
		local issmoking = vehicle:GetNWBool( "AM_IsSmoking" )

		if vehicle.VehicleName then --Detects if the vehicle has Photon support or not
			HUDPositions = HUDPhoton
		else
			HUDPositions = HUDNoPhoton
		end
		
		local background = HUDPositions.Background
		local health = HUDPositions.Health
		local lock = HUDPositions.Lock
		local cruise = HUDPositions.Cruise
		local fueltitle = HUDPositions.FuelTitle
		local fuelback = HUDPositions.FuelBackground
		local fuel = HUDPositions.Fuel
		local name = HUDPositions.AddonName
		local info = HUDPositions.AddonInfo
		if vehicle:GetClass() == "prop_vehicle_jeep" then
			draw.RoundedBox( 5, background[1], background[2], 180, 200, Color( 30, 30, 30, 254 ) )
			surface.SetFont( "AM_HUDFont1" )

			if issmoking or vehhealth <= vehmaxhealth * 0.25 then
				surface.SetTextColor( 255, 0, 0, 255 )
			else
				surface.SetTextColor( color_white )
			end

			surface.SetDrawColor(color_white)
			surface.SetTextPos( health[1], health[2] )

			if godenabled then
				surface.SetTextColor( 0, 255, 0 )
			end

		    if vehmaxhealth > 0 then
			    surface.DrawText( "Health: "..math.Round( vehhealth ).."/"..vehmaxhealth )
			else
				surface.DrawText( "Health Disabled" )
			end
			surface.SetTextColor( color_white )
			surface.SetTextPos( lock[1], lock[2] )
			if vehicle:GetNWBool( "AM_DoorsLocked" ) then
				surface.SetTextColor( color_white )
			    surface.DrawText( "Doors: Locked" )
			else
				surface.SetTextColor( 196, 145, 2 )
				surface.DrawText( "Doors: Unlocked" )
			end

			surface.SetTextColor( color_white )
			surface.SetTextPos( cruise[1], cruise[2] )
			if vehicle:GetNWBool( "CruiseActive" ) then
				surface.SetTextColor( 0, 255, 0 )
				local velocity = vehicle:GetVelocity():Length()
				local speed = 0
				local label = ""
				if GetConVar( "AM_Config_CruiseMPH" ):GetBool() then
					speed = math.Round( velocity * 3600 / 63360 * 0.75 )
					label = "MPH"
				else
					speed = math.Round( velocity * 3600 * 0.0000254 * 0.75 )
					label = "KPH"
				end
				surface.DrawText( "Cruise Control: "..speed.." "..label )
			else
				surface.DrawText( "Cruise Control: Disabled" )
			end

			local fuel75 = AM_FuelAmount * 0.75
			local fuel25 = AM_FuelAmount * 0.25
			surface.SetDrawColor( color_white )
			if AM_FuelEnabled then
				surface.DrawRect( fuelback[1], fuelback[2], 105, 20 )
				if fuellevel >= fuel75 then
					surface.SetDrawColor( 0, 255, 0 )
				elseif fuellevel < fuel75 and fuellevel >= fuel25 then
					surface.SetDrawColor( 196, 145, 2 )
				elseif fuellevel < fuel25 then
					surface.SetDrawColor( 255, 0, 0 )
				end
				surface.DrawRect( fuel[1], fuel[2], math.Clamp( fuellevel, 0, 100 ), 10 )
			else
				surface.SetTextColor( color_white )
				surface.SetTextPos( fuel[1], fuel[2] )
				surface.DrawText( "Fuel Disabled" )
			end
			
			surface.SetFont( "AM_HUDFont2" )
			surface.SetTextColor( color_white )
			surface.SetTextPos( fueltitle[1], fueltitle[2] )
			surface.DrawText( "Fuel Level:" )

			
			surface.SetTextPos( name[1], name[2] )
			surface.DrawText( "Automod - By [λG] O.P. Gλmer" )
			surface.SetTextPos( info[1], info[2] )
			surface.DrawText( "Suggestions are appreciated!" )
		end
	end
end )

local seatbuttons = {
	{ KEY_1, 1 },
	{ KEY_2, 2 },
	{ KEY_3, 3 },
	{ KEY_4, 4 },
	{ KEY_5, 5 },
	{ KEY_6, 6 },
	{ KEY_7, 7 },
	{ KEY_8, 8 },
	{ KEY_9, 9 },
	{ KEY_0, 10 }
}
hook.Add( "PlayerButtonDown", "AM_KeyPressDown", function( ply, key )
	if IsFirstTimePredicted() then
		if ply:InVehicle() then
			if key == GetConVar( "AM_Control_LockKey" ):GetInt() then
				net.Start( "AM_VehicleLock" )
				net.SendToServer()
			end
			if key == GetConVar( "AM_Control_HornKey" ):GetInt() then
				net.Start( "AM_VehicleHorn" )
				net.SendToServer()
			end
			if key == GetConVar( "AM_Control_CruiseKey" ):GetInt() then
				net.Start( "AM_CruiseControl" )
				net.SendToServer()
			end
			for k,v in pairs( seatbuttons ) do
				if key == v[1] then
					net.Start( "AM_ChangeSeats" )
					net.WriteInt( v[2], 32 )
					net.SendToServer()
				end
			end
		end
	end
end )

hook.Add( "PlayerButtonUp", "AM_KeyPressUp", function( ply, key )
	if IsFirstTimePredicted() then
		if ply:InVehicle() then
			if key == GetConVar( "AM_Control_HornKey" ):GetInt() then
				net.Start( "AM_VehicleHornStop" )
				net.SendToServer() --Not sure if this the most optimised way to do this
			end
		end
	end
end )

hook.Add( "Think", "AM_SmokeThink", function()
	local ply = LocalPlayer()
	for k,v in pairs( ents.FindByClass( "prop_vehicle_jeep" ) ) do
		if v:GetNWBool( "AM_IsSmoking" ) then
			local carpos = v:GetPos()
			local plypos = ply:GetPos()
			if plypos:DistToSqr( carpos ) < 4000000 then --Only displays particles if the player is within a certain distance of the vehicle, helps with optimization
				local pos = v:LocalToWorld( v:GetNWVector( "AM_EnginePos" ) )
				local smoke = ParticleEmitter( pos ):Add( "particle/smokesprites_000"..math.random( 1, 9 ), pos )
				smoke:SetVelocity( Vector( 0, 0, 50 ) )
				smoke:SetDieTime( math.Rand( 0.6, 1.3 ) )
				smoke:SetStartSize( math.random( 0, 5 ) )
				smoke:SetEndSize( math.random( 33, 55 ) )
				smoke:SetColor( 72, 72, 72 )
			end
		end
	end
end )