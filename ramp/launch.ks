@lazyglobal off.
/////////////////////////////////////////////////////
// Just decide if is better to use launch_asc or launch_ssto
/////////////////////////////////////////////////////
parameter Apo is 200000.
parameter hdg is 90.


if KUniverse:origineditor = "SPH" or ship:name:contains("SSTO") {
	runpath("launch_ssto", apo, hdg).
} else {
	runpath("launch_asc", apo, hdg).
}
