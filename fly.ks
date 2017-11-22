// FLY.KS 
// Usage: Type 'RUN FLY.' in kOS console for piloting planes.
// For shuttle reentry type 'RUN FLY("SHUTTLE").' in console when shuttle is about 20000 and about over the mountains. Your mileage may vary.

// 2017 FellipeC - Released under https://creativecommons.org/licenses/by-nc/4.0/


PARAMETER KindOfCraft IS "Plane".
PARAMETER LandingGear IS "Tricicle".

CLEARSCREEN.
CLEARVECDRAWS().
CLEARGUIS().

SET CONSOLEINFO TO FALSE.

PRINT "CONSOLE OUTPUT IS " + CONSOLEINFO.

FUNCTION fbwhud {
    PARAMETER TEXT.
    hudtext(TEXT,8,3,35,yellow,false).
}

FUNCTION PlayAlarm {
    SET V0 TO GetVoice(0).
    V0:PLAY( NOTE( 440, 1) ).  // Play one note at 440 Hz for 1 second.
    // Play a 'song' consisting of note, note, rest, sliding note, rest:
    V0:PLAY(
        LIST(
            NOTE("A#4", 0.2,  0.25), // quarter note, of which the last 0.05s is 'release'.
            NOTE("A4",  0.2,  0.25), // quarter note, of which the last 0.05s is 'release'.
            NOTE("R",   0.2,  0.25), // rest
            SLIDENOTE("C5", "F5", 0.45, 0.5), // half note that slides from C5 to F5 as it goes.
            NOTE("R",   0.2,  0.25)  // rest.
        )
    ).
}

  FUNCTION HasTermometer { 
    // Checks if ship have required sensors:
    // - Termometer
    LOCAL HasT IS False.
    LIST SENSORS IN SENSELIST.
    FOR S IN SENSELIST {
      IF S:TYPE = "TEMP" { SET HasT to True. }
    }
    RETURN HasT. 
  }

FUNCTION Mach {
    PARAMETER SpdMS.
    LOCAL AirTemp IS 288.15.
    IF HasTermometer() { SET AirTemp TO SHIP:SENSORS:TEMP.  }.
    RETURN SpdMS / SQRT(1.4*286*AirTemp).
}

FUNCTION YawError {
    LOCAL yaw_error_vec IS VXCL(FACING:TOPVECTOR,ship:srfprograde:vector).
    LOCAL yaw_error_ang IS VANG(FACING:VECTOR,yaw_error_vec).
    IF VDOT(SHIP:FACING:STARVECTOR, SHIP:srfprograde:VECTOR) < 0 {
        RETURN yaw_error_ang.
    }
    ELSE {
        RETURN -yaw_error_ang.
    }
    
}

FUNCTION AoA {
    LOCAL pitch_error_vec IS VXCL(FACING:STARVECTOR,ship:srfprograde:vector).
    LOCAL pitch_error_ang IS VANG(FACING:VECTOR,pitch_error_vec).
    IF VDOT(SHIP:FACING:TOPVECTOR, SHIP:srfprograde:VECTOR) < 0 {
        RETURN pitch_error_ang.
    }
    ELSE {
        RETURN -pitch_error_ang.
    }
    
}


FUNCTION BankAngle {
    LOCAL starBoardRotation TO SHIP:FACING * R(0,90,0).
    LOCAL starVec TO starBoardRotation:VECTOR.
    set horizonVec to VCRS(SHIP:UP:VECTOR,SHIP:FACING:VECTOR).
    
    IF VDOT(SHIP:UP:VECTOR, starVec) < 0{
        RETURN VANG(starVec,horizonVec).
    }
    ELSE {
        RETURN -VANG(starVec,horizonVec).
    }    
}

FUNCTION PitchAngle {
    RETURN -(VANG(ship:up:vector,ship:facing:FOREVECTOR) - 90).
}

FUNCTION ProgradePitchAngle {
    RETURN -(VANG(ship:up:vector,vxcl(ship:facing:starvector,ship:velocity:surface) - 90).
}

FUNCTION MagHeading {
    SET northPole TO latlng(90,0).
    Return mod(360-northPole:bearing, 360).
}

FUNCTION CompassDegrees {
    PARAMETER DEGREES.
    RETURN mod(360-DEGREES, 360).
}

FUNCTION MaxAoA {
    // Fligth Envelope Protection
    LOCAL AllowedAoA IS 40.
    Return ((AllowedAoA - AoA()) + PitchAngle()).
}

FUNCTION RadarAltimeter {
    Return ship:altitude - ship:geoposition:terrainheight.
}

FUNCTION DeltaHeading {
    PARAMETER tHeading.
    // Heading Control
    LOCAL dHeading to tHeading - magheading().
    if dHeading > 180 {
        SET dHeading TO dHeading - 360.
    }
    else if dHeading < -180 {
        SET dHeading TO dHeading + 360.
    }
    Return dHeading.
}

FUNCTION GroundDistance {
    // Returns distance to a point in ground from the ship's ground position (ignores altitude)
    PARAMETER TgtPos.
    RETURN vxcl(up:vector, TgtPos:Position):mag.
}


FUNCTION Glideslope{
    //Returns the altitude of the glideslope
    PARAMETER Threshold.
    PARAMETER GSAngle IS 5.
    LOCAL KerbinAngle is abs(ship:geoposition:lng) - abs(Threshold:lng).
    LOCAL Correction IS SQRT( (KERBIN:RADIUS^2) + (TAN(KerbinAngle)*KERBIN:RADIUS)^2 ) - KERBIN:Radius. // Why this correction? https://imgur.com/a/CPHnD
    RETURN (tan(GSAngle) * GroundDistance(Threshold)) + Threshold:terrainheight + Correction.
}

FUNCTION CenterLineDistance {
    //Returns the ground distance of the centerline
    PARAMETER Threshold.
    LOCAL Marker IS latlng(Threshold:lat,Ship:geoposition:lng).
    IF SHIP:geoposition:lat > Threshold:lat {
        RETURN GroundDistance(Marker).
    }
    ELSE {
        RETURN -GroundDistance(Marker).
    }
}

FUNCTION TAKEOFF {
    LOCAL LANDEDALT IS SHIP:ALTITUDE.
    SAS OFF.
    BRAKES OFF.
    STAGE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
    WAIT UNTIL SHIP:AIRSPEED > 50.
    SET SHIP:CONTROL:PITCH TO 0.5.
    WAIT UNTIL SHIP:Altitude > LANDEDALT + 50.
    SET SHIP:CONTROL:PITCH TO 0.
    SAS ON.
    GEAR OFF.
    WAIT UNTIL SHIP:Altitude > LANDEDALT + 600.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}


FUNCTION MSTOKMH {
    PARAMETER MS.
    RETURN MS * 3.6.
}

// Interface

// GUI FOR TAKE OFF
IF SHIP:STATUS = "LANDED" {
    LOCAL guiTO IS GUI(300).
    LOCAL labelAutoTakeoff IS guiTO:ADDLABEL("<size=20><b>Auto takeoff?</b></size>").
    SET labelAutoTakeoff:STYLE:ALIGN TO "CENTER".
    SET labelAutoTakeoff:STYLE:HSTRETCH TO True. 

    LOCAL autoTOYes TO guiTO:ADDBUTTON("Yes").
    LOCAL autoTONo  TO guiTO:ADDBUTTON("No").
    guiTO:SHOW().
    set atdone to false.
    SET autoTOYes:ONCLICK TO { guiTO:hide. takeoff().  set atdone to true. }.
    SET autoTONo:ONCLICK TO { guiTO:hide. wait until ship:altitude > 1000. set atdone to true. }.
    wait until atdone.
}

//Waypoint Selection screen
LOCAL guiWP IS GUI(200).
SET guiWP:x TO 360.
SET guiWP:y TO 100.
LOCAL labelSelectWaypoint IS guiWP:ADDLABEL("<size=20><b>Select waypoint:</b></size>").
SET labelSelectWaypoint:STYLE:ALIGN TO "CENTER".
SET labelSelectWaypoint:STYLE:HSTRETCH TO True. 

LOCAL buttonWP01 TO guiWP:ADDBUTTON("KSC Runway 09").
SET buttonWP01:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-74.724722). // RWY 09
        set TGTAltitude to 1000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "KSC Runway 09".
        guiWP:hide.
    }.

LOCAL buttonWP02 TO guiWP:ADDBUTTON("RNAV RWY09 Waypoint 1").
SET buttonWP02:ONCLICK TO 
    {
        set TargetCoord to latlng(-2,-77.7). 
        set TGTAltitude to 2500.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "RNAV RWY09 Waypoint 1".
        guiWP:hide.
    }.


LOCAL buttonWP03 TO guiWP:ADDBUTTON("Begin of glideslope").
SET buttonWP03:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-77). // Glideslope
        set TGTAltitude to 4000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Begin of glideslope".
        guiWP:hide.
    }.

LOCAL buttonWP04 TO guiWP:ADDBUTTON("Moutains").
SET buttonWP04:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-79.5). // Mountains
        set TGTAltitude to 8000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Moutains".
        guiWP:hide.
    }.

LOCAL buttonWP05 TO guiWP:ADDBUTTON("Far west").
SET buttonWP05:ONCLICK TO 
    {
        set TargetCoord to latlng(-0.0483334,-85). // Far west
        set TGTAltitude to 9000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Far west".
        guiWP:hide.
    }.

LOCAL buttonWP06 TO guiWP:ADDBUTTON("Old Airfield").
SET buttonWP06:ONCLICK TO 
    {
        set TargetCoord to latlng(-1.54084,-71.91). // Far west
        set TGTAltitude to 1500.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Old Airfield".
        guiWP:hide.
    }.

LOCAL buttonWP07 TO guiWP:ADDBUTTON("RNAV Old Airfield Waypoint 1").
SET buttonWP07:ONCLICK TO 
    {
        set TargetCoord to latlng(-1.3,-74.5). 
        set TGTAltitude to 2000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "RNAV Old Airfield Waypoint 1".
        guiWP:hide.
    }.

LOCAL buttonWP08 TO guiWP:ADDBUTTON("Baikerbanur").
SET buttonWP08:ONCLICK TO 
    {
        set TargetCoord to latlng(20.6572,-146.4205). 
        set TGTAltitude to 2000.
        SET LNAVMODE TO "TGT".
        SET LabelWaypoint:TEXT to "Baikerbanur".
        guiWP:hide.
    }.




// Create a GUI window
LOCAL gui IS GUI(300).
SET gui:x TO 30.
SET gui:y TO 100.

// Add widgets to the GUI
LOCAL labelMode IS gui:ADDLABEL("<b>AP Mode</b>").
SET labelMode:STYLE:ALIGN TO "CENTER".
SET labelMode:STYLE:HSTRETCH TO True. 

LOCAL baseselectbuttons TO gui:ADDHBOX().
LOCAL radiobuttonKSC to baseselectbuttons:ADDRADIOBUTTON("Space Center",True).
LOCAL radiobuttonOAF to baseselectbuttons:ADDRADIOBUTTON("Old airfield",False).
LOCAL checkboxVectors to baseselectbuttons:ADDBUTTON("HoloILS™").
SET radiobuttonKSC:Style:HEIGHT TO 25.
SET radiobuttonOAF:Style:HEIGHT TO 25.
SET checkboxVectors:TOGGLE TO True.

SET baseselectbuttons:ONRADIOCHANGE TO {
    PARAMETER B.

    IF B:TEXT = "Space Center" {
        SET TGTRunway to RWYKSC.
    }
    IF B:TEXT = "Old airfield" {
        SET TGTRunway to RWYOAF.
    }
}.

LOCAL apbuttons TO gui:ADDHBOX().
LOCAL ButtonNAV   TO apbuttons:addbutton("HLD").
LOCAL ButtonILS   TO apbuttons:addbutton("ILS").
LOCAL ButtonAPOFF TO apbuttons:addbutton("OFF").

SET ButtonNAV:ONCLICK   TO { 
    SET APMODE TO "NAV".
    SET VNAVMODE TO "ALT".
    SET LNAVMODE TO "HDG".
    SET TGTAltitude TO ROUND(SHIP:ALTITUDE).
    SET TGTHeading TO ROUND(MagHeading()).
 }.
SET ButtonILS:ONCLICK   TO { SET APMODE TO "ILS". }.
SET ButtonAPOFF:ONCLICK TO { SET APMODE TO "OFF". }.

//Autopilot settings
LOCAL apsettings to gui:ADDVBOX().

//HDG Settings
LOCAL hdgsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonHDG TO hdgsettings:ADDBUTTON("HDG").
SET ButtonHDG:Style:WIDTH TO 40.
SET ButtonHDG:Style:HEIGHT TO 25.
LOCAL ButtonHDGM TO hdgsettings:ADDBUTTON("◀").
SET ButtonHDGM:Style:WIDTH TO 40.
SET ButtonHDGM:Style:HEIGHT TO 25.
LOCAL LabelHDG TO hdgsettings:ADDLABEL("").
SET LabelHDG:Style:HEIGHT TO 25.
SET LabelHDG:STYLE:ALIGN TO "CENTER".
LOCAL ButtonHDGP TO hdgsettings:ADDBUTTON("▶").
SET ButtonHDGP:Style:WIDTH TO 40.
SET ButtonHDGP:Style:HEIGHT TO 25.

SET ButtonHDG:ONCLICK   TO { SET LNAVMODE TO "HDG". }.
SET ButtonHDGM:ONCLICK  TO { 
    SET TGTHeading TO ((ROUND(TGTHeading/5)*5) -5).
    IF TGTHeading < 0 {
        SET TGTHeading TO TGTHeading + 360.
    }
}.
SET ButtonHDGP:ONCLICK  TO { 
    SET TGTHeading TO ((ROUND(TGTHeading/5)*5) +5).
    IF TGTHeading > 360 {
        SET TGTHeading TO TGTHeading - 360.
    }
}.

//BNK Settings
LOCAL bnksettings to apsettings:ADDHLAYOUT().
LOCAL ButtonBNK TO bnksettings:ADDBUTTON("BNK").
SET ButtonBNK:Style:WIDTH TO 40.
SET ButtonBNK:Style:HEIGHT TO 25.
LOCAL ButtonBNKM TO bnksettings:ADDBUTTON("◀").
SET ButtonBNKM:Style:WIDTH TO 40.
SET ButtonBNKM:Style:HEIGHT TO 25.
LOCAL LabelBNK TO bnksettings:ADDLABEL("").
SET LabelBNK:Style:HEIGHT TO 25.
SET LabelBNK:STYLE:ALIGN TO "CENTER".
LOCAL ButtonBNKP TO bnksettings:ADDBUTTON("▶").
SET ButtonBNKP:Style:WIDTH TO 40.
SET ButtonBNKP:Style:HEIGHT TO 25.

SET ButtonBNK:ONCLICK TO { SET LNAVMODE TO "BNK". SET TGTBank TO BankAngle(). }.
SET ButtonBNKM:ONCLICK  TO { SET TGTBank TO ROUND(TGTBank) - 1. }.
SET ButtonBNKP:ONCLICK  TO { SET TGTBank TO ROUND(TGTBank) + 1. }.


//ALT Settings
LOCAL altsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonALT TO altsettings:ADDBUTTON("ALT").
SET ButtonALT:Style:WIDTH TO 40.
SET ButtonALT:Style:HEIGHT TO 25.
LOCAL ButtonALTM TO altsettings:ADDBUTTON("▼").
SET ButtonALTM:Style:WIDTH TO 40.
SET ButtonALTM:Style:HEIGHT TO 25.
LOCAL LabelALT TO altsettings:ADDLABEL("").
SET LabelALT:Style:HEIGHT TO 25.
SET LabelALT:STYLE:ALIGN TO "CENTER".
LOCAL ButtonALTP TO altsettings:ADDBUTTON("▲").
SET ButtonALTP:Style:WIDTH TO 40.
SET ButtonALTP:Style:HEIGHT TO 25.

SET ButtonALT:ONCLICK   TO { SET VNAVMODE TO "ALT". }.
SET ButtonALTM:ONCLICK  TO { SET TGTAltitude TO (ROUND(TGTAltitude/100)*100) -100 .}.
SET ButtonALTP:ONCLICK  TO { SET TGTAltitude TO (ROUND(TGTAltitude/100)*100) +100 .}.


//PIT Settings
LOCAL pitsettings to apsettings:ADDHLAYOUT().
LOCAL ButtonPIT TO pitsettings:ADDBUTTON("PIT").
SET ButtonPIT:Style:WIDTH TO 40.
SET ButtonPIT:Style:HEIGHT TO 25.
LOCAL ButtonPITM TO pitsettings:ADDBUTTON("▼").
SET ButtonPITM:Style:WIDTH TO 40.
SET ButtonPITM:Style:HEIGHT TO 25.
LOCAL LabelPIT TO pitsettings:ADDLABEL("").
SET LabelPIT:Style:HEIGHT TO 25.
SET LabelPIT:STYLE:ALIGN TO "CENTER".
LOCAL ButtonPITP TO pitsettings:ADDBUTTON("▲").
SET ButtonPITP:Style:WIDTH TO 40.
SET ButtonPITP:Style:HEIGHT TO 25.

SET ButtonPIT:ONCLICK   TO { SET VNAVMODE TO "PIT". }.
SET ButtonPITM:ONCLICK  TO { SET TGTPitch TO ROUND(TGTPitch) -1 .}.
SET ButtonPITP:ONCLICK  TO { SET TGTPitch TO ROUND(TGTPitch) +1 .}.




// Waypoints selection
LOCAL ButtonWAYPOINTS TO apsettings:ADDBUTTON("Select waypoint").
LOCAL wpsettings to apsettings:ADDHLAYOUT().
LOCAL LabelWaypoint to wpsettings:ADDLABEL("No waypoint selected").
LOCAL LabelWaypointDist to wpsettings:ADDLABEL("").
SET LabelWaypointDist:STYLE:ALIGN TO "RIGHT".
SET ButtonWAYPOINTS:ONCLICK TO { guiWP:SHOW. }.


// Autothrottle
LOCAL atbuttons TO gui:ADDHBOX().
LOCAL ButtonSPD   TO atbuttons:addbutton("SPD").
LOCAL ButtonMCT   TO atbuttons:addbutton("MCT").
LOCAL ButtonATOFF TO atbuttons:addbutton("OFF").

SET ButtonSPD:ONCLICK   TO { SET ATMODE TO "SPD". }.
SET ButtonMCT:ONCLICK   TO { SET ATMODE TO "MCT". }.
SET ButtonATOFF:ONCLICK TO { SET ATMODE TO "OFF". }.

LOCAL spdctrl TO gui:ADDHBOX().
LOCAL ButtonSPDM TO spdctrl:ADDBUTTON("▼"). 
SET ButtonSPDM:Style:WIDTH TO 45.
SET ButtonSPDM:Style:HEIGHT TO 25.
LOCAL LabelSPD TO spdctrl:ADDLABEL("").
SET LabelSPD:Style:HEIGHT TO 25.
SET LabelSPD:STYLE:ALIGN TO "CENTER".
LOCAL ButtonSPDP TO spdctrl:ADDBUTTON("▲").
SET ButtonSPDP:Style:WIDTH TO 45.
SET ButtonSPDP:Style:HEIGHT TO 25.
//Adjust speed.
SET ButtonSPDM:ONCLICK TO { SET TGTSpeed TO (ROUND(TGTSpeed/5)*5) -5. }.
SET ButtonSPDP:ONCLICK TO { SET TGTSpeed TO (ROUND(TGTSpeed/5)*5) +5. }.



LOCAL labelAirspeed IS gui:ADDLABEL("<b>Airspeed</b>").
SET labelAirspeed:STYLE:ALIGN TO "LEFT".
SET labelAirspeed:STYLE:HSTRETCH TO True. 

LOCAL labelVSpeed IS gui:ADDLABEL("<b>Vertical speed</b>").
SET labelVSpeed:STYLE:ALIGN TO "LEFT".
SET labelVSpeed:STYLE:HSTRETCH TO True. 

LOCAL labelLAT IS gui:ADDLABEL("<b>LAT</b>").
SET labelLAT:STYLE:ALIGN TO "LEFT".
SET labelLAT:STYLE:HSTRETCH TO True.
SET labelLAT:STYLE:TEXTCOLOR TO YELLOW. 
LOCAL labelLNG IS gui:ADDLABEL("<b>LNG</b>").
SET labelLNG:STYLE:ALIGN TO "LEFT".
SET labelLNG:STYLE:HSTRETCH TO True. 
SET labelLNG:STYLE:TEXTCOLOR TO YELLOW. 

LOCAL ok TO gui:ADDBUTTON("Reboot").

function RebootAutoPilot {
    gui:HIDE().
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    reboot.
}
SET ok:ONCLICK TO RebootAutoPilot@. 

gui:SHOW().





// ABORT!

ON ABORT {
    SET APATEnabled TO FALSE.
    fbwhud("Your controls!!!").
    PRESERVE.
}

// ****************
// SET UP PID LOOPS
// ****************

//PID Elevator 
SET ElevatorPID to PIDLOOP(0.03,0.003,0.007). // Kp, Ki, Kd
SET ElevatorPID:MAXOUTPUT TO 1.
SET ElevatorPID:MINOUTPUT TO -1.
SET ElevatorPID:SETPOINT TO 0. 

// PID Pitch Angle
SET PitchAnglePID to PIDLOOP(0.04,0.004,0.010). // Kp, Ki, Kd
SET PitchAnglePID:MAXOUTPUT TO 20.
SET PitchAnglePID:MINOUTPUT TO -25.
SET PitchAnglePID:SETPOINT TO 0.

//PID Aileron  
SET AileronPID to PIDLOOP(0.01,0.003,0.010). // Kp, Ki, Kd
SET AileronPID:MAXOUTPUT TO 1.
SET AileronPID:MINOUTPUT TO -1.
SET AileronPID:SETPOINT TO 0. 

//PID Yaw Damper
SET YawDamperPID to PIDLOOP(0.002,0.003,0.008). // Kp, Ki, Kd
SET YawDamperPID:MAXOUTPUT TO 1.
SET YawDamperPID:MINOUTPUT TO -1.
SET YawDamperPID:SETPOINT TO 0. 

// PID BankAngle
SET BankAnglePID to PIDLOOP(0.9,0.001,0.003). // Kp, Ki, Kd
SET BankAnglePID:MAXOUTPUT TO 33.
SET BankAnglePID:MINOUTPUT TO -33.
SET BankAnglePID:SETPOINT TO 0. 

//PID Throttle
SET ThrottlePID to PIDLOOP(0.01,0.006,0.016). // Kp, Ki, Kd
SET ThrottlePID:MAXOUTPUT TO 1.
SET ThrottlePID:MINOUTPUT TO 0.
SET ThrottlePID:SETPOINT TO 0. 

//Autotrim parameters
SET ElevatorTrimSum to 0.
SET ElevatorTrimCnt to 0.

SAS OFF. 

set Elevator to 0.
set Aileron to 0.
set Rudder to 0.
set ElevatorTrim to 0.


// Defauts
SET APATEnabled TO TRUE.
SET APSHUTDOWN TO FALSE.
SET LNAVMODE TO "HDG".
SET VNAVMODE TO "ALT".
SET APMODE TO "NAV".
SET ATMODE TO "SPD".
SET TGTSpeed to 150.
SET ILSHOLDALT TO 0.
SET TGTPitch to 0.
SET TGTBank to 0.
SET CTRLIMIT TO 1.
SET AUTOTHROTTLE TO TRUE.
SET PREVIOUSLNAV TO "".
SET PREVIOUSVNAV TO "".
SET PREVIOUSAT TO "".
SET PREVIOUSAP TO "".
SET FLAREALT TO 150.
SET TGTHeading to 90.



//Runways coordinates
SET RWYKSC to latlng(-0.04807,-74.65).
SET RWYKSC_SHUTTLE to latlng(-0.04807,-74.82).
SET RWYOAF to latlng(-1.51795834829155,-71.9661601438879).

IF KindOfCraft = "Shuttle" {
    SET APMODE TO "SHD".
    SET TGTAltitude to 6000.
    SET TGTHeading to MagHeading().
    SET GSAng to 20.
    SET TGTRunway TO RWYKSC_SHUTTLE.
    SET TargetCoord TO TGTRunway.
    SET LabelWaypoint:Text TO "Kerbin Space Center Runway 09".
    SET FLAREALT TO 300.
    PlayAlarm().
}
ELSE IF KindOfCraft = "Plane" {
    SET TGTAltitude to SHIP:Altitude.
    SET TGTHeading to MagHeading().
    SET GSAng TO 4.
    SET TGTRunway TO RWYKSC.
    SET TargetCoord TO TGTRunway.
    SET LabelWaypoint:Text TO "KSC Runway 09".
    SET FLAREALT TO 100.
}


// *********
// MAIN LOOP
// *********

until SHIP:STATUS = "LANDED" {
    wait 0. // Skip a physics tick 

    IF APATEnabled {

        IF SAS { SAS OFF. }

        // *****************
        // SHUTTLE HOLD MODE
        // *****************

        IF APMODE = "SHD" {
            SET LNAVMODE TO "BNK".
            SET TGTBank TO 0.
            SET VNAVMODE TO "PIT".
            SET TGTPitch TO -5.
            IF SHIP:Altitude >= Glideslope(TGTRunway)- 1500 AND 
               SHIP:AIRSPEED <= 1600 {
                SET VNAVMODE TO "ALT".
                SET APMODE TO "ILS".
            }
        }

        // ********
        // ILS MODE
        // ********

        ELSE IF APMODE = "ILS" {
            SET TargetCoord TO TGTRunway.
            //Checks if below GS
            SET TGTAltitude to Glideslope(TGTRunway,GSAng).
            IF ship:altitude < TGTAltitude {
                SET VNAVMODE TO "PIT".
                IF KindOfCraft = "SHUTTLE" { SET TGTPitch TO -GSAng/4. }
                ELSE { SET TGTPitch TO GSAng/4.} 
            }
            ELSE {
                SET VNAVMODE TO "ALT".
            }

            //Checks distance from centerline
            SET CLDist TO CenterLineDistance(TGTRunway).
            IF ABS(CLDist) > 3500 {
                SET LNAVMODE TO "HDG". 
                IF CLDist < 0 {
                    SET TGTHeading to 50.
                }
                ELSE {
                    SET TGTHeading TO 130.
                }
            }
            ELSE IF ABS(CLDist) < 2 {
                SET TGTHeading TO 90.
                SET LNAVMODE TO "HDG". 
            }
            ELSE {
                If ABS(CLDist/15) > 20 {
                    IF CLDist < 0 {
                        SET TGTHeading to 70.
                    }
                    ELSE {
                        SET TGTHeading TO 110.
                    }
                }
                ELSE {
                    SET TGTHeading TO ABS(90 + CLDist/15).
                }
                SET LNAVMODE TO "HDG". 
            }

            // Checks for excessive airspeed on final. 
            IF KindOfCraft = "Plane" {
                SET TGTSpeed to min(180,max(SQRT(TGTAltitude)*4,90)).
                IF ATMODE <> "OFF" {
                    SET ATMODE to "SPD".
                }
            }
            ELSE IF KindOfCraft = "Shuttle" {
                SET TGTSpeed to max(SQRT(TGTAltitude)*10,100).
                SET ATMODE to "OFF".
            }

            IF SHIP:AIRSPEED > TGTSpeed {
                IF NOT BRAKES { BRAKES ON. }
            }
            ELSE {
                IF BRAKES {BRAKES OFF.}
            }
        }
        // **********
        // FLARE MODE
        // **********
        ELSE IF APMODE = "FLR" {
            // Configure Flare mode
            IF VNAVMODE = "ALT" {
                SET VNAVMODE TO "PIT".
                SET TGTHeading TO 90.
                PitchAnglePID:RESET.
                SET ElevatorPID:Kp TO ElevatorPID:Kp*3.
                SET ElevatorPID:Ki to ElevatorPID:Ki/2.
                SET ElevatorPID:Kd to ElevatorPID:Kd*2.
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                SET ATMODE TO "OFF".
            }           
            // Adjust craft flight
            IF RadarAltimeter() > 20 {
                SET TGTPitch to PitchAnglePID:UPDATE(TIME:SECONDS,SHIP:VERTICALSPEED + 5).
                IF SHIP:AIRSPEED > 100 {
                    IF NOT BRAKES { BRAKES ON. }
                }
                ELSE {
                    IF BRAKES {BRAKES OFF.}
                }
            }
            ELSE {
                SET TGTPitch TO 5.
                IF BRAKES {BRAKES OFF.}
                SET LNAVMODE TO "BNK".
                SET TGTBank TO 0.
            }

        }

        // **************************
        // MANUAL MODE WITH AUTO TRIM
        // **************************

        ELSE IF APMODE = "OFF" {
            IF SHIP:CONTROL:PILOTPITCH <> 0 {
                SET Elevator TO SHIP:CONTROL:PILOTPITCH.
                SET ElevatorPID:SETPOINT to PitchAngle().
            }
            ELSE {
                SET SHIP:CONTROL:PITCHTRIM TO ElevatorPID:UPDATE(TIME:SECONDS, PitchAngle() ).
                SET Elevator to 0.
            }
            IF SHIP:CONTROL:PILOTYAW <> 0 {
                SET Aileron TO SHIP:CONTROL:PILOTYAW.
                SET AileronPID:SETPOINT TO min(40,max(-40,BankAngle() )). 
            }
            ELSE {
                SET SHIP:CONTROL:ROLLTRIM TO AileronPID:UPDATE(TIME:SECONDS,BankAngle()).
                SET Aileron to 0.
            }
        }

        // *********************
        // COMMON AUTOPILOT CODE
        // *********************

        // DEAL WITH LNAV
        IF APMODE <> "OFF" {
            IF LNAVMODE = "TGT" {
                SET dHeading TO -TargetCoord:bearing.
                SET AileronPID:SETPOINT to BankAnglePID:UPDATE(TIME:SECONDS,dHeading).
            }
            ELSE IF LNAVMODE = "HDG" {
                SET dHeading TO -DeltaHeading(TGTHeading).
                SET AileronPID:SETPOINT to BankAnglePID:UPDATE(TIME:SECONDS,dHeading).
            }
            ELSE IF LNAVMODE = "BNK" {
                SET AileronPID:SETPOINT TO min(45,max(-45,TGTBank)).
            }

            SET Aileron TO AileronPID:UPDATE(TIME:SECONDS, BankAngle()).

            // DEAL WITH VNAV

            IF VNAVMODE = "ALT" {
                SET dAlt to ship:Altitude - TGTAltitude.
                SET ElevatorPID:SETPOINT TO PitchAnglePID:UPDATE(TIME:SECONDS,dAlt).
            }
            ELSE IF VNAVMODE = "PIT" {
                SET ElevatorPID:SETPOINT to TGTPitch.
            }
            ELSE IF VNAVMODE = "SPU" {
                SET ElevatorPID:SETPOINT to ProgradePitchAngle().
            }
            SET Elevator TO ElevatorPID:UPDATE(TIME:SECONDS, PitchAngle() ).

            // RESET TRIM
            SET SHIP:CONTROL:ROLLTRIM TO 0.
            SET SHIP:CONTROL:PITCHTRIM TO 0.

        }
        // Stall Protection (Stick pusher!)
        IF AoA > MaxAoA(){
            IF VNAVMODE <> "SPU" {
                SET PREVIOUSVNAV TO VNAVMODE.
                SET PREVIOUSLNAV TO LNAVMODE.
                SET PREVIOUSAT TO ATMODE.
                SET PREVIOUSAP TO APMODE.
                SET APMODE TO "NAV".
                SET VNAVMODE TO "SPU".
                SET ATMODE TO "MCT".
                SET LNAVMODE TO "SPU".
                PlayAlarm().
            }
            fbwhud("Stick pusher!").
        }
        ELSE {
            IF VNAVMODE = "SPU" {
                SET VNAVMODE TO PREVIOUSVNAV.
                SET LNAVMODE TO PREVIOUSLNAV.
                SET ATMODE TO PREVIOUSAT.
                SET APMODE TO PREVIOUSAP.                
            }
        }

        
        IF KindOfCraft = "SHUTTLE" {
            SET CTRLIMIT TO min(1,ROUND(240/SHIP:AIRSPEED,2)).
            IF SHIP:ALTITUDE > 18000 { RCS ON .}
            ELSE { RCS OFF .}
        }
        ELSE {
            SET CTRLIMIT TO min(1,ROUND(120/SHIP:AIRSPEED,2)).
        }

        // Ease controls in high speeds
        IF ElevatorPID:MAXOUTPUT <> MIN(1,CTRLIMIT * 1.5) .{
            SET ElevatorPID:MAXOUTPUT TO MIN(1,CTRLIMIT * 1.5) .
            SET ElevatorPID:MINOUTPUT TO MAX (-1,-CTRLIMIT * 1.5) .
        }
        IF AileronPID:MAXOUTPUT <> CTRLIMIT. {
            SET AileronPID:MAXOUTPUT TO CTRLIMIT.
            SET AileronPID:MINOUTPUT TO -CTRLIMIT.
        }


        // Yaw Damper, it works!
        IF YawDamperPID:MAXOUTPUT <> CTRLIMIT * 0.5 .{
            SET YawDamperPID:MAXOUTPUT TO CTRLIMIT * 0.5.
            SET YawDamperPID:MINOUTPUT TO -CTRLIMIT * 0.5.
        }
        SET Rudder TO min(CTRLIMIT,max(-CTRLIMIT,YawDamperPID:UPDATE(TIME:SECONDS, YawError()))).
        IF PitchAngle() < MaxAoA() {
            SET SHIP:CONTROL:YAW TO Rudder.
        }
        else {
            SET SHIP:CONTROL:YAW TO 0.
        }

        // APPLY CONTROLS
        SET SHIP:CONTROL:ROLL TO min(CTRLIMIT,max(-CTRLIMIT,Aileron)). 
        SET SHIP:CONTROL:PITCH TO min(CTRLIMIT,max(-CTRLIMIT,Elevator)).

        // ************
        // AUTOTHROTTLE
        // ************

        IF ATMODE = "SPD" {
            IF NOT AUTOTHROTTLE { SET AUTOTHROTTLE TO TRUE .}
            SET VALUETHROTTLE TO ThrottlePID:UPDATE(TIME:SECONDS,SHIP:AIRSPEED - TGTSpeed).
            LOCK THROTTLE TO VALUETHROTTLE.
        }
        ELSE IF ATMODE = "MCT" {
            IF NOT AUTOTHROTTLE { SET AUTOTHROTTLE TO TRUE .}
            LOCK THROTTLE TO 1.
        }
        ELSE IF ATMODE = "OFF" {
            IF AUTOTHROTTLE {
                UNLOCK THROTTLE.
                SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
                SET AUTOTHROTTLE TO FALSE.
            }
        }

        // ******************
        // COMMON FLIGHT CODE
        // ******************



        // Auto raise/low gear and detect time to flare when landing.
        IF RadarAltimeter() < FLAREALT * 2 {
            IF NOT GEAR { GEAR ON .}
            IF NOT LIGHTS { LIGHTS ON. }
            // CHANGE TO FLARE MODE.

            IF APMODE = "ILS" AND RadarAltimeter() < FLAREALT {
                SET APMODE TO "FLR".
            }
        }
        ELSE {
            IF GEAR { GEAR OFF. }
        }

    }
    ELSE { 
        // *****************************************
        // TOTAL AUTOPILOT SHUTDOWN. SHOW INFO ONLY.
        // *****************************************
        IF NOT APSHUTDOWN {
            SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
            UNLOCK THROTTLE.
            SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
            IF NOT SAS {SAS ON.}
            SET APSHUTDOWN TO TRUE.
        }
    }


    // *********************
    // USER INTERFACE UPDATE
    // *********************

    //ILS VECTORS
    IF checkboxVectors:PRESSED  {
        SET RAMPEND TO latlng(TGTRunway:LAT,TGTRunway:LNG-10).
        SET RAMPENDALT TO TGTRunway:TERRAINHEIGHT + TAN(GSAng) * 10 * (Kerbin:RADIUS * 2 * constant:Pi / 360).
        SET ILSVEC TO VECDRAW(TGTRunway:POSITION(),RAMPEND:ALTITUDEPOSITION(RAMPENDALT+9256),magenta,"",1,true,30).
        // Why +9256? https://imgur.com/a/CPHnD 
    }
    ELSE {
        SET ILSVEC TO VECDRAW().
        PRINT "                            " AT (0,30).
    }

    //GUI ELEMENTS

    IF APSHUTDOWN {
        SET labelMode:text     to "<b><size=17>INP | INP | INP | INP</size></b>".
        SET LabelWaypointDist:text to "".
        SET LabelHDG:TEXT  TO "".
        SET LabelALT:TEXT  TO "".
        SET LabelBNK:TEXT TO "".
        SET LabelPIT:TEXT TO "". 
        SET LabelSPD:TEXT TO "".
    }
    ELSE {
        SET labelMode:text     to "<b><size=17>" + APMODE +" | " + VNAVMODE + " | " + LNAVMODE + " | " + ATMODE +"</size></b>".
        SET LabelWaypointDist:text to ROUND(GroundDistance(TargetCoord)/1000,1) + " km".
        SET LabelHDG:TEXT  TO "<b>" + ROUND(TGTHeading,2):TOSTRING + "º</b>".
        SET LabelALT:TEXT  TO "<b>" + ROUND(TGTAltitude,2):TOSTRING + " m</b>".
        SET LabelBNK:TEXT TO  "<b>" + ROUND(AileronPID:SETPOINT,2) + "º</b>".
        SET LabelPIT:TEXT TO  "<b>" + ROUND(ElevatorPID:SETPOINT,2) + "º</b>".
        SET LabelSPD:TEXT TO  "<b>" + ROUND(TGTSpeed) + " m/s | " + ROUND(MSTOKMH(TGTSpeed),2) + " km/h</b>".
    }
    SET labelAirspeed:text to "<b>Airspeed:</b> " + ROUND(MSTOKMH(SHIP:AIRSPEED)) + " km/h" +
                            " | Mach " + Round(Mach(SHIP:AIRSPEED),3). 
    SET labelVSpeed:text to "<b>Vertical speed:</b> " + ROUND(SHIP:VERTICALSPEED) + " m/s".
    SET labelLAT:text to "<b>LAT:</b> " + ROUND(SHIP:geoposition:LAT,4) + " º".
    SET labelLNG:text to "<b>LNG:</b> " + ROUND(SHIP:geoposition:LNG,4) + " º".
    
    //CONSOLE INFO
    IF CONSOLEINFO {
        PRINT "MODE:" + LNAVMODE AT (0,0). PRINT "YWD ERR:" + ROUND(YawError(),2) + "    " AT (20,0).
        IF APATEnabled {PRINT APMODE + "   " AT (10, 0).} ELSE {PRINT "MANUAL" AT (10,0).}
        PRINT "Pitch angle         " + ROUND(PitchAngle(),2) +          "       "at (0,1).
        PRINT "Target pitch:       " + ROUND(ElevatorPID:SETPOINT,2) +  "       " At (0,2).
        PRINT "AoA Protection      " + ROUND(MaxAoA(),2) +              "       " At (0,3).
        PRINT "AoA:                " + ROUND(AoA(),2) +                 "       " At (0,4).

        PRINT "Bank angle          " + ROUND(BankAngle(),2)          +  "     " AT (0,6).
        PRINT "Target bank:        " + ROUND(AileronPID:SETPOINT,2)  +  "     " At (0,7).
        PRINT "Target bearing:     " + ROUND(-dHeading,2)             +  "     " At (0,8).
        
        PRINT "Ship: Latitude:     " + SHIP:geoposition:LAT AT (0,10).
        PRINT "Ship: Longitude:    " + SHIP:geoposition:LNG AT (0,11).
        PRINT "Ship: Altitude:     " + SHIP:Altitude AT (0,12).
        PRINT "GS Altitude: " + ROUND(Glideslope(TGTRunway,GSAng),2) AT (0,30).
    }
    WAIT 0. //Next loop only in next physics tick 
}
PRINT "LANDED!" AT (0,18).
WAIT 0.5.
IF LandingGear = "Tricicle" {
    SET SHIP:CONTROL:PITCH TO -0.5.
}
ELSE IF LandingGear = "Conventional" {
    SET SHIP:CONTROL:PITCH TO 0.5.
}
WAIT 2.
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
CLEARGUIS().
CHUTES ON.
BRAKES ON.
SAS ON.