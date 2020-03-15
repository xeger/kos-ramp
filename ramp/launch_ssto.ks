@lazyglobal off.
// Parameters
Parameter TGTApoapsis is 150000.
Parameter TGTHeading is 90.

// Libraries
runoncepath("lib_ui").
runoncepath("lib_parts").

// Global Variables.
global LaunchSPV0 is ship:AIRSPEED.
global LaunchSPT0 is time:SECONDS.

// Local Variables.
Local TGTClimbAcc is 5.             // Acceleration in m/s² the ship try to keep during climb
Local ClimbTick is 0.25.            // Time between each loop run
Local ClimbDefaultPitch is 20.      // Default climb pitch
Local GTAltitude is 45000.          // End of "Gravit turn" (When ship will fly with pitch 0 until apoapsis)
Local AirBreathingAlt is 23000.     // From this altitude and up, dual-mode engines will change to closed cycle.
Local ThrottleValue is 0.

// Functions.
function ClimbAcc {
	if time:SECONDS - LaunchSPT0 > 0 return (SHIP:AIRSPEED - LaunchSPV0 ) / (TIME:SECONDS - LaunchSPT0).
	else Return 0.
}

function ascentThrottle {
	// Ease thottle when near the Apoapsis
	local ApoPercent is ship:obt:apoapsis / TGTApoapsis.
	local ApoCompensation is 0.
	if ApoPercent > 0.9 set ApoCompensation to (ApoPercent - 0.9) * 10.
	return 1 - min(0.95, max(0, ApoCompensation)).
}

when Ship:Altitude > AirBreathingAlt then {
	partsMMEngineClosedCycle().
	Return False.
}

// PID Loop.
local CLimbPitchPID is PIDLOOP(1, 0.4, 0.6,-10, 10). // kP, kI, kD, Min, Max
set CLimbPitchPID:SetPoint to 0.

// Main program

// Take off
uiBanner("SSTO", "Take off...").
Set ThrottleValue to 1.
LOCK THROTTLE TO ThrottleValue.
STAGE.
LOCK STEERING TO HEADING(90, 0).
WAIT UNTIL SHIP:AIRSPEED > 90.
uiBanner("SSTO", "Rotate...").
LOCK STEERING TO HEADING(90, 10).
WAIT UNTIL SHIP:ALTITUDE > 100.
GEAR OFF.
uiBanner("SSTO", "Positive climb, gear up.").

// Climb to Apoapsis
Local PitchAngle is ClimbDefaultPitch.

Local PitchByAcc is 0.
Local PitchByGT is 0.

Lock Steering to Heading (TGTHeading, PitchAngle).
Lock PercentGT to MIN( 1, SHIP:ALTITUDE / GTAltitude).

UNTIL SHIP:Apoapsis > TGTApoapsis {
	set LaunchSPT0 to Time:Seconds.
	set LaunchSPV0 to Ship:AIRSPEED.
	set ThrottleValue to ascentThrottle().
	wait ClimbTick.

	set PitchByGT to ArcCos(PercentGT).
	set PitchByAcc to ClimbDefaultPitch + CLimbPitchPID:UPDATE(Time:Seconds, TGTClimbAcc - ClimbAcc()).

	set PitchAngle to min(PitchByGT, PitchByAcc).
}
Set ThrottleValue to 0.

until ship:altitude > body:atm:height {
	if ship:obt:apoapsis < TGTApoapsis Set ThrottleValue to ascentThrottle().
	else set ThrottleValue to 0.
	wait ClimbTick.
}

Unlock Steering.
Unlock Throttle.

Panels On.
Fuelcells On.
Radiators On.
uiBanner("SSTO", "Circularizing...").
RUN CIRC.
