/////////////////////////////////////////////////////////////////////////////
// Circularize to altitude.
/////////////////////////////////////////////////////////////////////////////
// (Re)circularizes at a designated altitude, immediately if possible, else
// at the next apsis.
/////////////////////////////////////////////////////////////////////////////

parameter alt.

if obt:eccentricity < 0.001 { // For (almost) circular orbits, just change the altitude and recircularize
	run node_alt(alt).
	local prograde is nextnode:prograde.
	run node({run node_alt(alt).}).

	if prograde < 0 { // Means it raised the apoapsis
		run node({run node_apo(obt:periapsis).}).
	} else {
		run node({run node_peri(obt:apoapsis).}).
	}
} else { // For eliptical orbits
	// Added by FellipeC
	if alt > obt:periapsis {
		// Decrease apoapsis
		run node({run node_apo(alt).}).
		run node({run node_peri(alt).}).
	} else {
		// Decresase periapsis
		run node({run node_peri(alt).}).
		run node({run node_apo(alt).}).
	}
}
