/////////////////////////////////////////////////////////////////////////////
// Circularize to altitude.
/////////////////////////////////////////////////////////////////////////////
// (Re)circularizes at a designated altitude, immediately if possible, else
// at the next apsis.
/////////////////////////////////////////////////////////////////////////////

parameter circAlt.

if obt:eccentricity < 0.001 { // For (almost) circular orbits, just change the altitude and recircularize
	run node_alt(circAlt).
	local prg is nextnode:prograde.
	run node({run node_alt(circAlt).}).

	if prg < 0 { // Means it raised the apoapsis
		run node({run node_apo(obt:periapsis).}).
	} else {
		run node({run node_peri(obt:apoapsis).}).
	}
} else { // For eliptical orbits
	// Added by FellipeC
	if circAlt > obt:periapsis {
		// Decrease apoapsis
		run node({run node_apo(circAlt).}).
		run node({run node_peri(circAlt).}).
	} else {
		// Decresase periapsis
		run node({run node_peri(circAlt).}).
		run node({run node_apo(circAlt).}).
	}
}
