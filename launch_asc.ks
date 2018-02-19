/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo is 200000.
parameter hdglaunch is 90.

runoncepath("lib_parts").
runoncepath("lib_ui").
runoncepath("lib_util").
runoncepath("lib_staging").

uiBanner("ascend","Ascend to " + round(apo/1000) + "km; heading " + hdglaunch + "º").

// Number of seconds to sleep during ascent loop
global launch_tick is 1.

// Time of SRB separation
global launch_tSrbSep is 0.

// Time of last stage
global launch_tStage is time:seconds.

// Stage number at entry
global launch_nInitStage is stage:number.

// Starting/ending height of gravity turn
// TODO adjust for atmospheric pressure; this works for Kerbin
global launch_gt0 is body:atm:height * 0.007. // About 500m in Kerbin
global launch_gt1 is body:atm:height * 0.6. // About 42000m in Kerbin

/////////////////////////////////////////////////////////////////////////////
// Ascent staging (borrowed from lib).
/////////////////////////////////////////////////////////////////////////////

local ascentStaging is stagingCheck@.

/////////////////////////////////////////////////////////////////////////////
// Steering function for continuous lock.
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  // How far through our gravity turn are we? (0..1)
  local gtPct is (ship:altitude - launch_gt0) / (launch_gt1 - launch_gt0).

  // Ideal gravity-turn azimuth (inclination) and facing at present altitude.
  local inclin is min(90, max(0, arccos(min(1,max(0,gtPct))))).
  local gtFacing is heading ( hdglaunch, inclin) * r(0,0,180). //180 for shuttles, doesn't matter for rockets.

  if gtPct <= 0 {
    return heading (hdglaunch,90) + r(0,0,180). //Straight up.
  } else {
    return gtFacing.
  }
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

  if spd > cutoff and launch_tSrbSep = 0 {
    // going too fast during SRB ascent; avoid overheat or
    // aerodynamic catastrophe by limiting throttle
    return 1 - (1 * (spd - cutoff) / cutoff).
  } else {
    // Ease thottle when near the Apoapsis
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


if ship:status <> "PRELAUNCH" and stage:solidfuel = 0 {
  // note that there's no SRB
  set launch_tSrbSep to time:seconds.
}

lock steering to ascentSteering().
lock throttle to ascentThrottle().

/////////////////////////////////////////////////////////////////////////////
// Enter ascent loop.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  ascentStaging().
  ascentFairing().
  wait launch_tick.
}

uiBanner("ascend", "Engine cutoff").
unlock throttle.
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

// Get rid of ascent stage if less that 5% fuel remains ... bit wasteful, but
// keeps our burn calculations from being erroneous due to staging mid-burn.
if stage:resourceslex:haskey("LiquidFuel") {
  if stage:resourceslex["LiquidFuel"]:capacity > 0 { // Checks to avoid NaN error
    if stage:resourceslex["LiquidFuel"]:amount / stage:resourceslex["LiquidFuel"]:capacity < 0.05 {
      uiBanner("ascend","Discarding ascent stage").
      stage.
      stagingPrepare.
    }
  }
}
// Corner case: circularization stage is not bottom most (i.e. there is an
// aeroshell ejection in a lower stage).
until ship:availablethrust > 0 {
  stage.
  uiBanner("ascend","Discard non-propulsive stage").
  wait until stage:ready.
}

// Roll with top up.
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
