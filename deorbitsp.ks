PARAMETER Deorbit_Long_Offset IS 0. // Diference from the default deorbit longitude.

CLEARSCREEN.


SAS OFF.
BAYS OFF.
GEAR OFF.

FUNCTION LngToDegrees { 
    //From youtube.com/cheerskevin
    PARAMETER lng.
    RETURN MOD(lng + 360, 360).
}

FUNCTION TimeToLong {
    PARAMETER lng.

    LOCAL SDAY IS BODY("KERBIN"):ROTATIONPERIOD. // Duration of Kerbin day in seconds
    LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
    LOCAL P IS SHIP:ORBIT:PERIOD.
    LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Kerbin rotation.
    LOCAL TgtLong IS LngToDegrees(lng).
    LOCAL ShipLong is LngToDegrees(SHIP:LONGITUDE). 
    LOCAL DLong IS TgtLong - ShipLong. 
    IF DLong < 0 {
        RETURN (DLong + 360) / SAngS. 
    }
    ELSE {
        RETURN DLong / SAngS.
    }
}

SET Deorbit_Long TO -149.8 + Deorbit_Long_Offset.
SET Deorbit_dV TO -110. 
SET Deorbit_Inc to 0.
SET Deorbit_Alt to 80000.

SAS OFF.
LOCK STEERING TO LOOKDIRUP(RETROGRADE:VECTOR,UP:VECTOR). 
wait until (vdot(facing:forevector, RETROGRADE:VECTOR) >= 0.995). WAIT 15.
SET ORBITOK TO FALSE.
SET INCOK TO FALSE.

UNTIL ORBITOK AND INCOK {

    // Check if orbit is acceptable and correct if needed.

    IF NOT (OBT:INCLINATION < (Deorbit_Inc + 1) AND 
            OBT:INCLINATION > (Deorbit_Inc - 1)) {
                RUNPATH("node_inc_equ.ks",Deorbit_Inc).
                RUNPATH("node.ks").
            }
    ELSE { SET INCOK TO TRUE.}

    IF NOT (OBT:APOAPSIS < (Deorbit_Alt + Deorbit_Alt*0.05) AND 
            OBT:APOAPSIS > (Deorbit_Alt - Deorbit_Alt*0.05) AND
            OBT:eccentricity < 0.1 ) {
                RUNPATH("circ_alt.ks",Deorbit_Alt).
    }
    ELSE { SET ORBITOK TO TRUE. }

}
UNLOCK STEERING. UNLOCK THROTTLE. WAIT 5.

// Add Deorbit maneuver node.
LOCAL nd IS NODE(time:seconds + TimeToLong(Deorbit_Long), 0, 0, Deorbit_dV).
ADD nd. RUN NODE.
PRINT "Deorbit burn done.".

PANELS OFF.
BAYS OFF.
GEAR OFF.
LADDERS OFF.
SAS OFF.
RCS ON.
LOCK THROTTLE TO 0.
PRINT "Holding 40º Pitch until 35000m".
LOCK STEERING TO HEADING(90,40).
WAIT 10.
SET KUNIVERSE:TIMEWARP:MODE TO "RAILS".
SET KUNIVERSE:TIMEWARP:WARP to 2.
WAIT UNTIL SHIP:ALTITUDE < 71000.
KUNIVERSE:TIMEWARP:CANCELWARP().
WAIT UNTIL SHIP:ALTITUDE < 35000.
PRINT "Holding -3º Pitch until 30000m".
LOCK STEERING TO HEADING(90,-3).
WAIT UNTIL SHIP:ALTITUDE < 30000.
PRINT "Preparing autopilot...".
UNLOCK THROTTLE.
UNLOCK STEERING.
SAS ON.
run fly("SHUTTLE").