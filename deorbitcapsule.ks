PARAMETER Land_Lat TO 91.
PARAMETER Land_Lng TO 361.

CLEARSCREEN.

SAS OFF.
BAYS OFF.
GEAR OFF.

FUNCTION To360 { 
    //From youtube.com/cheerskevin
    PARAMETER lng.
    RETURN MOD(lng + 360, 360).
}

FUNCTION RadarAltimeter {
    Return ship:altitude - ship:geoposition:terrainheight.
}

FUNCTION TimeToLong {
    PARAMETER lng.

    LOCAL SDAY IS SHIP:BODY:ROTATIONPERIOD. // Duration of Body day in seconds
    LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
    LOCAL P IS SHIP:ORBIT:PERIOD.
    LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Body rotation.
    LOCAL TgtLong IS To360(lng).
    LOCAL ShipLong is To360(SHIP:LONGITUDE). 
    LOCAL DLong IS TgtLong - ShipLong. 
    IF DLong < 0 {
        RETURN (DLong + 360) / SAngS. 
    }
    ELSE {
        RETURN DLong / SAngS.
    }
}

FUNCTION Deorbit_deltaV {
    parameter alt.
    // From node_apo.ks
    local mu is body:mu.
    local br is body:radius.

    // present orbit properties
    local vom is ship:obt:velocity:orbit:mag.      // actual velocity
    local r is br + altitude.                      // actual distance to body
    local ra is r.                                 // radius at burn apsis
    //local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
    local v1 is vom.
    // true story: if you name this "a" and call it from circ_alt, its value is 100,000 less than it should be!
    local sma1 is obt:semimajoraxis.

    // future orbit properties
    local r2 is br + periapsis.                    // distance after burn at periapsis
    local sma2 is (alt + 2*br + periapsis)/2. // semi major axis target orbit
    local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

    // create node
    local deltav is v2 - v1.
    return deltav.
}

FUNCTION ShipAcc {
    
        FUNCTION HasSensors { 
        // Checks if ship have required sensors:
        // - Accelerometer (Double-C Seismic Accelerometer) 
        // - Gravity Sensor (GRAVMAX Negative Gravioli Detector)
        LOCAL HasA IS False.
        LOCAL HasG IS False.
        LIST SENSORS IN SENSELIST.
        FOR S IN SENSELIST {
        IF S:TYPE = "ACC" { SET HasA to True. }
        IF S:TYPE = "GRAV" { SET HasG to True. }
        }
        IF HasA AND HasG { RETURN TRUE. }
        ELSE { RETURN FALSE. }
        }

    // Checks if ship has an accelerometer
    if HasSensors {
        return ship:sensors:acc.
    }
    else { // Calculete by hand
        local v1 is ship:velocity:surface:mag.
        local t1 is time:seconds.
        wait 0.5. // Unfortunatelly needs to wait some time to accuratelly calculate the acceleration.
        local v2 is ship:velocity:surface:mag.
        local t2 is time:seconds.
        local scalaracc to (v2-v1)/(t2-t1).
        return ship:velocity:surface:normalized * scalaracc.
    }
}

//  Torricelli equation
FUNCTION TorricelliEquation { 
    PARAMETER V0.  // Initial speed
    PARAMETER ACC. // Acceleration
    PARAMETER dS.  // Distance
    LOCAL SQUARE IS v0^2 + 2*Acc * dS .// Intermediate term
    IF SQUARE >=0 {
        RETURN SQRT(SQUARE). // Final speed
    }
    ELSE {
        RETURN -SQRT(ABS(SQUARE)).
    }
}

// ************
// MAIN PROGRAM
// ************

if ship:status = "ORBITING" {


    // Find where to land
    IF Land_Lat >= 91 AND Land_Lng >= 361 { // Means no paramenter was given.
        LOCAL ValidTarget IS False.
        IF HASTARGET {
            IF TARGET:BODY = SHIP:BODY {
                SET ValidTarget TO True.
            }    
        }
        IF ValidTarget {
            SET Land_Lat to To360(TARGET:GEOPOSITION:LAT()).
            SET Land_Lng TO To360(TARGET:GEOPOSITION:LNG()).
        }
        ELSE {
            SET Land_Lat TO 0.
            SET Land_Lng TO To360(SHIP:GEOPOSITION:LNG() + 90).
        }
    }
    SET LandingSite to LATLNG(Land_Lat,Land_Lng).

    // Find parking orbit
    Set Deorbit_Long to To360(Land_Lng - 90).
    SET Deorbit_Inc to 0.
    SET Deorbit_Alt to 0.
    IF BODY:ATM:EXISTS {
        SET Deorbit_Alt to BODY:RADIUS * 0.1 + BODY:ATM:HEIGHT.
    }
    ELSE {
        SET Deorbit_Alt to BODY:RADIUS * 0.3.
    }

    // Fly to parking orbit
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
    local IncDV is 2 * ship:velocity:orbit:mag * sin(LandingSite:LAT / 2).
    LOCAL nd IS NODE(time:seconds + TimeToLong(Deorbit_Long), 0, IncDV, 0).
    add nd.
    RUN NODE. 
    local Deorbit_dV is Deorbit_deltaV(-BODY:RADIUS*0.05). 
    LOCAL nd IS NODE(time:seconds + 2, 0, 0, Deorbit_dV).
    add nd.
    RUN NODE. 
    PRINT "Deorbit burn done.".

    // Warp about over to landing site
    SET timetowarp TO time:seconds + TimeToLong(ship:geoposition:lng + 85).
    kuniverse:timewarp:warpto(timetowarp).
    wait until kuniverse:timewarp:issettled and time:seconds > timetowarp.

    FUNCTION GroundDistance {
        // Returns distance to a point in ground from the ship's ground position (ignores altitude)
        PARAMETER TgtPos.
        RETURN vxcl(up:vector, TgtPos:Position):mag.
    }

    FUNCTION AirDistance {
        PARAMETER TgtPos.
        RETURN TgtPos:AltitudePosition(SHIP:altitude):mag.
    }

    // Breaks (most) speed over landing site
    // Figures how much time to fly over the landing site
    set TimeToBurn to -1.
    until TimeToBurn > 0 {
        SET HDist to (AirDistance(LandingSite)*2 + GroundDistance(LandingSite)) / 3. //Approximation 
        SET Acceleration TO shipacc.
        SET ShipVelocity to ship:velocity:surface.
        SET HAcc to vxcl(SHIP:UP:VECTOR,Acceleration):mag.
        SET HSpd0 to vxcl(SHIP:UP:VECTOR,ShipVelocity):mag.
        SET HSpdF to TorricelliEquation(HSpd0,HAcc,HDist).
        SET TimeToBurn to (HSpdF - HSpd0)/HAcc. 
        print "Dist          " + HDist.
        print "v0            " + HSpd0.
        print "vF            " + HSpdF.
        print "Acc           " + HAcc.
        print "Time          " + TimeToBurn. wait 1.
    }.
    SET BreakingDeltaV to ShipVelocity:mag + Acceleration:mag * TimeToBurn.
    SET ND TO NODE(time:seconds + TimeToBurn , 0, 0, -BreakingDeltaV).
    add nd.
    RUN NODE.
    Print "Braking burn done.".

}
ELSE IF SHIP:STATUS = "SUBORBITAL" {
    LOCK LandingSite TO SHIP:GEOPOSITION.
}

// Try to land
SET TouchdownSpeed to 2.

//PID Throttle
SET ThrottlePID to PIDLOOP(0.04,0.001,0.01). // Kp, Ki, Kd
SET ThrottlePID:MAXOUTPUT TO 1.
SET ThrottlePID:MINOUTPUT TO 0.
SET ThrottlePID:SETPOINT TO 0. 

SAS OFF.
RCS OFF.
LEGS ON.

UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
    WAIT 0.
    // Steer the rocket
    SET ShipVelocity TO SHIP:velocity:surface.
    SET ShipHVelocity to vxcl(SHIP:UP:VECTOR,ShipVelocity).
    Set DFactor TO 0.05. 
    SET TargetVector to vxcl(SHIP:UP:VECTOR,LandingSite:Position*DFactor).
    SET SteerVector to -ShipVelocity - ShipHVelocity + TargetVector.
    SET DRAWSV TO VECDRAW(v(0,0,0),SteerVector, red, "", 1, true, 1).
    SET DRAWV TO VECDRAW(v(0,0,0),ShipVelocity, green, "", 1, true, 1).
    SET DRAWHV TO VECDRAW(v(0,0,0),ShipHVelocity, YELLOW, "", 1, true, 1).
    SET DRAWTV TO VECDRAW(v(0,0,0),TargetVector, Magenta, "", 1, true, 1).
        
    LOCK STEERING TO SteerVector:Direction. 

    // Throttle the rocket
    set TargetVSpeed to MAX(TouchdownSpeed,sqrt(RadarAltimeter())).

    IF abs(SHIP:VERTICALSPEED) > TargetVSpeed {
        LOCK THROTTLE TO ThrottlePID:UPDATE(TIME:seconds,(SHIP:VERTICALSPEED + TargetVSpeed)).
    }
    ELSE
    {
        LOCK THROTTLE TO 0.
    }

    PRINT "Vertical speed            " + Ship:VERTICALSPEED + "                           " at (0,0).
    Print "Target Vspeed             " + TargetVSpeed       + "                           " at (0,1).
    print "Throttle                  " + Throttle           + "                           " at (0,2).
    print "Ship Velocity             " + ShipVelocity:MAG   + "                           " at (0,3).
    print "Distance                  " + RadarAltimeter()   + "                           " at (0,4).
    wait 0.
 }

UNLOCK THROTTLE. UNLOCK STEERING.
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
LADDERS ON.

