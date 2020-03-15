FUNCTION landRadarAltimeter {
	Return ship:altitude - ship:geoposition:terrainheight.
}

FUNCTION landTimeToLong {
	PARAMETER lng.

	LOCAL SDAY IS SHIP:BODY:ROTATIONPERIOD. // Duration of Body day in seconds
	LOCAL KAngS IS 360/SDAY. // Rotation angular speed.
	LOCAL P IS SHIP:ORBIT:PERIOD.
	LOCAL SAngS IS (360/P) - KAngS. // Ship angular speed acounted for Body rotation.
	LOCAL TgtLong IS utilLongitudeTo360(lng).
	LOCAL ShipLong is utilLongitudeTo360(SHIP:LONGITUDE).
	LOCAL DLong IS TgtLong - ShipLong.
	IF DLong < 0 {
		RETURN (DLong + 360) / SAngS.
	}
	ELSE {
		RETURN DLong / SAngS.
	}
}

FUNCTION landDeorbitDeltaV {
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
