/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo is 200000.
// Heading during launch (90 for equatorial prograde orbit)
parameter hdglaunch is 90.

// Roll/rotation during launch
local function defaultRotation {
	// do not rotate the rocket 180° if we are already facing the proper way
	if abs(ship:facing:roll-180-hdglaunch) < 30 return 0.
	return 180. // needed for shuttles, should not harm rockets
}
parameter launchRoll is defaultRotation().

runoncepath("lib_parts").
runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_staging").

uiBanner("ascend","Ascend to " + round(apo/1000) + "km; heading " + hdglaunch + "º").

// Number of seconds to sleep during ascent loop
global launch_tick is 1.

// Starting/ending height of gravity turn
// TODO adjust for atmospheric pressure; this works for Kerbin
global launch_gt0 is body:atm:height * 0.007. // About 500m in Kerbin
global launch_gt1 is body:atm:height * 0.6. // About 42000m in Kerbin

/////////////////////////////////////////////////////////////////////////////
// Steering function for continuous lock.
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  // How far through our gravity turn are we? (0..1)
  local gtPct is min(1,max(0, (ship:altitude - launch_gt0) / (launch_gt1 - launch_gt0))).
  // Ideal gravity-turn azimuth (inclination) and facing at present altitude.
  local pitch is arccos(gtPct).

  return heading(hdglaunch, pitch) * r(0,0,launchRoll).
}

/////////////////////////////////////////////////////////////////////////////
// Throttle function for continuous lock.
/////////////////////////////////////////////////////////////////////////////

function ascentThrottle {
  // angle of attack
  local aoa is vdot(ship:facing:vector, ship:velocity:surface).
  // how far through the soup are we?
  local atmPct is ship:altitude / (body:atm:height+1).
  local spd is ship:airspeed.

  // TODO adjust cutoff for atmospheric pressure; this works for kerbin
  local cutoff is 200 + (400 * max(0, (atmPct*3))).

  if spd > cutoff {
    // going too fast - avoid overheat or aerodynamic catastrophe
	// by limiting throttle but not less than 10% to keep some gimbaling
    return 1 - max(0.1, ((spd - cutoff) / cutoff)).
  } else {
    // Ease throttle when near the Apoapsis
    local ApoPercent is ship:obt:apoapsis/apo.
    local ApoCompensation is 0.
    if ApoPercent > 0.9 set ApoCompensation to (ApoPercent - 0.9) * 10.
    return 1.05 - min(1,max(0,ApoCompensation)).
  }
}

/////////////////////////////////////////////////////////////////////////////
// Deploy fairings at proper altitude; call in a loop.
/////////////////////////////////////////////////////////////////////////////

function ascentFairing {
  if ship:altitude > ship:body:atm:height {
    if partsDeployFairings() uiBanner("ascend","Discard fairings").
  }
}

/////////////////////////////////////////////////////////////////////////////
// Perform initial setup; trim ship for ascent.
/////////////////////////////////////////////////////////////////////////////

sas off.
bays off.
panels off.
radiators off.

lock steering to ascentSteering().
lock throttle to ascentThrottle().

/////////////////////////////////////////////////////////////////////////////
// Enter ascent loop.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  stagingCheck().
  ascentFairing().
  wait launch_tick.
}

uiBanner("Launch", "Engine cutoff").
unlock throttle.
set ship:control:pilotmainthrottle to 0.
uiBanner("Launch", "Engine cutoff").

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

// Roll with top up
uiBanner("ascend","Point prograde").
lock steering to heading (hdglaunch,0). //Horizon, ceiling up.
wait until utilIsShipFacing(heading(hdglaunch,0):vector).

// Warp to end of atmosphere
local AdjustmentThrottle is 0.
lock throttle to AdjustmentThrottle.
until ship:altitude > body:atm:height {
  if ship:obt:apoapsis < apo set AdjustmentThrottle to ascentThrottle().
  else set AdjustmentThrottle to 0.
  wait launch_tick.
}
// Discard fairings, if they aren't yet.
ascentFairing(). wait launch_tick.

// Give power and communication to the ship
fuelcells on.
panels on.
partsExtendAntennas().
wait launch_tick.

// Release controls. Turn on RCS to help steer to circularization burn.
unlock steering.
unlock throttle.
rcs on.
run circ.
