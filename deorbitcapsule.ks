
// 0) Be in a circular, zero inclination orbit.
// 1) Calculate a Hohmann Transfer with:
//    - Target altitude = 1% of body radius above ground
// 2) Calculate a phase angle so the periapsis of the new orbit will be right over the landing site
// 3) Take a point 270º before the landing site and do the plane change 
// 4) Do the deorbit burn

PARAMETER Land_Lat TO 91.
PARAMETER Land_Lng TO 361.

runoncepath("lib_ui").
runoncepath("lib_util").

CLEARSCREEN.

SAS OFF.
BAYS OFF.
GEAR OFF.

DrawDebugVectors off.

FUNCTION RadarAltimeter {
    Return ship:altitude - ship:geoposition:terrainheight.
}

FUNCTION TimeToLong {
    PARAMETER lng.

    LOCAL SDAY IS SHIP:BODY:ROTATIONPERIOD. // Duration of Body day in seconds
    LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
    LOCAL P IS SHIP:ORBIT:PERIOD.
    LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Body rotation.
    LOCAL TgtLong IS utilTo360(lng).
    LOCAL ShipLong is utilTo360(SHIP:LONGITUDE). 
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

// ************
// MAIN PROGRAM
// ************

if ship:status = "ORBITING" {

    // Zero the orbit inclination
    IF abs(OBT:INCLINATION) > 0.1 {
        uiBanner("Deorbit","Setting an equatorial orbit").
        RUNPATH("node_inc_equ.ks",0).
        RUNPATH("node.ks").
    }
    // Circularize the orbit
    if obt:eccentricity > 0.01 {
        uiBanner("Deorbit","Circularizing the orbit").
        run circ.
    }

    // Find where to land
    IF Land_Lat >= 91 AND Land_Lng >= 361 { // Means no paramenter was given.
        LOCAL ValidTarget IS False.
        IF HASTARGET {
            IF TARGET:BODY = SHIP:BODY {
                SET ValidTarget TO True.
            }    
        }
        IF ValidTarget {
            SET Land_Lat to utilTo360(TARGET:GEOPOSITION:LAT()).
            SET Land_Lng TO utilTo360(TARGET:GEOPOSITION:LNG()).
        }
        ELSE {
            SET Land_Lat TO 0.
            SET Land_Lng TO utilTo360(SHIP:GEOPOSITION:LNG()).
        }
    }
    SET LandingSite to LATLNG(Land_Lat,Land_Lng).

    //Define the deorbit periapsis
    local DeorbitRad to ship:body:radius*1.02 + LandingSite:terrainheight.

    // Find a phase angle for the landing
    // The landing burning is like a Hohmann transfer, but to an orbit close to the body surface
    local r1 is ship:orbit:semimajoraxis. //Orbit now
    local r2 is DeorbitRad .  // Target orbit
    local pt is 0.5 * ((r1+r2) / (2*r2))^1.5. // How many orbits of a target in the target (deorbit) orbit will do.
    local sp is sqrt( ( 4 * constant:pi^2 * r2^3 ) / body:mu ). // Period of the target orbit.
    local DeorbitTravelTime is pt*sp. // Since ft is a fraction of the 
    // Phi in this case is not the angle between two orbits, but the angle the body rotates during the transit time
    local phi is (DeorbitTravelTime/ship:body:rotationperiod) * 360.

    Set Deorbit_Long to utilTo360(Land_Lng - 180).
    Set PlaneChangeLong to utilTo360(Land_Lng - 270).

    local v is velocityat(ship, TimeToLong(PlaneChangeLong)):orbit.
    local i is LandingSite:lat.
    local TotIncDV is 2 * v:mag * sin(i / 2).    
    local nDv is v:mag * sin(i).
    local pDV is v:mag * (cos(i) - 1 ).

    if TotIncDV > 1 { // Only burn if it matters.
        uiBanner("Deorbit","Burning dV of " + round(TotIncDV,1) + " m/s @ anti-normal to change plane.").
        LOCAL nd IS NODE(time:seconds + TimeToLong(PlaneChangeLong), 0, -nDv, pDv).
        add nd. run node.
    }
 
    local Deorbit_dV is Deorbit_deltaV(DeorbitRad-body:radius).
    uiBanner("Deorbit","Burning dV of " + round(Deorbit_dV,1) + " m/s retrograde to deorbit.").
    LOCAL nd IS NODE(time:seconds + TimeToLong(Deorbit_Long+phi) , 0, 0, Deorbit_dV).
    add nd. run node. 
    uiBanner("Deorbit","Deorbit burn done").

    // Warp about over to landing site
    run warp(eta:periapsis - 120). wait 2.

    // Brake the ship in prepartion to land
    SET BreakingDeltaV to VELOCITYAT(ship,eta:periapsis):orbit:mag.
    uiBanner("Deorbit","Burning dV of " + round(BreakingDeltaV,1) + " m/s retrograde to brake ship.").
    SET ND TO NODE(time:seconds + eta:periapsis , 0, 0, -BreakingDeltaV).
    add nd.
    RUN NODE.
    uiBanner("Deorbit","Brake burn done").

}
ELSE IF SHIP:STATUS = "SUB_ORBITAL" {
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

local tVal is 0.
lock Throttle to tVal.
local sDir is ship:up.
lock steering to sDir.

UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
    WAIT 0.
    // Steer the rocket
    SET ShipVelocity TO SHIP:velocity:surface.
    SET ShipHVelocity to vxcl(SHIP:UP:VECTOR,ShipVelocity).
    Set DFactor TO 0.08. // How much the target position matters when steering. Higher values make landing more precise, but also may make the ship land with too much horizontal speed.
    SET TargetVector to vxcl(SHIP:UP:VECTOR,LandingSite:Position*DFactor).
    SET SteerVector to -ShipVelocity - ShipHVelocity + TargetVector.
    if DrawDebugVectors {
        SET DRAWSV TO VECDRAW(v(0,0,0),SteerVector, red, "Steering", 1, true, 1).
        SET DRAWV TO VECDRAW(v(0,0,0),ShipVelocity, green, "Velocity", 1, true, 1).
        SET DRAWHV TO VECDRAW(v(0,0,0),ShipHVelocity, YELLOW, "Horizontal Velocity", 1, true, 1).
        SET DRAWTV TO VECDRAW(v(0,0,0),TargetVector, Magenta, "Target", 1, true, 1).
    }
        
    set sDir TO SteerVector:Direction. 

    // Throttle the rocket
    set TargetVSpeed to MAX(TouchdownSpeed,sqrt(RadarAltimeter())).

    IF abs(SHIP:VERTICALSPEED) > TargetVSpeed {
        set tVal TO ThrottlePID:UPDATE(TIME:seconds,(SHIP:VERTICALSPEED + TargetVSpeed)).
    }
    ELSE
    {
        set tVal TO 0.
    }

    if DrawDebugVectors { // I know, isn't the debug vectors but helps

        PRINT "Vertical speed " + abs(Ship:VERTICALSPEED) + "                           " at (0,0).
        Print "Target Vspeed  " + TargetVSpeed            + "                           " at (0,1).
        print "Throttle       " + tVal                    + "                           " at (0,2).
        print "Ship Velocity  " + ShipVelocity:MAG        + "                           " at (0,3).
        print "Ship height    " + RadarAltimeter()        + "                           " at (0,4).
        print "                                                                    " at (0,5).

    }
    wait 0.
 }

UNLOCK THROTTLE. UNLOCK STEERING.
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
clearvecdraws().
LADDERS ON.

