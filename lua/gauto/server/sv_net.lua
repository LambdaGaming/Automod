util.AddNetworkString( "GAuto_VehicleLock" )
function GAuto.VehicleLock( len, ply )
	if IsFirstTimePredicted() then
		local veh = ply:GetVehicle()
		local canLock = hook.Run( "GAuto_CanLockDoors", ply, veh )
		if GAuto.IsBlackListed( veh ) or canLock == false then return end
		if !veh:GetNWBool( "GAuto_DoorsLocked" ) then
			GAuto.Notify( ply, "Vehicle locked." )
			veh:Fire( "Lock", "", 0.01 )
			veh:SetNWBool( "GAuto_DoorsLocked", true )
			veh:SetNWEntity( "GAuto_LockOwner", ply )
		else
			GAuto.Notify( ply, "Vehicle unlocked." )
			veh:Fire( "Unlock", "", 0.01 )
			veh:SetNWBool( "GAuto_DoorsLocked", false )
		end
	end
end
net.Receive( "GAuto_VehicleLock", GAuto.VehicleLock )

util.AddNetworkString( "GAuto_VehicleHorn" )
function GAuto.VehicleHorn( len, ply )
	local GAuto_HornEnabled = GetConVar( "gauto_horn_enabled" ):GetBool()
	if GAuto_HornEnabled then
		local veh = ply:GetVehicle()
		local canHorn = hook.Run( "GAuto_CanUseHorn", ply, veh )
		if GAuto.IsBlackListed( veh ) or canHorn == false then return end
		veh.GAuto_CarHorn = CreateSound( veh, veh:GetNWString( "GAuto_HornSound" ) )
		if !veh.GAuto_CarHorn:IsPlaying() then
			veh.GAuto_CarHorn:Play()
		end
	end
end
net.Receive( "GAuto_VehicleHorn", GAuto.VehicleHorn )

util.AddNetworkString( "GAuto_VehicleHornStop" )
function GAuto.VehicleHornStop( len, ply )
	local veh = ply:GetVehicle()
	if !IsValid( veh ) or !veh.GAuto_CarHorn then return end
	if veh.GAuto_CarHorn:IsPlaying() then veh.GAuto_CarHorn:Stop() end
end
net.Receive( "GAuto_VehicleHornStop", GAuto.VehicleHornStop )

util.AddNetworkString( "GAuto_CruiseControl" )
function GAuto.CruiseControl( len, ply )
	local GAuto_CruiseEnabled = GetConVar( "gauto_cruise_enabled" ):GetBool()
	if GAuto_CruiseEnabled then
		local veh = ply:GetVehicle()
		local canCruise = hook.Run( "GAuto_CanCruise", ply, veh )
		if GAuto.IsBlackListed( veh ) or !veh:IsEngineStarted() or canCruise == false then return end
		local cruiseactive = veh:GetNWBool( "CruiseActive" )
		if cruiseactive then
			veh:SetNWBool( "CruiseActive", false )
			GAuto.Notify( ply, "Cruise control is now disabled." )
			return
		end
		veh:SetNWBool( "CruiseActive", true )
		GAuto.Notify( ply, "Cruise control is now enabled. Press forward/backward to increase/decrease cruise speed." )
		veh:SetNWInt( "CruiseSpeed", 0.05 )
	end
end
net.Receive( "GAuto_CruiseControl", GAuto.CruiseControl )

util.AddNetworkString( "GAuto_ChangeSeats" )
function GAuto.ChangeSeats( len, ply, seat )
	local key = seat or net.ReadInt( 32 )
	local veh = ply:GetVehicle()
	if GAuto.IsBlackListed( veh ) then return end
	local vehparent = veh:GetParent()
	local realseat = key - 1 --Need to subtract 1 since the driver's seat doesn't count as a passenger seat
	local canChange = hook.Run( "GAuto_CanChangeSeats", ply, veh, seat )
	if canChange == false then return end
	if GAuto.IsDrivable( veh ) then
		if key == 1 then
			GAuto.Notify( ply, "You are already sitting in the selected seat." )
			return
		else
			if veh.seat and IsValid( veh.seat[realseat] ) then
				if !IsValid( veh.seat[realseat]:GetDriver() ) then
					ply.IsSwitching = true --Fix for players getting kicked out while the seat cooldown is in effect
					ply:EnterVehicle( veh.seat[realseat] )
					ply:SetEyeAngles( Angle( veh.seat[realseat]:GetAngles():Normalize() ) + Angle( 0, 90, 0 ) ) --Fix for the seats setting random eye angles
					ply.IsSwitching = nil
				else
					GAuto.Notify( ply, "Selected seat is already taken." )
					return
				end
			else
				GAuto.Notify( ply, "Selected seat doesn't exist." )
				return
			end
		end
	else
		if !IsValid( vehparent ) then return end
		if key == 1 then
			if !IsValid( vehparent:GetDriver() ) then
				ply.IsSwitching = true
				ply:EnterVehicle( vehparent )
				ply:SetEyeAngles( Angle( vehparent:GetAngles():Normalize() ) + Angle( 0, 90, 0 ) )
				ply.IsSwitching = nil
				return
			else
				GAuto.Notify( ply, "Selected seat is already taken." )
				return
			end
		end
		if vehparent.seat[realseat] == veh then
			GAuto.Notify( ply, "You are already sitting in the selected seat." )
			return
		end
		if IsValid( vehparent ) and vehparent.seat and IsValid( vehparent.seat[realseat] ) then	
			if !IsValid( vehparent.seat[realseat]:GetDriver() ) then
				ply.IsSwitching = true
				ply:EnterVehicle( vehparent.seat[realseat] )
				ply:SetEyeAngles( Angle( vehparent.seat[realseat]:GetAngles():Normalize() ) + Angle( 0, 90, 0 ) )
				ply.IsSwitching = nil
			else
				GAuto.Notify( ply, "Selected seat is already taken." )
				return
			end
		else
			GAuto.Notify( ply, "Selected seat doesn't exist." )
			return
		end
	end
end
net.Receive( "GAuto_ChangeSeats", GAuto.ChangeSeats )

util.AddNetworkString( "GAuto_EjectPassenger" )
function GAuto.EjectPassenger( len, ply, seat )
	local key = seat or net.ReadInt( 32 )
	local veh = ply:GetVehicle()
	local realseat = key - 1
	local canEject = hook.Run( "GAuto_CanEjectPassenger", ply, veh, seat )
	if GAuto.IsBlackListed( veh ) or !GAuto.IsDrivable( veh ) or canEject == false then return end
	if veh.seat and IsValid( veh.seat[realseat] ) then
		local passenger = veh.seat[realseat]:GetDriver()
		if IsValid( passenger ) then
			local nick = ply:Nick()
			local passengernick = passenger:Nick()
			passenger:ExitVehicle()
			GAuto.Notify( ply, "Ejected "..passengernick.." from the vehicle." )
			GAuto.Notify( passenger, "You have been ejected from the vehicle by "..nick.."." )
		else
			GAuto.Notify( ply, "Selected seat doesn't have a passenger to eject." )
		end
	else
		GAuto.Notify( ply, "Select seat doesn't exist." )
	end
end
net.Receive( "GAuto_EjectPassenger", GAuto.EjectPassenger )

util.AddNetworkString( "GAuto_EngineToggle" )
function GAuto.EngineToggle( len, ply )
	if ply:InVehicle() then
		local veh = ply:GetVehicle()
		local GAuto_HealthEnabled = GetConVar( "gauto_health_enabled" ):GetBool()
		local GAuto_FuelEnabled = GetConVar( "gauto_fuel_enabled" ):GetBool()
		local canToggle = hook.Run( "GAuto_CanToggleEngine", ply, veh )
		if GAuto.IsBlackListed( veh ) or canToggle == false then return end
		if GAuto_HealthEnabled and veh:GetNWInt( "GAuto_VehicleHealth" ) <= 0 then return end --Don't want players turning the car back on when it's destroyed or out of fuel
		if GAuto_FuelEnabled and veh:GetNWInt( "GAuto_FuelAmount" ) <= 0 then return end
		veh:StartEngine( !veh:IsEngineStarted() )
	end
end
net.Receive( "GAuto_EngineToggle", GAuto.EngineToggle )
