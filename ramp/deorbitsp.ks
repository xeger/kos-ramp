parameter DeorbitLongOffset is 0. // Diference from the default deorbit longitude.

runoncepath("lib_ui").
runoncepath("lib_parts").
runoncepath("lib_util").
SAS off.

function LngToDegrees {
	// From youtube.com/cheerskevin
	parameter lng.
	return mod(lng + 360, 360).
}

function TimeToLong {
	parameter lng.

	local sday is body("KERBIN"):rotationperiod. // Duration of Kerbin day in seconds
	local KAngS is 360 / sday. // Rotation angular speed.
	local P is ship:orbit:period.
	local SAngS is (360 / P) - KAngS. // Ship angular speed acounted for Kerbin rotation.
	local TgtLong is LngToDegrees(lng).
	local ShipLong is LngToDegrees(ship:longitude).
	local DLong is TgtLong - ShipLong.
	if DLong < 0 {
		return (DLong + 360) / SAngS.
	} else {
		return DLong / SAngS.
	}
}

set Deorbit_Long to -149.8 + DeorbitLongOffset.
set Deorbit_dV to -110.
set Deorbit_Inc to 0.
set Deorbit_Alt to 80000.

SAS off.
set orbitok to false.
set incok to false.

until orbitok and incok {
	// Check if orbit is acceptable and correct if needed.

	if not (obt:inclination < (Deorbit_Inc + 0.1) and
					obt:inclination > (Deorbit_Inc - 0.1)) {
		uiBanner("Deorbit", "Changing inclination from " + round(obt:inclination, 2) +
						"º to " + round(Deorbit_Inc, 2) + "º").
		runpath("node_inc_equ", Deorbit_Inc).
		runpath("node").
	} else { set incok to true.}

	if not (obt:apoapsis < (Deorbit_Alt + Deorbit_Alt * 0.05) and
					obt:apoapsis > (Deorbit_Alt - Deorbit_Alt * 0.05) and
					obt:eccentricity < 0.1 ) {
		uiBanner("Deorbit", "Establishing a new orbit at " + round(Deorbit_Alt / 1000) + "km" ).
		runpath("circ_alt", Deorbit_Alt).
	} else { set orbitok to true. }

}
unlock steering. unlock throttle. wait 5.

// Add Deorbit maneuver node.
uiBanner("Deorbit", "Doing the deorbit burn").
local nd is node(time:seconds + TimeToLong(Deorbit_Long), 0, 0, Deorbit_dV).
add nd. run node.

// Configure the ship to reenter.
PANELS off.
BAYS off.
GEAR off.
LADDERS off.
SAS off.
RCS on.
partsDisarmsChutes().
partsRetractAntennas().
partsRetractRadiators().

lock throttle to 0.
uiBanner("Deorbit", "Holding 40º Pitch until 35000m").
lock steering to heading(90, 40).
wait until utilIsShipFacing(heading(90, 40):Vector).
set kuniverse:timewarp:mode to "RAILS".
set kuniverse:timewarp:warp to 2.
wait until ship:altitude < 71000.
kuniverse:timewarp:cancelwarp().
wait until ship:altitude < 35000.
uiBanner("Deorbit", "Holding -3º Pitch until 30000m").
lock steering to heading(90,-3).
wait until ship:altitude < 30000.
uiBanner("Deorbit", "Preparing atmospheric autopilot...").
unlock throttle.
unlock steering.
SAS on.
run fly("SHUTTLE").
