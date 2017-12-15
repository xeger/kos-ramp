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

local wtVAL is 0. //Wheel Throttle Value
local kTurn is 0. //Wheel turn value.
local targetspeed is 0. //Cruise control starting speed
local targetHeading is 90. //Used for autopilot steering
local CruiseControl is False. //Enable/Disable Cruise control
local lastGUIUpdate is 0.
local GUIUpdateInterval is 0.25.
local runmode is 0.
local cHeading is 0. //Compass heading 
local gs is ship:groundspeed.
local errorSteering is 0.
local turnlimit is 0.

//Route maker 
local Route is list().
Function AddWaypoint { 
    local waypointlex is lexicon("lat",ship:geoposition:lat,"lng",ship:geoposition:lng).
    Route:add(waypointlex). 
    uiBanner("Route","Waypoint added: " + Route[Route:length-1]). 
}

Function RmvWaypoint { 
    if route:empty() uiBanner("Route","There are no more waypoints").
    else { 
        route:remove(Route:length-1).
        uiBanner("Route","Last waypoint removed."). 
    } 
}

Function SaveRoute {
    if HomeConnection:IsConnected {
        WriteJSON(Route,"0:/routes/" + TextFieldRouteName:Text()+ ".json").
        uiBanner("Route","Route saved!",2).
    }
    else uiError("Route","There is no connection to KSC servers. Raise antennas and try again.").
}




// Create a GUI window
LOCAL gui IS GUI(250).
SET gui:x TO 30.
SET gui:y TO 100.

LOCAL labelName IS gui:ADDLABEL("<b><i><size=14>" + SHIP:NAME + "</size></i></b>").
SET labelName:STYLE:ALIGN TO "CENTER".
SET labelName:STYLE:HSTRETCH TO True. 
SET labelName:STYLE:TEXTCOLOR to Yellow.

LOCAL labelMode IS gui:ADDLABEL("").
SET labelMode:STYLE:ALIGN TO "CENTER".
SET labelMode:STYLE:HSTRETCH TO True. 

LOCAL apbuttons TO gui:ADDHBOX().
LOCAL ButtonCC   TO apbuttons:addbutton("Cruise").
LOCAL ButtonMD   TO apbuttons:addbutton("Assist").
LOCAL ButtonMC   TO apbuttons:addbutton("Manual").

SET ButtonCC:ONCLICK TO { SET CruiseControl TO True. }.
SET ButtonMD:ONCLICK TO { SET CruiseControl TO False. }.
SET ButtonMC:ONCLICK TO { SET runmode TO 1. }.


LOCAL apsettings to gui:ADDVLAYOUT().
//HDG Settings
LOCAL labelHDGTitle IS apsettings:ADDLABEL("<b><size=15>Desired Heading</size></b>").
SET labelHDGTitle:STYLE:ALIGN TO "CENTER".
SET labelHDGTitle:STYLE:HSTRETCH TO True. 
LOCAL hdgsettings to apsettings:ADDHBOX().
LOCAL ButtonHDGM TO hdgsettings:ADDBUTTON("◀").
SET ButtonHDGM:Style:WIDTH TO 40.
SET ButtonHDGM:Style:HEIGHT TO 25.
LOCAL LabelHDG TO hdgsettings:ADDLABEL("").
SET LabelHDG:Style:HEIGHT TO 25.
SET LabelHDG:STYLE:ALIGN TO "CENTER".
LOCAL ButtonHDGP TO hdgsettings:ADDBUTTON("▶").
SET ButtonHDGP:Style:WIDTH TO 40.
SET ButtonHDGP:Style:HEIGHT TO 25.

local SteeringSteep is 5.

SET ButtonHDGM:ONCLICK  TO { 
    SET targetheading TO ((ROUND(targetheading/SteeringSteep)*SteeringSteep) -SteeringSteep).
    IF targetheading < 0 {
        SET targetheading TO targetheading + 360.
    }
}.
SET ButtonHDGP:ONCLICK  TO { 
    SET targetheading TO ((ROUND(targetheading/SteeringSteep)*SteeringSteep) +SteeringSteep).
    IF targetheading > 360 {
        SET targetheading TO targetheading - 360.
    }
}.

//SPEED Settings
LOCAL labelSPDTitle IS apsettings:ADDLABEL("<b><size=15>Desired Speed</size></b>").
SET labelSPDTitle:STYLE:ALIGN TO "CENTER".
SET labelSPDTitle:STYLE:HSTRETCH TO True. 
LOCAL SPDsettings to apsettings:ADDHBOX().
LOCAL ButtonSPDM TO SPDsettings:ADDBUTTON("▼").
SET ButtonSPDM:Style:WIDTH TO 40.
SET ButtonSPDM:Style:HEIGHT TO 25.
LOCAL LabelSPD TO SPDsettings:ADDLABEL("").
SET LabelSPD:Style:HEIGHT TO 25.
SET LabelSPD:STYLE:ALIGN TO "CENTER".
LOCAL ButtonSPDP TO SPDsettings:ADDBUTTON("▲").
SET ButtonSPDP:Style:WIDTH TO 40.
SET ButtonSPDP:Style:HEIGHT TO 25.

SET ButtonSPDM:ONCLICK  TO { 
    SET targetspeed TO ROUND(targetspeed) -3.
}.
SET ButtonSPDP:ONCLICK  TO { 
    SET targetspeed TO ROUND(targetspeed) +3.
}.

//Dashboard
LOCAL dashboard to gui:ADDHBOX().
LOCAL DashLeft to dashboard:ADDVLAYOUT().
LOCAL LabelDashSpeed to DashLeft:ADDLABEL("").
SET LabelDashSpeed:STYLE:ALIGN TO "LEFT".
SET LabelDashSpeed:STYLE:HSTRETCH TO True. 
SET LabelDashSpeed:STYLE:TEXTCOLOR TO Yellow.  
LOCAL LabelDashEC to DashLeft:ADDLABEL("").
SET LabelDashEC:STYLE:ALIGN TO "LEFT".
SET LabelDashEC:STYLE:HSTRETCH TO True. 
SET LabelDashEC:STYLE:TEXTCOLOR TO Yellow.  
LOCAL LabelDashLFO to DashLeft:ADDLABEL("").
SET LabelDashLFO:STYLE:ALIGN TO "LEFT".
SET LabelDashLFO:STYLE:HSTRETCH TO True. 
SET LabelDashLFO:STYLE:TEXTCOLOR TO Yellow.  


LOCAL SliderSteering to DashLeft:ADDHSLIDER(0,1,-1).
LOCAL LabelControls  to DashLeft:ADDLABEL("<color=#aaaaaa88>▲ Steering | Throttle ▶</color>").
SET LabelControls:STYLE:ALIGN TO "RIGHT".
SET LabelControls:STYLE:HSTRETCH TO True. 
LOCAL SliderThrottle to Dashboard:ADDVSLIDER(0,1,-1).

local RouteMaker is gui:AddVBox().
local rmButtons is RouteMaker:AddHLayout().
local ButtonAddWPT is rmButtons:AddButton("+ Waypoint").
local ButtonRmvWPT is rmButtons:AddButton("- Waypoint").
local ButtonSaveRoute is rmButtons:AddButton("Save Route").
local TextFieldRouteName is RouteMaker:AddTextField("Route name").

Set ButtonAddWPT:ONCLICK to AddWaypoint@.
Set ButtonRmvWPT:ONCLICK to RmvWaypoint@.
Set ButtonSaveRoute:ONCLICK To SaveRoute@.

ON AG1 { AddWaypoint(). Preserve. }

LOCAL ButtonStop TO gui:ADDBUTTON("Stop script").
SET ButtonStop:ONCLICK TO { set runmode to -1 . WAIT 0.}.

LOCAL ok TO gui:ADDBUTTON("Reboot kOS").
SET ok:ONCLICK TO {
    gui:HIDE().
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    reboot.
}.
gui:SHOW().


///////////////
// Main program
///////////////

wait until kuniverse:activevessel = ship.

// Reset controls
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
sas off.
rcs off.
lights on.
fuelcells on.
partsDisableReactionWheels().
partsExtendAntennas().

// Check if rover is in a good state to be controlled.
if ship:status = "PRELAUNCH" {
    SET labelMode:Text TO "<size=16><color=yellow>Waiting launch...</color></size>".
    wait until ship:status <> "PRELAUNCH".
}
else if ship:status <> "LANDED" {  
    set runmode to -1.
}

local WThrottlePID to PIDLOOP(0.15,0.005,0.020, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WThrottlePID:SETPOINT TO 0. 

local WSteeringPID to PIDLOOP(0.005,0.0001,0.001, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
set WSteeringPID:SETPOINT TO 0. 

until runmode = -1 {

    //Update the compass:
    // I want the heading to match the navball 
    // and be out of 360' instead of +/-180'
    // I do this by judging the heading relative
    // to a latlng set to the north pole
    set cHeading to utilCompassHeading().
    LOCAL N IS TerrainNormalVector().
    set turnlimit to min(1, turnfactor / abs(gs)). //Scale the turning radius based on current speed

    if runmode = 0 { //Govern the rover 
    
        //Wheel Throttle:
        set targetspeed to targetspeed + 0.1 * SHIP:CONTROL:PILOTWHEELTHROTTLE.
        set targetspeed to max(-speedlimit/3, min( speedlimit, targetspeed)).
        set gs to vdot(ship:facing:vector,ship:velocity:surface).
        set wtVAL to WThrottlePID:UPDATE(time:seconds,gs-targetspeed).

        if brakes { //Disable cruise control if the brakes are turned on.
            set targetspeed to 0.
        }
        
        //Steering:
        if CruiseControl { //Activate autopilot 
            set errorSteering to utilHeadingToBearing(targetheading - cHeading).
            if gs < 0 set errorSteering to -errorSteering.
            set WSteeringPID:MaxOutput to  1 * turnlimit.
            set WSteeringPID:MinOutput to -1 * turnlimit.
            set kturn to WSteeringPID:UPDATE(time:seconds,errorSteering).
        }
        else {
            set kturn to turnlimit * SHIP:CONTROL:PILOTWHEELSTEER.
            set targetHeading to cheading.
            }
        //Detect jumps and engage stability control
        if ship:status <> "LANDED" {
            if roverStabilzeJump(N) {
                uiBanner("Rover","Wow, that was a long jump!").
                set targetspeed to targetspeed * 0.75.
            }
        }
        //Detect rollover
        if roverIsRollingOver(N) {
            set turnfactor to max(1,turnfactor * 0.9). //Reduce turnfactor
            roverStabilzeJump(N). //Engage Stability control
        }
    }    
    else if runmode = 1 { //Stock driving mode
        set wtVAL to SHIP:CONTROL:PILOTWHEELTHROTTLE * 0.5.
        set kturn to SHIP:CONTROL:PILOTWHEELSTEER.
        if abs(ship:groundspeed) > speedlimit * 0.3 {
            set runmode to 0.
            brakes on.
        } 
    }
    
    //Here it really control the rover.
    set wtVAL to min(1,(max(-1,wtVAL))).
    set kTurn to min(1,(max(-1,kTurn))).
    set SHIP:CONTROL:WHEELTHROTTLE to WTVAL.
    set SHIP:CONTROL:WHEELSTEER to kTurn.
    
    // Update the GUI
    if time:seconds > lastGUIUpdate + GUIUpdateInterval {
        set lastGUIUpdate to time:seconds.
        if runmode = 0 {
            if CruiseControl {
                set labelMode:TEXT to "<b><size=17>Cruise Control</size></b>".
            }
            Else{
                set labelMode:TEXT to "<b><size=17>Assisted Drive</size></b>".
            }
            SET LabelHDG:TEXT to "<b>" + round( targetheading, 2) + "º</b>".
            SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (uiMSTOKMH(targetspeed),1) + " km/h</b>".
            }
        else if runmode = 1 {
            set labelMode:TEXT to "<b><size=17>Manual Control</size></b>".
            SET LabelHDG:TEXT to "<b>-º</b>".
            SET LabelSPD:TEXT to "<b>- m/s | - km/h</b>".
        }
        else if runmode = 2 {
            set labelMode:TEXT to "<b><size=17>Stability Control</size></b>".
            SET LabelHDG:TEXT to "<b>" + round( targetheading, 2) + "º</b>".
            SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (uiMSTOKMH(targetspeed),1) + " km/h</b>".  
        }
        SET LabelDashSpeed:TEXT to "<b>Speed: </b>" + round( gs, 1) + " m/s | "+ round (uiMSTOKMH(gs),1) + " km/h".

        local PEC is partsPercentEC().
        SET LabelDashEC:TEXT to "<b>Charge: </b>" + ROUND(PEC) + "%".
        SET LabelDashLFO:TEXT to "<b>Fuel: </b>" + ROUND(partsPercentLFO()) + "%".
        // Brake in case of low power
        If pec < 0.1 brakes on.

        SET SliderSteering:VALUE to kTurn.
        SET SliderThrottle:VALUE to wtVAL. 
    }
    wait 0. // Waits for next physics tick.
}

//Clear before end
CLEARGUIS().
partsEnableReactionWheels().
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.