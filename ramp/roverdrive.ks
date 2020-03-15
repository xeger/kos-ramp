@lazyglobal off.

// rover.ks
// Written by KK4TEE
// License: GPLv3
//
// This program provides stability assistance
// for manually driven rovers

// GUI, Stability control and other improvements by FellipeC 2017

parameter speedlimit is 39. // Speedlimit. Default is 39 m/s, almost 88mph ;)
parameter turnfactor is 5. // Factor to reduce steering with speed..


runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_parts").
runoncepath("lib_terrain").
runoncepath("lib_rover").

local wtVAL is 0. // Wheel Throttle Value
local kTurn is 0. // Wheel turn value.
local targetspeed is 0. // Cruise control starting speed
local targetHeading is 90. // Used for autopilot steering
local CruiseControl is false. // Enable/Disable Cruise control
local lastGUIUpdate is 0.
local GUIUpdateInterval is 0.25.
local runmode is 0.
local cHeading is 0. // Compass heading
local gs is ship:groundspeed.
local errorSteering is 0.
local turnlimit is 0.

// Route maker
local Route is list().
Function AddWaypoint {
	local waypointlex is lexicon("lat", ship:geoposition:lat, "lng", ship:geoposition:lng).
	Route:add(waypointlex).
	uiBanner("Route", "Waypoint added: " + Route[Route:length - 1]).
}

Function RmvWaypoint {
	if Route:empty() uiBanner("Route", "There are no more waypoints").
	else {
		Route:remove(Route:length - 1).
		uiBanner("Route", "Last waypoint removed.").
	}
}

Function SaveRoute {
	if HomeConnection:IsConnected {
		WriteJSON(Route, "0:/routes/" + TextFieldRouteName:text()+ ".json").
		uiBanner("Route", "Route saved!", 2).
	} else uiError("Route", "There is no connection to KSC servers. Raise antennas and try again.").
}




// Create a GUI window
local gui is GUI(250).
set gui:x to 30.
set gui:y to 100.

local labelName is gui:addlabel("<b><i><size=14>" + ship:name + "</size></i></b>").
set labelName:style:align to "CENTER".
set labelName:style:hstretch to true.
set labelName:style:textcolor to Yellow.

local labelMode is gui:addlabel("").
set labelMode:style:align to "CENTER".
set labelMode:style:hstretch to true.

local apbuttons to gui:addhbox().
local ButtonCC to apbuttons:addbutton("Cruise").
local ButtonMD to apbuttons:addbutton("Assist").
local ButtonMC to apbuttons:addbutton("Manual").

set ButtonCC:onclick to { set CruiseControl to true. }.
set ButtonMD:onclick to { set CruiseControl to false. }.
set ButtonMC:onclick to { set runmode to 1. }.


local apsettings to gui:addvlayout().
// HDG Settings
local labelHDGTitle is apsettings:addlabel("<b><size=15>Desired Heading</size></b>").
set labelHDGTitle:style:align to "CENTER".
set labelHDGTitle:style:hstretch to true.
local hdgsettings to apsettings:addhbox().
local ButtonHDGM to hdgsettings:addbutton("◀").
set ButtonHDGM:style:width to 40.
set ButtonHDGM:style:height to 25.
local LabelHDG to hdgsettings:addlabel("").
set LabelHDG:style:height to 25.
set LabelHDG:style:align to "CENTER".
local ButtonHDGP to hdgsettings:addbutton("▶").
set ButtonHDGP:style:width to 40.
set ButtonHDGP:style:height to 25.

local SteeringSteep is 5.

set ButtonHDGM:onclick to {
	set targetheading to ((round(targetheading / SteeringSteep) * SteeringSteep) -SteeringSteep).
	if targetheading < 0 {
		set targetheading to targetheading + 360.
	}
}.
set ButtonHDGP:onclick to {
	set targetheading to ((round(targetheading / SteeringSteep) * SteeringSteep) +SteeringSteep).
	if targetheading > 360 {
		set targetheading to targetheading - 360.
	}
}.

// SPEED Settings
local labelSPDTitle is apsettings:addlabel("<b><size=15>Desired Speed</size></b>").
set labelSPDTitle:style:align to "CENTER".
set labelSPDTitle:style:hstretch to true.
local SPDsettings to apsettings:addhbox().
local ButtonSPDM to SPDsettings:addbutton("▼").
set ButtonSPDM:style:width to 40.
set ButtonSPDM:style:height to 25.
local LabelSPD to SPDsettings:addlabel("").
set LabelSPD:style:height to 25.
set LabelSPD:style:align to "CENTER".
local ButtonSPDP to SPDsettings:addbutton("▲").
set ButtonSPDP:style:width to 40.
set ButtonSPDP:style:height to 25.

set ButtonSPDM:onclick to {
	set targetspeed to round(targetspeed) -3.
}.
set ButtonSPDP:onclick to {
	set targetspeed to round(targetspeed) +3.
}.

// Dashboard
local dashboard to gui:addhbox().
local DashLeft to dashboard:addvlayout().
local LabelDashSpeed to DashLeft:addlabel("").
set LabelDashSpeed:style:align to "LEFT".
set LabelDashSpeed:style:hstretch to true.
set LabelDashSpeed:style:textcolor to Yellow.
local LabelDashEC to DashLeft:addlabel("").
set LabelDashEC:style:align to "LEFT".
set LabelDashEC:style:hstretch to true.
set LabelDashEC:style:textcolor to Yellow.
local LabelDashLFO to DashLeft:addlabel("").
set LabelDashLFO:style:align to "LEFT".
set LabelDashLFO:style:hstretch to true.
set LabelDashLFO:style:textcolor to Yellow.


local SliderSteering to DashLeft:addhslider(0, 1,-1).
local LabelControls to DashLeft:addlabel("<color=#aaaaaa88>▲ Steering | Throttle ▶</color>").
set LabelControls:style:align to "RIGHT".
set LabelControls:style:hstretch to true.
local SliderThrottle to dashboard:addvslider(0, 1,-1).

local RouteMaker is gui:AddVBox().
local rmButtons is RouteMaker:AddHLayout().
local ButtonAddWPT is rmButtons:AddButton("+ Waypoint").
local ButtonRmvWPT is rmButtons:AddButton("- Waypoint").
local ButtonSaveRoute is rmButtons:AddButton("Save Route").
local TextFieldRouteName is RouteMaker:AddTextField("Route name").

Set ButtonAddWPT:onclick to AddWaypoint@.
Set ButtonRmvWPT:onclick to RmvWaypoint@.
Set ButtonSaveRoute:onclick To SaveRoute@.

on AG1 { AddWaypoint(). Preserve. }

local ButtonStop to gui:addbutton("Stop script").
set ButtonStop:onclick to { set runmode to -1 . wait 0.}.

local ok to gui:addbutton("Reboot kOS").
set ok:onclick to {
	gui:hide().
	set ship:control:neutralize to true.
	set ship:control:pilotmainthrottle to 0.
	reboot.
}.
gui:show().


///////////////
// Main program
///////////////

wait until kuniverse:activevessel = ship.

// Reset controls
set ship:control:neutralize to true.
set ship:control:pilotmainthrottle to 0.
sas off.
rcs off.
lights on.
fuelcells on.
partsDisableReactionWheels().
partsExtendAntennas().

// Check if rover is in a good state to be controlled.
if ship:status = "PRELAUNCH" {
	set labelMode:text to "<size=16><color=yellow>Waiting launch...</color></size>".
	wait until ship:status <> "PRELAUNCH".
} else if ship:status <> "LANDED" {
	set runmode to -1.
}

local WThrottlePID to pidloop(0.15, 0.005, 0.020, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WThrottlePID:setpoint to 0.

local WSteeringPID to pidloop(0.005, 0.0001, 0.001, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WSteeringPID:setpoint to 0.

until runmode = -1 {
	// Update the compass:
	// I want the heading to match the navball
	// and be out of 360' instead of +/-180'
	// I do this by judging the heading relative
	// to a latlng set to the north pole
	set cHeading to utilCompassHeading().
	local N is TerrainNormalVector().
	set turnlimit to min(1, turnfactor / abs(gs)). // Scale the turning radius based on current speed

	if runmode = 0 { // Govern the rover

		// Wheel Throttle:
		set targetspeed to targetspeed + 0.1 * ship:control:pilotwheelthrottle.
		set targetspeed to max(-speedlimit / 3, min( speedlimit, targetspeed)).
		set gs to vdot(ship:facing:vector, ship:velocity:surface).
		set wtVAL to WThrottlePID:update(time:seconds, gs - targetspeed).

		if brakes { // Disable cruise control if the brakes are turned on.
			set targetspeed to 0.
		}

		// Steering:
		if CruiseControl { // Activate autopilot
			set errorSteering to utilHeadingToBearing(targetheading - cHeading).
			if gs < 0 set errorSteering to -errorSteering.
			set WSteeringPID:MaxOutput to 1 * turnlimit.
			set WSteeringPID:MinOutput to -1 * turnlimit.
			set kturn to WSteeringPID:update(time:seconds, errorSteering).
		} else {
			set kturn to turnlimit * ship:control:pilotwheelsteer.
			set targetHeading to cheading.
		}
		// Detect jumps and engage stability control
		if ship:status <> "LANDED" {
			if roverStabilzeJump(N) {
				uiBanner("Rover", "Wow, that was a long jump!").
				set targetspeed to targetspeed * 0.75.
			}
		}
		// Detect rollover
		if roverIsRollingOver(N) {
			set turnfactor to max(1, turnfactor * 0.9). // Reduce turnfactor
			roverStabilzeJump(N). // Engage Stability control
		}
	} else if runmode = 1 { // Stock driving mode
		set wtVAL to ship:control:pilotwheelthrottle * 0.5.
		set kturn to ship:control:pilotwheelsteer.
		if abs(ship:groundspeed) > speedlimit * 0.3 {
			set runmode to 0.
			brakes on.
		}
	}

	// Here it really control the rover.
	set wtVAL to min(1, (max(-1, wtVAL))).
	set kTurn to min(1, (max(-1, kTurn))).
	set ship:control:wheelthrottle to wtval.
	set ship:control:wheelsteer to kTurn.

	// Update the GUI
	if time:seconds > lastGUIUpdate + GUIUpdateInterval {
		set lastGUIUpdate to time:seconds.
		if runmode = 0 {
			if CruiseControl {
				set labelMode:text to "<b><size=17>Cruise Control</size></b>".
			} else {
				set labelMode:text to "<b><size=17>Assisted Drive</size></b>".
			}
			set LabelHDG:text to "<b>" + round( targetheading, 2) + "º</b>".
			set LabelSPD:text to "<b>" + round( targetspeed, 1) + " m/s | " + round (uiMSTOKMH(targetspeed), 1) + " km/h</b>".
		} else if runmode = 1 {
			set labelMode:text to "<b><size=17>Manual Control</size></b>".
			set LabelHDG:text to "<b>-º</b>".
			set LabelSPD:text to "<b>- m/s | - km/h</b>".
		} else if runmode = 2 {
			set labelMode:text to "<b><size=17>Stability Control</size></b>".
			set LabelHDG:text to "<b>" + round( targetheading, 2) + "º</b>".
			set LabelSPD:text to "<b>" + round( targetspeed, 1) + " m/s | " + round (uiMSTOKMH(targetspeed), 1) + " km/h</b>".
		}
		set LabelDashSpeed:text to "<b>Speed: </b>" + round( gs, 1) + " m/s | " + round (uiMSTOKMH(gs), 1) + " km/h".

		local PEC is partsPercentEC().
		set LabelDashEC:text to "<b>Charge: </b>" + round(PEC) + "%".
		set LabelDashLFO:text to "<b>Fuel: </b>" + round(partsPercentLFO()) + "%".
		// Brake in case of low power
		If pec < 0.1 brakes on.

		set SliderSteering:value to kTurn.
		set SliderThrottle:value to wtVAL.
	}
	wait 0. // Waits for next physics tick.
}

// Clear before end
clearguis().
partsEnableReactionWheels().
set ship:control:neutralize to true.
