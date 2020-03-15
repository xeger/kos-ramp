/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall. Try to avoid a rapid unplanned disassemble.
// Warranty void if used with air
//
// Usage: RUN LANDVAC(<mode>,<latitude>,<longitude>).
//
//       Parameters:
//          <mode>: Can be TARG, COOR or SHIP.
//                  -TARG (default) will try to land on the selected target.
//                  If has no valid target falls back to SHIP.
//                  -COOR will try to land on <latitude> and <longitude>.
//                  -SHIP will try to land in the coordinates that ship is
//                  flying over when the program start.
/////////////////////////////////////////////////////////////////////////////


// General logic:
// 0) Be in a circular, zero inclination orbit.
// 1) Calculate a Hohmann Transfer with:
//    - Target altitude = 1% of body radius above ground
// 2) Calculate a phase angle so the periapsis of the new orbit will be right over the landing site
// 3) Take a point 270º before the landing site and do the plane change
// 4) Do the deorbit burn

// LandMode defines how this program will work
PARAMETER LandMode is "TARG".
PARAMETER LandLat is ship:geoposition:lat.
PARAMETER LandLng is ship:geoposition:lng.

runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_land").

SAS OFF.
BAYS OFF.
GEAR OFF.
LADDERS OFF.

DrawDebugVectors off.



// ************
// MAIN PROGRAM
// ************


// DEORBIT SEQUENCE
if ship:status = "ORBITING" {

	if body:atm:exists uiWarning("Deorbit", "Warning: Warranty void, used with atmosphere!").

// Zero the orbit inclination
	IF abs(OBT:INCLINATION) > 0.1 {
		uiBanner("Deorbit", "Setting an equatorial orbit").
		RUNPATH("node_inc_equ.ks", 0).
		RUNPATH("node.ks").
	}
// Circularize the orbit
	if obt:eccentricity > 0.01 {
		uiBanner("Deorbit", "Circularizing the orbit").
		run circ.
	}

// Find where to land
	if LandMode:contains("TARG") {
		if hastarget and TARGET:BODY = SHIP:BODY { // Make sure have a target in the same planet at least! Note it doesn't check if target is landed/splashed, will just use it's position, for all it cares.
			set LandLat to utilLongitudeTo360(TARGET:GEOPOSITION:LAT).
			set LandLng to utilLongitudeTo360(TARGET:GEOPOSITION:LNG).
		} else {
			set LandLat to utilLongitudeTo360(ship:geoposition:lat).
			set LandLng to utilLongitudeTo360(ship:geoposition:lng).
		}
	} else if LandMode:contains("COOR") {
		set LandLat to utilLongitudeTo360(LandLat).
		set LandLng to utilLongitudeTo360(LandLng).
	} else if LandMode:contains("SHIP") {
		set LandLat to utilLongitudeTo360(ship:geoposition:lat).
		set LandLng to utilLongitudeTo360(ship:geoposition:lng).
	} else {
		uiFatal("Land", "Invalid mode").
	}

	SET LandingSite to LATLNG(LandLat, LandLng).

	// Define the deorbit periapsis
	local DeorbitRad to max(5000 + ship:body:radius, (ship:body:radius * 1.02 + LandingSite:terrainheight)).

	// Find a phase angle for the landing
	// The landing burning is like a Hohmann transfer, but to an orbit close to the body surface
	local r1 is ship:orbit:semimajoraxis.                               // Orbit now
	local r2 is DeorbitRad .                                            // Target orbit
	local pt is 0.5 * ((r1 + r2) / (2 * r2)) ^ 1.5.                     // How many orbits of a target in the target (deorbit) orbit will do.
	local sp is sqrt( ( 4 * constant:pi ^ 2 * r2 ^ 3 ) / body:mu ).     // Period of the target orbit.
	local DeorbitTravelTime is pt * sp.                                 // Transit time
	local phi is (DeorbitTravelTime / ship:body:rotationperiod) * 360.  // Phi in this case is not the angle between two orbits, but the angle the body rotates during the transit time
	local IncTravelTime is ship:obt:period / 4.                         // Travel time between change of inclinationa and lower perigee
	local phiIncManeuver is (IncTravelTime / ship:body:rotationperiod) * 360.

	// Deorbit and plane change longitudes
	Set Deorbit_Long to utilLongitudeTo360(LandLng - 180).
	Set PlaneChangeLong to utilLongitudeTo360(LandLng - 270).

	// Plane change for landing site
	local vel is velocityat(ship, landTimeToLong(PlaneChangeLong)):orbit.
	local inc is LandingSite:lat.
	local TotIncDV is 2 * vel:mag * sin(inc / 2).
	local nDv is vel:mag * sin(inc).
	local pDV is vel:mag * (cos(inc) - 1 ).

	if TotIncDV > 0.1 { // Only burn if it matters.
		uiBanner("Deorbit", "Burning dV of " + round(TotIncDV, 1) + " m/s @ anti-normal to change plane.").
		LOCAL nd IS NODE(time:seconds + landTimeToLong(PlaneChangeLong + phiIncManeuver), 0, -nDv, pDv).
		add nd. run node.
	}

	// Lower orbit over landing site
	local Deorbit_dV is landDeorbitDeltaV(DeorbitRad - body:radius).
	uiBanner("Deorbit", "Burning dV of " + round(Deorbit_dV, 1) + " m/s retrograde to deorbit.").
	LOCAL nd IS NODE(time:seconds + landTimeToLong(Deorbit_Long + phi) , 0, 0, Deorbit_dV).
	add nd. run node.
	uiBanner("Deorbit", "Deorbit burn done").
	wait 5. // Let's have some time to breath and look what's happening

	// Brake the ship to finally deorbit.
	SET BreakingDeltaV to VELOCITYAT(ship, time:seconds + eta:periapsis):orbit:mag.
	uiBanner("Deorbit", "Burning dV of " + round(BreakingDeltaV, 1) + " m/s retrograde to brake ship.").
	SET ND TO NODE(time:seconds + eta:periapsis , 0, 0, -BreakingDeltaV).
	add nd.
	RUN NODE.
	uiBanner("Deorbit", "Brake burn done").

} ELSE IF SHIP:STATUS = "SUB_ORBITAL" {
	LOCK LandingSite TO SHIP:GEOPOSITION.
}

// Try to land
if ship:status = "SUB_ORBITAL" or ship:status = "FLYING" {
	SET TouchdownSpeed to 2.

	// PID Throttle
	SET ThrottlePID to PIDLOOP(0.04, 0.001, 0.01). // Kp, Ki, Kd
	SET ThrottlePID:MAXOUTPUT TO 1.
	SET ThrottlePID:MINOUTPUT TO 0.
	SET ThrottlePID:SETPOINT TO 0.

	SAS OFF.
	RCS OFF.
	LIGHTS ON. // We want the Kerbals to see where they are going right?
	LEGS ON. // This is important!

	// Throttle and Steering
	local tVal is 0.
	lock Throttle to tVal.
	local sDir is ship:up.
	lock steering to sDir.

	// Main landing loop
	UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" {
		WAIT 0.
		// Steer the rocket
		SET ShipVelocity TO SHIP:velocity:surface.
		SET ShipHVelocity to vxcl(SHIP:UP:VECTOR, ShipVelocity).
		Set DFactor TO 0.08. // How much the target position matters when steering. Higher values make landing more precise, but also may make the ship land with too much horizontal speed.
		SET TargetVector to vxcl(SHIP:UP:VECTOR, LandingSite:Position * DFactor).
		SET SteerVector to -ShipVelocity - ShipHVelocity + TargetVector.
		if DrawDebugVectors {
			SET DRAWSV TO VECDRAW(v(0, 0, 0), SteerVector, red, "Steering", 1, true, 1).
			SET DRAWV TO VECDRAW(v(0, 0, 0), ShipVelocity, green, "Velocity", 1, true, 1).
			SET DRAWHV TO VECDRAW(v(0, 0, 0), ShipHVelocity, YELLOW, "Horizontal Velocity", 1, true, 1).
			SET DRAWTV TO VECDRAW(v(0, 0, 0), TargetVector, Magenta, "Target", 1, true, 1).
		}

		set sDir TO SteerVector:Direction.

		// Throttle the rocket
		set TargetVSpeed to MAX(TouchdownSpeed, sqrt(landRadarAltimeter())).

		IF abs(SHIP:VERTICALSPEED) > TargetVSpeed {
			set tVal TO ThrottlePID:UPDATE(TIME:seconds, (SHIP:VERTICALSPEED + TargetVSpeed)).
		} ELSE {
			set tVal TO 0.
		}

		if DrawDebugVectors { // I know, isn't the debug vectors but helps
			PRINT "Vertical speed " + abs(Ship:VERTICALSPEED) + "                           " at (0, 0).
			Print "Target Vspeed  " + TargetVSpeed            + "                           " at (0, 1).
			print "Throttle       " + tVal                    + "                           " at (0, 2).
			print "Ship Velocity  " + ShipVelocity:MAG        + "                           " at (0, 3).
			print "Ship height    " + landRadarAltimeter()    + "                           " at (0, 4).
			print "                                                                    " at (0, 5).
		}
		wait 0.
	}

	UNLOCK THROTTLE. UNLOCK STEERING.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	clearvecdraws().
	LADDERS ON.
	SAS ON. // Helps to don't tumble after landing
} else if ship:status = "ORBITING" uiError("Land", "This ship is still in orbit!?").
else if ship:status = "LANDED" or ship:status = "SPLASHED" uiError("Land", "We are already landed, nothing to do here, move along").
else uiError("Land", "Can't land from " + ship:status).
