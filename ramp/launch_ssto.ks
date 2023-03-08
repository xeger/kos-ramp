@lazyglobal off.
// Parameters
Parameter TGTApoapsis is 150000.
Parameter TGTHeading is 90.

// Libraries
runoncepath("lib_ui").
runoncepath("lib_parts").

// Global Variables.
global LaunchSPV0 is ship:airspeed.
global LaunchSPT0 is time:seconds.

// Local Variables.
Local TGTClimbAcc is 5.             // Acceleration in m/s² the ship try to keep during climb
Local ClimbTick is 0.25.            // Time between each loop run
Local ClimbDefaultPitch is 20.      // Default climb pitch
Local GTAltitude is 45000.          // End of "Gravit turn" (When ship will fly with pitch 0 until apoapsis)
Local AirBreathingAlt is 23000.     // From this altitude and up, dual-mode engines will change to closed cycle.
Local ThrottleValue is 0.

// Functions.
function ClimbAcc {
	if time:seconds - LaunchSPT0 > 0 return (ship:airspeed - LaunchSPV0 ) / (time:seconds - LaunchSPT0).
	else return 0.
}

function ascentThrottleSSTO {
	// Ease thottle when near the Apoapsis
	local ApoPercent is ship:obt:apoapsis / TGTApoapsis.
	local ApoCompensation is 0.
	if ApoPercent > 0.9 set ApoCompensation to (ApoPercent - 0.9) * 10.
	return 1 - min(0.95, max(0, ApoCompensation)).
}

when ship:altitude > AirBreathingAlt then {
	partsMMEngineClosedCycle().
	return false.
}

// PID Loop.
local CLimbPitchPID is pidloop(1, 0.4, 0.6,-10, 10). // kP, kI, kD, Min, Max
set CLimbPitchPID:SetPoint to 0.

// Main program

// Take off
uiBanner("SSTO", "Take off...").
Set ThrottleValue to 1.
lock throttle to ThrottleValue.
stage.
lock steering to heading(90, 0).
wait until ship:airspeed > 90.
uiBanner("SSTO", "Rotate...").
lock steering to heading(90, 10).
wait until ship:altitude > 100.
GEAR off.
uiBanner("SSTO", "Positive climb, gear up.").

// Climb to Apoapsis
Local PitchAngle is ClimbDefaultPitch.

Local PitchByAcc is 0.
Local PitchByGT is 0.

Lock Steering to Heading (TGTHeading, PitchAngle).
Lock PercentGT to min( 1, ship:altitude / GTAltitude).

until ship:apoapsis > TGTApoapsis {
	set LaunchSPT0 to time:seconds.
	set LaunchSPV0 to ship:airspeed.
	set ThrottleValue to ascentThrottleSSTO().
	wait ClimbTick.

	set PitchByGT to ArcCos(PercentGT).
	set PitchByAcc to ClimbDefaultPitch + CLimbPitchPID:update(time:seconds, TGTClimbAcc - ClimbAcc()).

	set PitchAngle to min(PitchByGT, PitchByAcc).
}
Set ThrottleValue to 0.

until ship:altitude > body:atm:height {
	if ship:obt:apoapsis < TGTApoapsis Set ThrottleValue to ascentThrottleSSTO().
	else set ThrottleValue to 0.
	wait ClimbTick.
}

Unlock Steering.
Unlock Throttle.

Panels On.
Fuelcells On.
Radiators On.
uiBanner("SSTO", "Circularizing...").
run circ.
