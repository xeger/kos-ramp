@lazyglobal off.
// Usage: Type 'run fly.' in kOS console for piloting planes.
// For shuttle reentry type 'run fly("SHUTTLE").' in console when shuttle is about 20000 and about over the mountains. Your mileage may vary.

parameter KindOfCraft is "Plane". // KindOfCraft valid values are "Plane" and "Shuttle". This changes the way the craft lands.
parameter LandingGear is "Tricycle". // LandingGear valid values are "Tricycle" or "Taildragger". This changes how to handle the plane after touchdown.

runoncepath("lib_ui").
runoncepath("lib_parts").

clearvecdraws().
clearguis().

local OldIPU is config:ipu.
if OldIPU < 500 set config:ipu to 500.

Local consoleinfo is false.
uiDebug("console output is " + consoleinfo).

// Runways coordinates
global RWYKSC is latlng(-0.04807,-74.65).
global RWYKSC_SHUTTLE is latlng(-0.04807,-74.82).
global RWYOAF is latlng(-1.51764918920989,-71.9565681001265).

// Values
local TGTAltitude is 1000.
local TGTBank is 0.
local TGTHeading is 90.
local TGTPitch is 0.
local TGTRunway is RWYKSC.
local TGTSpeed is 150.

////////////////////
// Graphic Interface
////////////////////

// GUI FOR TAKE OFF
if ship:status = "LANDED" {
	local guiTO is GUI(300).
	local labelAutoTakeoff is guiTO:addlabel("<size=20><b>Auto takeoff?</b></size>").
	set labelAutoTakeoff:style:align to "CENTER".
	set labelAutoTakeoff:style:hstretch to true.

	local autoTOYes to guiTO:addbutton("Yes").
	local autoTONo to guiTO:addbutton("No").
	guiTO:show().
	local atdone to false.
	set autoTOYes:onclick to { guiTO:hide. takeoff(). set atdone to true. }.
	set autoTONo:onclick to { guiTO:hide. wait until ship:altitude > 1000. set atdone to true. }.
	wait until atdone.
}

// Waypoint Selection screen
local guiWP is GUI(200).
set guiWP:x to 360.
set guiWP:y to 100.
local labelSelectWaypoint is guiWP:addlabel("<size=20><b>Select waypoint:</b></size>").
set labelSelectWaypoint:style:align to "CENTER".
set labelSelectWaypoint:style:hstretch to true.

local buttonWP01 to guiWP:addbutton("KSC Runway 09").
set buttonWP01:onclick to {
	set TargetCoord to latlng(-0.0483334,-74.724722). // RWY 09
	set TGTAltitude to 1000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "KSC Runway 09".
	guiWP:hide.
}.

local buttonWP02 to guiWP:addbutton("RNAV RWY09 Waypoint 1").
set buttonWP02:onclick to {
	set TargetCoord to latlng(-2,-77.7).
	set TGTAltitude to 2500.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "RNAV RWY09 Waypoint 1".
	guiWP:hide.
}.

local buttonWP03 to guiWP:addbutton("Begin of glideslope").
set buttonWP03:onclick to {
	set TargetCoord to latlng(-0.0483334,-77). // Glideslope
	set TGTAltitude to 4000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "Begin of glideslope".
	guiWP:hide.
}.

local buttonWP04 to guiWP:addbutton("Moutains").
set buttonWP04:onclick to {
	set TargetCoord to latlng(-0.0483334,-79.5). // Mountains
	set TGTAltitude to 8000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "Moutains".
	guiWP:hide.
}.

local buttonWP05 to guiWP:addbutton("Far west").
set buttonWP05:onclick to {
	set TargetCoord to latlng(-0.0483334,-85). // Far west
	set TGTAltitude to 9000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "Far west".
	guiWP:hide.
}.

local buttonWP06 to guiWP:addbutton("Old Airfield").
set buttonWP06:onclick to {
	set TargetCoord to latlng(-1.54084,-71.91). // Far west
	set TGTAltitude to 1500.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "Old Airfield".
	guiWP:hide.
}.

local buttonWP07 to guiWP:addbutton("RNAV Old Airfield Waypoint 1").
set buttonWP07:onclick to {
	set TargetCoord to latlng(-1.3,-74.5).
	set TGTAltitude to 2000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "RNAV Old Airfield Waypoint 1".
	guiWP:hide.
}.

local buttonWP08 to guiWP:addbutton("Baikerbanur").
set buttonWP08:onclick to {
	set TargetCoord to latlng(20.6572,-146.4205).
	set TGTAltitude to 2000.
	set lnavmode to "TGT".
	set LabelWaypoint:text to "Baikerbanur".
	guiWP:hide.
}.

// Main Window
local gui is GUI(300).
set gui:x to 30.
set gui:y to 100.

local labelMode is gui:addlabel("<b>AP Mode</b>").
set labelMode:style:align to "CENTER".
set labelMode:style:hstretch to true.

local baseSelectButtons to gui:addhbox().
local radioButtonKSC to baseSelectButtons:addradiobutton("Space Center", true).
local radioButtonOAF to baseSelectButtons:addradiobutton("Old airfield", false).
local checkboxVectors to baseSelectButtons:addbutton("HoloILS™").
set radioButtonKSC:style:height to 25.
set radioButtonOAF:style:height to 25.
set checkboxVectors:toggle to true.

set baseSelectButtons:onRadioChange to {
	parameter B.

	if B:text = "Space Center" {
		set TGTRunway to RWYKSC.
	}

	if B:text = "Old airfield" {
		set TGTRunway to RWYOAF.
	}
}.

local apbuttons to gui:addhbox().
local ButtonNAV to apbuttons:addbutton("HLD").
local ButtonILS to apbuttons:addbutton("ILS").
local ButtonAPOFF to apbuttons:addbutton("off").

set ButtonNAV:onclick to {
	set apmode to "NAV".
	set vnavmode to "ALT".
	set lnavmode to "HDG".
	set TGTAltitude to round(ship:altitude).
	set TGTHeading to round(MagHeading()).
}.
set ButtonILS:onclick to { set apmode to "ILS". set GSLocked to false. }.
set ButtonAPOFF:onclick to { set apmode to "off". }.

// Autopilot settings
local apsettings to gui:addvbox().

// HDG Settings
local hdgsettings to apsettings:addhlayout().
local ButtonHDG to hdgsettings:addbutton("HDG").
set ButtonHDG:style:width to 40.
set ButtonHDG:style:height to 25.
local ButtonHDGM to hdgsettings:addbutton("◀").
set ButtonHDGM:style:width to 40.
set ButtonHDGM:style:height to 25.
local LabelHDG to hdgsettings:addlabel("").
set LabelHDG:style:height to 25.
set LabelHDG:style:align to "CENTER".
local ButtonHDGP to hdgsettings:addbutton("▶").
set ButtonHDGP:style:width to 40.
set ButtonHDGP:style:height to 25.

set ButtonHDG:onclick to { set lnavmode to "HDG". }.
set ButtonHDGM:onclick to {
	set TGTHeading to ((round(TGTHeading / 5) * 5) -5).
	if TGTHeading < 0 {
		set TGTHeading to TGTHeading + 360.
	}
}.
set ButtonHDGP:onclick to {
	set TGTHeading to ((round(TGTHeading / 5) * 5) + 5).
	if TGTHeading > 360 {
		set TGTHeading to TGTHeading - 360.
	}
}.

// BNK Settings
local bnksettings to apsettings:addhlayout().
local ButtonBNK to bnksettings:addbutton("BNK").
set ButtonBNK:style:width to 40.
set ButtonBNK:style:height to 25.
local ButtonBNKM to bnksettings:addbutton("◀").
set ButtonBNKM:style:width to 40.
set ButtonBNKM:style:height to 25.
local LabelBNK to bnksettings:addlabel("").
set LabelBNK:style:height to 25.
set LabelBNK:style:align to "CENTER".
local ButtonBNKP to bnksettings:addbutton("▶").
set ButtonBNKP:style:width to 40.
set ButtonBNKP:style:height to 25.

set ButtonBNK:onclick to { set lnavmode to "BNK". set TGTBank to BankAngle(). }.
set ButtonBNKM:onclick to { set TGTBank to round(TGTBank) - 1. }.
set ButtonBNKP:onclick to { set TGTBank to round(TGTBank) + 1. }.

// ALT Settings
local altsettings to apsettings:addhlayout().
local ButtonALT to altsettings:addbutton("ALT").
set ButtonALT:style:width to 40.
set ButtonALT:style:height to 25.
local ButtonALTM to altsettings:addbutton("▼").
set ButtonALTM:style:width to 40.
set ButtonALTM:style:height to 25.
local LabelALT to altsettings:addlabel("").
set LabelALT:style:height to 25.
set LabelALT:style:align to "CENTER".
local ButtonALTP to altsettings:addbutton("▲").
set ButtonALTP:style:width to 40.
set ButtonALTP:style:height to 25.

set ButtonALT:onclick to { set vnavmode to "ALT". }.
set ButtonALTM:onclick to { set TGTAltitude to (round(TGTAltitude / 100) * 100) -100 .}.
set ButtonALTP:onclick to { set TGTAltitude to (round(TGTAltitude / 100) * 100) + 100 .}.

// PIT Settings
local pitsettings to apsettings:addhlayout().
local ButtonPIT to pitsettings:addbutton("PIT").
set ButtonPIT:style:width to 40.
set ButtonPIT:style:height to 25.
local ButtonPITM to pitsettings:addbutton("▼").
set ButtonPITM:style:width to 40.
set ButtonPITM:style:height to 25.
local LabelPIT to pitsettings:addlabel("").
set LabelPIT:style:height to 25.
set LabelPIT:style:align to "CENTER".
local ButtonPITP to pitsettings:addbutton("▲").
set ButtonPITP:style:width to 40.
set ButtonPITP:style:height to 25.

set ButtonPIT:onclick to { set vnavmode to "PIT". }.
set ButtonPITM:onclick to { set TGTPitch to round(TGTPitch) -1 .}.
set ButtonPITP:onclick to { set TGTPitch to round(TGTPitch) + 1 .}.

// Waypoints selection
local ButtonWAYPOINTS to apsettings:addbutton("Select waypoint").
local wpsettings to apsettings:addhlayout().
local LabelWaypoint to wpsettings:addlabel("No waypoint selected").
local LabelWaypointDist to wpsettings:addlabel("").
set LabelWaypointDist:style:align to "RIGHT".
set ButtonWAYPOINTS:onclick to { guiWP:show. }.

// Autothrottle
local atbuttons to gui:addhbox().
local ButtonSPD to atbuttons:addbutton("SPD").
local ButtonMCT to atbuttons:addbutton("MCT").
local ButtonATOFF to atbuttons:addbutton("off").

set ButtonSPD:onclick to { set atmode to "SPD". }.
set ButtonMCT:onclick to { set atmode to "MCT". }.
set ButtonATOFF:onclick to { set atmode to "off". }.

local spdctrl to gui:addhbox().
local ButtonSPDM to spdctrl:addbutton("▼").
set ButtonSPDM:style:width to 45.
set ButtonSPDM:style:height to 25.
local LabelSPD to spdctrl:addlabel("").
set LabelSPD:style:height to 25.
set LabelSPD:style:align to "CENTER".
local ButtonSPDP to spdctrl:addbutton("▲").
set ButtonSPDP:style:width to 45.
set ButtonSPDP:style:height to 25.
// Adjust speed.
set ButtonSPDM:onclick to { set TGTSpeed to (round(TGTSpeed / 5) * 5) -5. }.
set ButtonSPDP:onclick to { set TGTSpeed to (round(TGTSpeed / 5) * 5) + 5. }.

local labelAirspeed is gui:addlabel("<b>Airspeed</b>").
set labelAirspeed:style:align to "LEFT".
set labelAirspeed:style:hstretch to true.

local labelVSpeed is gui:addlabel("<b>Vertical speed</b>").
set labelVSpeed:style:align to "LEFT".
set labelVSpeed:style:hstretch to true.

local labelLAT is gui:addlabel("<b>LAT</b>").
set labelLAT:style:align to "LEFT".
set labelLAT:style:hstretch to true.
set labelLAT:style:textcolor to YELLOW.
local labelLNG is gui:addlabel("<b>LNG</b>").
set labelLNG:style:align to "LEFT".
set labelLNG:style:hstretch to true.
set labelLNG:style:textcolor to YELLOW.

local ButtonReboot to gui:addbutton("Reboot").

set ButtonReboot:onclick to {
	gui:hide().
	set ship:control:neutralize to true.
	set ship:control:pilotmainthrottle to 0.
	reboot.
}.

gui:show().

// ABORT!
on abort {
	set APATEnabled to false.
	uiWarning("Fly", "Your controls!!!").
	preserve.
}

// ////////////////
// SET UP PID LOOPS
// ////////////////
// Arguments = Kp, Ki, Kd, MinOutput, MaxOutput

// PID Elevator
local ElevatorPID is pidloop(0.03, 0.003, 0.007,-1, 1).
set ElevatorPID:setpoint to 0.

// PID Pitch Angle
local PitchAnglePID is pidloop(0.04, 0.004, 0.010,-30, 30).
set PitchAnglePID:setpoint to 0.

// PID Aileron
local AileronPID is pidloop(0.004, 0.001, 0.008,-1, 1).
set AileronPID:setpoint to 0.

// PID Yaw Damper
local YawDamperPID is pidloop(0.002, 0.003, 0.008,-1, 1).
set YawDamperPID:setpoint to 0.

// PID BankAngle
local BankAnglePID is pidloop(2, 0.1, 0.3,-33, 33).
set BankAnglePID:setpoint to 0.

// PID Throttle
local ThrottlePID is pidloop(0.01, 0.006, 0.016, 0, 1).
set ThrottlePID:setpoint to 0.

// Control surface variables
local Elevator is 0.
local Aileron is 0.
local Rudder is 0.

// Defauts
local APATEnabled is true.
local apmode is "NAV".
local apshutdown is false.
local atmode is "SPD".
local autothrottle is true.
local CLDist is 0.
local ctrlimit is 1.
local dAlt is 0.
local dHeading is 0.
local flarealt is 150.
local GSAng is 5.
local GSLocked is false.
local HasTermometer is partsHasTermometer().
local lnavmode is "HDG".
local MaxAoA is 20.
local previousap is "".
local previousat is "".
local previouslnav is "".
local previousvnav is "".
local RA is RadarAltimeter().
local ShipStatus is ship:status.
local TargetCoord is RWYKSC.
local TimeOfLanding is 0.
local vnavmode is "ALT".
local valuethrottle is 0.

if KindOfCraft = "Shuttle" {
	set apmode to "ILS".
	set TGTAltitude to 6000.
	set TGTHeading to MagHeading().
	set GSAng to 20.
	set TGTRunway to RWYKSC_SHUTTLE.
	set TargetCoord to TGTRunway.
	set LabelWaypoint:text to "Kerbin Space Center Runway 09".
	set flarealt to 300.
	Set PitchAnglePID:MinOutput to -40.
	uiChime().
} else if KindOfCraft = "Plane" {
	if ship:altitude < 1000 set TGTAltitude to 1000.
	else set TGTAltitude to ship:altitude.
	set TGTHeading to MagHeading().
	set GSAng to 4.
	set TGTRunway to RWYKSC.
	set TargetCoord to TGTRunway.
	set LabelWaypoint:text to "KSC Runway 09".
	set flarealt to 100.
	uiChime().
}

// Holo ILS Variables
local rampend is 0.
local rampendalt is 0.
local ilsvec is 0.


//////////////////////////////////////////////
// Functions to use exclusive with this script
//////////////////////////////////////////////

function Mach {
	parameter SpdMS.
	local AirTemp is 288.15.
	if HasTermometer { set AirTemp to ship:sensors:temp. }.
	return SpdMS / sqrt(1.4 * 286 * AirTemp).
}

function YawError {
	local yaw_error_vec is vxcl(facing:topvector, ship:srfprograde:vector).
	local yaw_error_ang is vang(facing:vector, yaw_error_vec).
	if vdot(ship:facing:starvector, ship:srfprograde:vector) < 0 {
		return yaw_error_ang.
	} else {
		return -yaw_error_ang.
	}

}

function AoA {
	local pitch_error_vec is vxcl(facing:starvector, ship:srfprograde:vector).
	local pitch_error_ang is vang(facing:vector, pitch_error_vec).
	if vdot(ship:facing:topvector, ship:srfprograde:vector) < 0 {
		return pitch_error_ang.
	} else {
		return -pitch_error_ang.
	}

}

function BankAngle {
	local starBoardRotation to ship:facing * R(0, 90, 0).
	local starVec to starBoardRotation:vector.
	local horizonVec to vcrs(ship:up:vector, ship:facing:vector).

	if vdot(ship:up:vector, starVec) < 0{
		return vang(starVec, horizonVec).
	} else {
		return -vang(starVec, horizonVec).
	}
}

function PitchAngle {
	return -(vang(ship:up:vector, ship:facing:forevector) - 90).
}

function ProgradePitchAngle {
	return -(vang(ship:up:vector, vxcl(ship:facing:starvector, ship:velocity:surface)) - 90).
}

function MagHeading {
	local northPole to latlng(90, 0).
	return mod(360 - northPole:bearing, 360).
}

function CompassDegrees {
	parameter degrees.
	return mod(360 - degrees, 360).
}

function RadarAltimeter {
	return ship:altitude - ship:geoposition:terrainheight.
}

function DeltaHeading {
	parameter tHeading.
	// Heading Control
	local val to tHeading - magheading().
	if val > 180 {
		set val to val - 360.
	} else if val < -180 {
		set val to val + 360.
	}
	return val.
}

function GroundDistance {
	// Returns distance to a point in ground from the ship's ground position (ignores altitude)
	parameter TgtPos.
	return vxcl(up:vector, TgtPos:position):mag.
}

function Glideslope{
	// Returns the altitude of the glideslope
	parameter Threshold.
	parameter GSAngle is 5.
	parameter Offset is 20.
	local KerbinAngle is abs(ship:geoposition:lng) - abs(Threshold:lng).
	local Correction is sqrt( (kerbin:radius ^ 2) + (tan(KerbinAngle) * kerbin:radius) ^ 2 ) - kerbin:radius. // Why this correction? https://imgur.com/a/CPHnD
	return (tan(GSAngle) * GroundDistance(Threshold)) + Threshold:terrainheight + Correction + Offset.
}

function CenterLineDistance {
	// Returns the ground distance of the centerline
	parameter Threshold.
	local Marker is latlng(Threshold:lat, ship:geoposition:lng).
	if ship:geoposition:lat > Threshold:lat {
		return GroundDistance(Marker).
	} else {
		return -GroundDistance(Marker).
	}
}

function TakeOff {
	local LandedAlt is ship:altitude.
	sas off.
	brakes off.
	lights on.
	stage.
	set ship:control:pilotmainthrottle to 1.
	wait until ship:airspeed > 50.
	set ship:control:pitch to 0.5.
	wait until ship:altitude > LandedAlt + 50.
	set ship:control:pitch to 0.
	sas on.
	gear off.
	lights off.
	wait until ship:altitude > LandedAlt + 600.
	set ship:control:pilotmainthrottle to 0.
}


// *********
// MAIN LOOP
// *********

partsDisarmsChutes(). // We don't want any chute deploing while flying, right?
local AirSPD is ship:airspeed.
local TimeNow is time:seconds.
local BaroAltitude is ship:altitude.
local SafeToExit is false.

until SafeToExit {

	// Make sure cooked controls are off before engaging autopilot
	SAS off.
	set RCS to ship:altitude > 18000.
	partsDisableReactionWheels().
	unlock steering.
	unlock throttle.
	set TimeOfLanding to 0.

	until ShipStatus = "LANDED" or ShipStatus = "SPLASHED" {
		wait 0. // Skip a physics tick

		set AirSPD to ship:airspeed.
		set TimeNow to time:seconds.
		set BaroAltitude to ship:altitude.
		set RA to RadarAltimeter().

		if APATEnabled {
			if SAS { SAS off. }

			// ********
			// ILS MODE
			// ********

			else if apmode = "ILS" {
				set TargetCoord to TGTRunway.
				// Checks if below GS
				set TGTAltitude to Glideslope(TGTRunway, GSAng).
				if (not GSLocked) and (BaroAltitude < TGTAltitude) {
					if KindOfCraft = "SHUTTLE" {
						set TGTPitch to -GSAng / 4.
						set vnavmode to "PIT".
					} else {
						set TGTAltitude to (BaroAltitude + TGTAltitude) / 2.
						set vnavmode to "ALT".
					}
				} else {
					set vnavmode to "ALT".
					GSLocked on.
				}

				// Checks distance from centerline
				local GDist to GroundDistance(TargetCoord).
				local AllowedDeviation is GDist * sin(0.5).
				set CLDist to CenterLineDistance(TGTRunway).
				if abs(CLDist) < AllowedDeviation set TGTHeading to 90.
				else if abs(CLDist) < GDist / 3 set TGTHeading to abs(90 + arcsin(CLDist / (GDist / 3))).
				else set TGTHeading to 90 + ((CLDist / abs(CLDist)) * 90). // 0 or 180 heading, depending if ship is north or south of runway.
				set lnavmode to "HDG".

				// Checks for excessive airspeed on final.
				if KindOfCraft = "Plane" {
					set TGTSpeed to min(180, max(sqrt(TGTAltitude) * 4, 90)).
					if atmode <> "off" {
						set atmode to "SPD".
					}
					if AirSPD > TGTSpeed * 1.01 and ship:control:pilotmainthrottle < 0.1 brakes on.
					else if AirSPD < TGTSpeed or ship:control:pilotmainthrottle > 0.4 brakes off.
				} else if KindOfCraft = "Shuttle" {
					set TGTSpeed to max(sqrt(TGTAltitude) * 10, 100).
					set atmode to "off".
					set brakes to AirSPD > TGTSpeed.
				}
			}
			// **********
			// FLARE MODE
			// **********
			else if apmode = "FLR" {
				// Configure Flare mode
				if vnavmode <> "PIT" {
					set vnavmode to "PIT".
					set TGTHeading to 90.
					PitchAnglePID:reset.
					set ElevatorPID:kp to ElevatorPID:kp * 2.
					set ElevatorPID:ki to ElevatorPID:ki / 4.
					set ElevatorPID:kd to ElevatorPID:kd * 2.
					set ship:control:pilotmainthrottle to 0.
					set atmode to "off".
				}
				// Adjust craft flight
				if RA > 20 {
					set TGTPitch to PitchAnglePID:update(TimeNow, ship:verticalspeed + 3).
					if AirSPD > 80 {
						if not BRAKES { BRAKES on. }
					} else {
						if BRAKES {BRAKES off.}
					}
				} else {
					set TGTPitch to 5.
					if BRAKES {BRAKES off.}
					set lnavmode to "BNK".
					set TGTBank to 0.
				}

			}

			// **************************
			// MANUAL MODE WITH AUTO TRIM
			// **************************

			else if apmode = "off" {
				if ship:control:pilotpitch <> 0 {
					set Elevator to ship:control:pilotpitch.
					set ElevatorPID:setpoint to PitchAngle().
				} else {
					set ship:control:pitchtrim to ElevatorPID:update(TimeNow, PitchAngle() ).
					set Elevator to 0.
				}
				if ship:control:pilotyaw <> 0 {
					set Aileron to ship:control:pilotyaw.
					set AileronPID:setpoint to min(40, max(-40, BankAngle() )).
				} else {
					set ship:control:rolltrim to AileronPID:update(TimeNow, BankAngle()).
					set Aileron to 0.
				}
			}

			// *********************
			// COMMON AUTOPILOT CODE
			// *********************

			// DEAL WITH LNAV
			if apmode <> "off" {
				if lnavmode = "TGT" {
					set dHeading to -TargetCoord:bearing.
					set AileronPID:setpoint to BankAnglePID:update(TimeNow, dHeading).
				} else if lnavmode = "HDG" {
					set dHeading to -DeltaHeading(TGTHeading).
					set AileronPID:setpoint to BankAnglePID:update(TimeNow, dHeading).
				} else if lnavmode = "BNK" {
					set AileronPID:setpoint to min(45, max(-45, TGTBank)).
				}

				set Aileron to AileronPID:update(TimeNow, BankAngle()).

				// DEAL WITH VNAV

				if vnavmode = "ALT" {
					set dAlt to BaroAltitude - TGTAltitude.
					set ElevatorPID:setpoint to PitchAnglePID:update(TimeNow, dAlt).
				} else if vnavmode = "PIT" {
					set ElevatorPID:setpoint to TGTPitch.
				} else if vnavmode = "SPU" {
					set ElevatorPID:setpoint to ProgradePitchAngle().
				}
				set Elevator to ElevatorPID:update(TimeNow, PitchAngle() ).

				// RESET TRIM
				set ship:control:rolltrim to 0.
				set ship:control:pitchtrim to 0.

			}
			// Stall Protection (Stick pusher!)
			if KindOfCraft = "PLANE" {
				if AoA() > MaxAoA {
					if vnavmode <> "SPU" {
						set previousvnav to vnavmode.
						set previouslnav to lnavmode.
						set previousat to atmode.
						set previousap to apmode.
						set apmode to "NAV".
						set vnavmode to "SPU".
						set atmode to "MCT".
						set lnavmode to "SPU".
						uiAlarm().
					}
					uiWarning("Fly", "Stick pusher!").
				} else {
					if vnavmode = "SPU" {
						set vnavmode to previousvnav.
						set lnavmode to previouslnav.
						set atmode to previousat.
						set apmode to previousap.
					}
				}
			}

			if KindOfCraft = "SHUTTLE" {
				set ctrlimit to min(1, round(300 / AirSPD, 2)).
				set RCS to BaroAltitude > 15000.
			} else {
				set ctrlimit to min(1, round(120 / AirSPD, 2)).
			}

			// Ease controls in high speeds
			if ElevatorPID:maxoutput <> min(1, ctrlimit * 1.5) .{
				set ElevatorPID:maxoutput to min(1, ctrlimit * 1.5) .
				set ElevatorPID:minoutput to max (-1,-ctrlimit * 1.5) .
			}
			if AileronPID:maxoutput <> ctrlimit. {
				set AileronPID:maxoutput to ctrlimit.
				set AileronPID:minoutput to -ctrlimit.
			}

			// Yaw Damper
			if YawDamperPID:maxoutput <> ctrlimit * 0.75 .{
				set YawDamperPID:maxoutput to ctrlimit * 0.75.
				set YawDamperPID:minoutput to -ctrlimit * 0.75.
			}
			set Rudder to YawDamperPID:update(TimeNow, YawError()).
			set ship:control:yaw to Rudder.

			// APPLY CONTROLS
			set ship:control:roll to min(ctrlimit, max(-ctrlimit, Aileron)).
			set ship:control:pitch to min(ctrlimit, max(-ctrlimit, Elevator)).

			// ************
			// AUTOTHROTTLE
			// ************

			if atmode = "SPD" {
				if not autothrottle { set autothrottle to true .}
				set valuethrottle to ThrottlePID:update(TimeNow, AirSPD - TGTSpeed).
				set ship:control:pilotmainthrottle to valuethrottle.
			} else if atmode = "MCT" {
				if not autothrottle { set autothrottle to true .}
				set ship:control:pilotmainthrottle to 1.
			} else if atmode = "off" {
				if autothrottle {
					unlock throttle.
					set ship:control:pilotmainthrottle to 0.
					set autothrottle to false.
				}
			}

			// ******************
			// COMMON FLIGHT CODE
			// ******************

			// Auto raise/low gear and detect time to flare when landing.
			if RA < flarealt * 2 {
				if not GEAR { GEAR on .}
				if not LIGHTS { LIGHTS on. }
				// CHANGE TO FLARE MODE.
				if apmode = "ILS" and BaroAltitude - TargetCoord:terrainheight < flarealt {
					set apmode to "FLR".
				}
			} else {
				if GEAR GEAR off.
			}

		} else {
			// *****************************************
			// TOTAL AUTOPILOT SHUTDOWN. SHOW INFO ONLY.
			// *****************************************
			if not apshutdown {
				set ship:control:neutralize to true.
				unlock throttle.
				set ship:control:pilotmainthrottle to 0.
				if not SAS {SAS on.}
				set apshutdown to true.
			}
		}


		// *********************
		// USER INTERFACE UPDATE
		// *********************

		wait 0.
		// ILS VECTORS
		if checkboxVectors:pressed {
			set rampend to latlng(TGTRunway:lat, TGTRunway:lng - 10).
			set rampendalt to TGTRunway:terrainheight + tan(GSAng) * 10 * (kerbin:radius * 2 * constant:pi / 360).
			set ilsvec to vecdraw(TGTRunway:position(), rampend:altitudeposition(rampendalt+ 9256), magenta, "", 1, true, 30).
			// Why +9256? https://imgur.com/a/CPHnD
		} else {
			set ilsvec to vecdraw().
			print "                            " at (0, 30).
		}

		// GUI ELEMENTS

		if apshutdown {
			set labelMode:text to "<b><size=17>INP | INP | INP | INP</size></b>".
			set LabelWaypointDist:text to "".
			set LabelHDG:text to "".
			set LabelALT:text to "".
			set LabelBNK:text to "".
			set LabelPIT:text to "".
			set LabelSPD:text to "".
		} else {
			set labelMode:text to "<b><size=17>" + apmode + " | " + vnavmode + " | " + lnavmode + " | " + atmode + "</size></b>".
			set LabelWaypointDist:text to round(GroundDistance(TargetCoord) / 1000, 1) + " km".
			set LabelHDG:text to "<b>" + round(TGTHeading, 2):tostring + "º</b>".
			set LabelALT:text to "<b>" + round(TGTAltitude, 2):tostring + " m</b>".
			set LabelBNK:text to "<b>" + round(AileronPID:setpoint, 2) + "º</b>".
			set LabelPIT:text to "<b>" + round(ElevatorPID:setpoint, 2) + "º</b>".
			set LabelSPD:text to "<b>" + round(TGTSpeed) + " m/s | " + round(uiMSTOKMH(TGTSpeed), 2) + " km/h</b>".
		}
		set labelAirspeed:text to "<b>Airspeed:</b> " + round(uiMSTOKMH(AirSPD)) + " km/h" + " | Mach " + Round(Mach(AirSPD), 3).
		set labelVSpeed:text to "<b>Vertical speed:</b> " + round(ship:verticalspeed) + " m/s".
		set labelLAT:text to "<b>LAT:</b> " + round(ship:geoposition:lat, 4) + " º".
		set labelLNG:text to "<b>LNG:</b> " + round(ship:geoposition:lng, 4) + " º".

		// CONSOLE INFO
		if consoleinfo {
			print "MODE:" + lnavmode at (0, 0). print "YWD ERR:" + round(YawError(), 2) + "    " at (20, 0).
			if APATEnabled {print apmode + "   " at (10, 0).} else {print "MANUAL" at (10, 0).}
			print "Pitch angle         " + round(PitchAngle(), 2) +          "       "at (0, 1).
			print "Target pitch:       " + round(ElevatorPID:setpoint, 2) +  "       " At (0, 2).
			print "AoA:                " + round(AoA(), 2) +                 "       " At (0, 3).

			print "Bank angle          " + round(BankAngle(), 2)          +  "     " at (0, 6).
			print "Target bank:        " + round(AileronPID:setpoint, 2)  +  "     " At (0, 7).
			print "Target bearing:     " + round(-dHeading, 2)             +  "     " At (0, 8).

			print "Ship: Latitude:     " + ship:geoposition:lat at (0, 10).
			print "Ship: Longitude:    " + ship:geoposition:lng at (0, 11).
			print "Ship: Altitude:     " + BaroAltitude at (0, 12).
			print "GS Altitude: " + round(Glideslope(TGTRunway, GSAng), 2) at (0, 30).
		}
		wait 0. // Next loop only in next physics tick
		set ShipStatus to ship:status.
	}

	// Takes care of ship after autopilot ends it's work.
	local SteerDir is heading(90, 0).

	until ship:status <> "LANDED" or SafeToExit {
		if TimeOfLanding = 0 {
			// Set up ship for runway roll
			set TimeOfLanding to time:seconds.
			uiBanner("Fly", "Landed!").
			// Neutralize RAW controls
			set ship:control:neutralize to true.
			set ship:control:pilotmainthrottle to 0.
			// Try to keep the ship on ground
			partsEnableReactionWheels().
			if LandingGear = "Tricycle" { // With tricycle landing gear is safe to pitch down while on ground. This helps prevents bounces and improve braking.
				set SteerDir to heading(90,-1).
			} else if LandingGear = "Taildragger" { // With taildraggers is better to keep the nose a little up to avoid a nose-over accident.
				set SteerDir to heading(90, 0.5).
			}
			lock steering to SteerDir.
		} else if time:seconds > TimeOfLanding + 3 {
			uiBanner("Fly", "Braking!").
			// We didn't bounce, apply brakes
			brakes on.
			chutes on.
			if partsReverseThrust() set ship:control:pilotmainthrottle to 1.
			if ship:groundspeed < 30 set ship:control:pilotmainthrottle to 0.
			// Don't let tail-dragger to nose-over when braking
			if LandingGear = "Taildragger" and PitchAngle() < 0 brakes off.
			// Now it's really safe to exit the autopilot.
			if ship:groundspeed < 1 SafeToExit on.
		}
		wait 0.
	}

	if ship:status = "splashed" {
		SafeToExit on.
		uiBanner("Fly", "Splash!!!").
	}
}

clearguis().
clearvecdraws().
BRAKES on.
SAS on.
set config:ipu to OldIPU.
partsEnableReactionWheels().
partsForwardThrust().
uiBanner("Fly", "Thanks to flying with RAMP. Remember to take your belongings.", 2).
