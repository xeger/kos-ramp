function landRadarAltimeter {
	return ship:altitude - ship:geoposition:terrainheight.
}

function landTimeToLong {
	parameter lng.

	local sday is ship:body:rotationperiod. // Duration of Body day in seconds
	local KAngS is 360 / sday. // Rotation angular speed.
	local P is ship:orbit:period.
	local SAngS is (360 / P) - KAngS. // Ship angular speed acounted for Body rotation.
	local TgtLong is utilLongitudeTo360(lng).
	local ShipLong is utilLongitudeTo360(ship:longitude).
	local DLong is TgtLong - ShipLong.
	if DLong < 0 {
		return (DLong + 360) / SAngS.
	} else {
		return DLong / SAngS.
	}
}

function landDeorbitDeltaV {
	parameter alt.
	// From node_apo
	local mu is body:mu.
	local br is body:radius.

	// present orbit properties
	local vom is ship:obt:velocity:orbit:mag.      // actual velocity
	local r is br + altitude.                      // actual distance to body
	local ra is r.                                 // radius at burn apsis
	// local v1 is sqrt( vom ^ 2 + 2 * mu * (1 / ra - 1 / r) ). // velocity at burn apsis
	local v1 is vom.
	// true story: if you name this "a" and call it from circ_alt, its value is 100, 000 less than it should be!
	local sma1 is obt:semimajoraxis.

	// future orbit properties
	local r2 is br + periapsis. // distance after burn at periapsis
	local sma2 is (alt + 2 * br + periapsis) / 2. // semi major axis target orbit
	local v2 is sqrt( vom ^ 2 + (mu * (2 / r2 - 2 / r + 1 / sma1 - 1 / sma2 ) ) ).

	// create node
	local deltav is v2 - v1.
	return deltav.
}
