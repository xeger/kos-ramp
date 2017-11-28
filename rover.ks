// rover.ks
// Written by KK4TEE
// License: GPLv3
//
// This program provides stability assistance
// for manually driven rovers

// GUI, Stability control and other improvements by FellipeC 2017

parameter turnfactor is 8. // Allow for passing the turnfactor for different rovers.
parameter maxspeed is 39. // Allow for passing the speedlimit. Default is 39 m/s, almost 88mph ;)

set speedlimit to maxspeed. //All speeds are in m/s 
lock turnlimit to min(1, turnfactor / GROUNDSPEED). //Scale the 
                   //turning radius based on current speed

set looptime to 0.01.
set loopEndTime to TIME:SECONDS.
set eWheelThrottle to 0. // Error between target speed and actual speed
set iWheelThrottle to 0. // Accumulated speed error
set wtVAL to 0. //Wheel Throttle Value
set kTurn to 0. //Wheel turn value.
set targetspeed to 0. //Cruise control starting speed
set targetHeading to 90. //Used for autopilot steering
set NORTHPOLE to latlng( 90, 0). //Reference heading
set CruiseControl to False. //Enable/Disable Cruise control
set StartJump to 0. //Used to track airtime
set StartLand to 0. //Used to track time after recover from a jump
set LongJump to False. //Use by jump recovery
set lastGUIUpdate to 0.
set GUIUpdateInterval to 0.25.


FUNCTION MSTOKMH {
    PARAMETER MS.
    RETURN MS * 3.6.
}

FUNCTION DisableReactionWheels {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleReactionWheel") {
            LOCAL M IS P:GETMODULE("ModuleReactionWheel").
            M:DOACTION("deactivate wheel",True).
        }
    }.
}

FUNCTION EnableReactionWheels {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleReactionWheel") {
            LOCAL M IS P:GETMODULE("ModuleReactionWheel").
            M:DOACTION("activate wheel",True).
        }
    }.
}

FUNCTION ExtendAntennas {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            M:DOACTION("extend antenna",True).
        }
    }.
}

FUNCTION RetractAntennas {
    FOR P IN SHIP:PARTS {
        IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
            LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
            M:DOACTION("retract antenna",True).
        }
    }.
}

FUNCTION PercentEC { 
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "ELECTRICCHARGE" {
            RETURN R:AMOUNT / R:CAPACITY * 100.
        }
    }
    RETURN 0.
}

FUNCTION TerrainNormal {
    // Thanks to Ozin
    // Returns a vector normal to the terrain
    parameter radius is 5. //Radius of the terrain sample
    local p1 to body:geopositionof(facing:vector * radius).
    local p2 to body:geopositionof(facing:vector * -radius + facing:starvector * radius).
    local p3 to body:geopositionof(facing:vector * -radius + facing:starvector * -radius).

    local p3p1 to p3:position - p1:position.
    local p2p1 to p2:position - p1:position.

    local normalvec to vcrs(p2p1,p3p1).
    return normalvec.
}


FUNCTION PercentLFO {
    LOCAL LFCAP IS 0.
    LOCAL LFAMT IS 0.
    LOCAL OXCAP IS 0.
    LOCAL OXAMT IS 0.
    LOCAL SURPLUS IS 0.
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "LIQUIDFUEL" {
            SET LFCAP TO R:CAPACITY.
            SET LFAMT TO R:AMOUNT. 
        }
        ELSE IF R:NAME = "OXIDIZER" {
            SET OXCAP TO R:CAPACITY.
            SET OXAMT TO R:AMOUNT.
        }
    }
    IF OXCAP = 0 OR LFCAP = 0 {
        RETURN 0.
    }
    ELSE {
        IF OXCAP * (11/9) < LFCAP { // Surplus fuel
            RETURN OXAMT/OXCAP*100.
        }
        ELSE { // Surplus oxidizer or proportional amonts
            RETURN LFAMT/LFCAP*100.
        }
    }
}

FUNCTION PercentMP {
    FOR R IN SHIP:RESOURCES {
        IF R:NAME = "MONOPROPELLANT" {
            RETURN R:AMOUNT / R:CAPACITY * 100.
        }
    }
    RETURN 0.
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
LOCAL labelHDGTitle IS apsettings:ADDLABEL("<b><size=15>Desidered Heading</size></b>").
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

local SteeringSteep is 10.

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
LOCAL labelSPDTitle IS apsettings:ADDLABEL("<b><size=15>Desidered Speed</size></b>").
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

if kuniverse:activevessel = ship { 

    // Reset controls
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    sas off.
    rcs off.
    lights on.
    set runmode to 0.

    // Check if rover is in a good state to be controlled.
    if ship:status = "PRELAUNCH" {
        SET labelMode:Text TO "<size=16><color=yellow>Waiting launch...</color></size>".
        wait until ship:status <> "PRELAUNCH".
    }
    else if ship:status = "ORBITING" {
        set runmode to -1.
    }

    DisableReactionWheels().
    ExtendAntennas().

    SET WThrottlePID to PIDLOOP(0.15,0.005,0.020, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
    SET WThrottlePID:SETPOINT TO 0. 

    SET WSteeringPID to PIDLOOP(0.005,0.0001,0.001, -1, 1). // Kp, Ki, Kd, MinOutput, MaxOutput
    SET WSteeringPID:SETPOINT TO 0. 

    until runmode = -1 {

        //Update the compass:
        // I want the heading to match the navball 
        // and be out of 360' instead of +/-180'
        // I do this by judging the heading relative
        // to a latlng set to the north pole
        if northPole:bearing <= 0 {
            set cHeading to ABS(northPole:bearing).
        }
        else {
            set cHeading to (180 - northPole:bearing) + 180.
        }

        if runmode = 0 { //Govern the rover 
        
            //Wheel Throttle:
            set targetspeed to targetspeed + 0.05 * SHIP:CONTROL:PILOTWHEELTHROTTLE.
            set targetspeed to max(-speedlimit/3, min( speedlimit, targetspeed)).
            set gs to vdot(ship:facing:vector,ship:velocity:surface).
            set wtVAL to WThrottlePID:UPDATE(time:seconds,gs-targetspeed).

            if brakes { //Disable cruise control if the brakes are turned on.
                set targetspeed to 0.
            }
            
            //Steering:
            if CruiseControl { //Activate autopilot 
                set errorSteering to (targetheading - cHeading).
                if errorSteering > 180 { //Make sure the headings make sense
                    set errorSteering to errorSteering - 360.
                    }
                else if errorSteering < -180 {
                    set errorSteering to errorSteering + 360.
                    }
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
            if ship:status <> "LANDED" { set StartJump to time:seconds. set runmode to 2.}.
            //Detect rollover
            if abs(vang(vxcl(ship:facing:vector,ship:facing:upvector),TerrainNormal())) > 5 {
                set turnfactor to max(1,turnfactor * 0.9). //Reduce turnfactor
                set runmode to 2. //Engage Stability control
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
        else if runmode = 2 { //Stability control mode

            //We don't want the rover trying to turn or accelerate while trying to stay stable
            set wtVAL to 0. 
            set kTurn to 0.

            // Use all means available to steer the rover parallel to the surface
            LOCAL N IS TerrainNormal().
            SET SteerDir to LOOKDIRUP(vxcl(N,VELOCITY:SURFACE),SHIP:UP:vector).
            IF NOT RCS LOCK STEERING TO SteerDir.
            EnableReactionWheels().
            RCS ON. SAS OFF.
            RetractAntennas(). //Try to don't break the antennas

            if ship:status = "LANDED" { //Deals with rover on ground
                if StartLand = 0 { // Means it just landed or start to rollover
                    SET StartLand to TIME:SECONDS. 
                }
                else if time:seconds - StartLand <= 3 { // Stabilze landing
                    if longJump { //Only try to stabilize the landing if was a long jump, to save Monopropellant
                        local sense is ship:facing.
                        local dirV is V(
                        vdot(-ship:up:vector, sense:starvector),
                        vdot(-ship:up:vector, sense:upvector),
                        vdot(-ship:up:vector, sense:vector)
                        ).
                        set ship:control:translation to dirV:normalized.
                    }
                }
                else if time:seconds - StartLand > 3 { // Reset and resume normal drive
                    SAS OFF.
                    RCS OFF.
                    DisableReactionWheels().
                    UNLOCK STEERING.
                    SET runmode TO 0.
                    SET ship:control:translation to v(0,0,0).
                    SET StartLand to 0.
                    SET StartJump to 0.
                    SET LongJump to False.
                    ExtendAntennas(). //Keep the communication
                }
            }
            ELSE {
                if ship:verticalspeed < -5 and ALT:RADAR < 20 { // Use RCS to try to soften the landing
                    local sense is ship:facing.
                    local dirV is V(
                        vdot(ship:up:vector, sense:starvector),
                        vdot(ship:up:vector, sense:upvector),
                        vdot(ship:up:vector, sense:vector)
                    ).
                    set ship:control:translation to dirV:normalized.
                }
                else { // Stop the RCS translation up.
                    set ship:control:translation to v(0,0,0).
                }
                if time:seconds - StartJump > 3 { // Detects long jumps 
                    set targetspeed to targetspeed * 0.9. //Reduces speed by 10% to prevent more jumps
                    set StartJump to time:SECONDS.
                    set longJump to True.
                }.
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
                SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (MSTOKMH(targetspeed),1) + " km/h</b>".
                }
            else if runmode = 1 {
                set labelMode:TEXT to "<b><size=17>Manual Control</size></b>".
                SET LabelHDG:TEXT to "<b>-º</b>".
                SET LabelSPD:TEXT to "<b>- m/s | - km/h</b>".
            }
            else if runmode = 2 {
                set labelMode:TEXT to "<b><size=17>Stability Control</size></b>".
                SET LabelHDG:TEXT to "<b>" + round( targetheading, 2) + "º</b>".
                SET LabelSPD:TEXT to "<b>" + round( targetspeed, 1) + " m/s | "+ round (MSTOKMH(targetspeed),1) + " km/h</b>".  
            }
            SET LabelDashSpeed:TEXT to "<b>Speed: </b>" + round( gs, 1) + " m/s | "+ round (MSTOKMH(gs),1) + " km/h".

            local PEC is PercentEC().
            SET LabelDashEC:TEXT to "<b>Charge: </b>" + ROUND(PEC) + "%".
            SET LabelDashLFO:TEXT to "<b>Fuel: </b>" + ROUND(PercentLFO()) + "%".
            // Brake in case of low power
            If pec < 0.1 brakes on.

            SET SliderSteering:VALUE to kTurn.
            SET SliderThrottle:VALUE to wtVAL. 
        }
        set looptime to TIME:SECONDS - loopEndTime.
        set loopEndTime to TIME:SECONDS.

        wait 0. // Waits for next physics tick.
    }

}

//Clear before end
CLEARGUIS().
UNLOCK Throttle.
UNLOCK Steering.
EnableReactionWheels().
SET ship:control:translation to v(0,0,0).
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.