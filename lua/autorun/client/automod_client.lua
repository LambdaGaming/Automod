
local AM_HealthEnabled = GetConVar( "AM_Config_HealthEnabled" ):GetBool()
local AM_WheelLockEnabled = GetConVar( "AM_Config_WheelLockEnabled" ):GetBool()
local AM_DoorLockEnabled = GetConVar( "AM_Config_LockEnabled" ):GetBool()
local AM_BrakeLockEnabled = GetConVar( "AM_Config_BrakeLockEnabled" ):GetBool()
local AM_SeatsEnabled = GetConVar( "AM_Config_SeatsEnabled" ):GetBool()

hook.Add( "HUDPaint", "AM_HUDStuff", function() --Main HUD, needs adjusted so it works alongside photon and seat weaponizer mods
	local ply = LocalPlayer()
	if ply:InVehicle() then
		local vehicle = ply:GetVehicle()
		if vehicle:GetClass() == "prop_vehicle_jeep" then
			draw.RoundedBox( 5, 1500, ScrH() - 155, 200, 150, Color(25,25,25,200) )
			surface.SetFont( "Trebuchet18" )
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.SetTextPos( 1500, ScrH() - 155 )
		    if AM_HealthEnabled then
			    surface.DrawText( vehicle:GetNWInt( "AM_VehicleHealth" ).."/"..vehicle:GetNWInt( "AM_VehicleMaxHealth" ) )
			else
			    surface.DrawText( "Health Disabled" )
			end
			surface.SetTextPos( 1500, ScrH() - 135 )
			if vehicle:GetNWBool( "AM_DoorsLocked" ) then
			    surface.DrawText( "Doors: Locked" )
			else
				surface.DrawText( "Doors: Unlocked" )
			end
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
	{ KEY_9, 9 }
}
hook.Add( "PlayerButtonDown", "AM_KeyPressDown", function( ply, key )
	if IsFirstTimePredicted() then
		if ply:InVehicle() then
			if key == KEY_N then
				net.Start( "AM_VehicleLock" )
				net.SendToServer()
			end
			if key == KEY_H then
				net.Start( "AM_VehicleHorn" )
				net.SendToServer()
			end
			for k,v in pairs( seatbuttons ) do
				if key == v[1] then
					net.Start( "AM_ChangeSeats" )
					net.WriteString( tostring( v[2] ) )
					net.SendToServer()
				end
			end
		end
	end
end )

hook.Add( "PlayerButtonUp", "AM_KeyPressUp", function( ply, key )
	if IsFirstTimePredicted() then
		if ply:InVehicle() then
			if key == KEY_H then
				net.Start( "AM_VehicleHornStop" )
				net.SendToServer() --Not sure if this the most optimised way to do this
			end
		end
	end
end )