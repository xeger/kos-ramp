/////////////////////////////////////////////////////////////////////////////
// Mission: Ascent to Low Kerbin Orbit.
/////////////////////////////////////////////////////////////////////////////
// Launches from Kerbin into a circular orbit barely above the atmosphere.
//
// Can be safely resumed at any point prior to achieving orbit. If you
// resume during descent, it will try and ascend (which probably won't
// do any harm, but you have been warned.)
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

if ship:status = "PRELAUNCH" {
	wait 1.
	uiBanner("Mission", "Launch!").
	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2. // Wait to ship stabilize
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	uiBanner("Mission", "Ascend from " + body:name).
	run launch_asc(body:atm:height + (body:radius / 10)).
}
