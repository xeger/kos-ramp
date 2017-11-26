/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo is 200000.
parameter hdglaunch is 90. 

runoncepath("lib_parts.ks"). 
runoncepath("lib_ui.ks").
runoncepath("lib_util").

uiBanner("Launch","Launching to an orbit of " + round(apo/1000) + "km and heading of " + hdglaunch + "º"). 

// Number of seconds to sleep during ascent loop
global launch_tick is 1.

// Time of SRB separation
global launch_tSrbSep is 0.

// Time of last stage
global launch_tStage is time:seconds.

// Starting/ending height of gravity turn
// TODO adjust for atmospheric pressure; this works for Kerbin
global launch_gt0 is body:atm:height * 0.007. // About 500m in Kerbin
global launch_gt1 is body:atm:height * 0.6. // About 42000m in Kerbin

// Can't figure out the original formula for Gravity Turn, changed to use ARCCOS. 
// The original algorithm didn't work with most of my rockets, so changed.
// TODO: Figure a better formula for Gravity Turn.
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
// Throttle function.
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
    return 1.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Auto-stage and auto-warp logic -- performs its work as side effects vs.
// returning a value; must be called in a loop to have any effect!
/////////////////////////////////////////////////////////////////////////////

function ascentStaging {
  local Neng is 0.
  local Nsrb is 0.
  local Nlfo is 0.
  local ThisStage is stage:Number.

  list engines in engs.
  for eng in engs {
    if eng:ignition {
      set Neng to Neng + 1.
      if not eng:allowshutdown and eng:flameout {
        set Nsrb to Nsrb + 1.
      }
      if eng:flameout {
        set Nlfo to Nlfo + 1.
      }
    }
  }

  if Nsrb > 0 {
    stage.
    set launch_tSrbSep to time:seconds.
    set launch_tStage to launch_tSrbSep.
    uiBanner("Launch","Stage " + ThisStage + " separated. " + Nsrb + " SRBs discarded.").
  } else if (Nlfo > 0) {
    wait until stage:ready.
    stage.
    set launch_tStage to time:seconds.
    uiBanner("Launch","Stage " + ThisStage + " separated. " + Nlfo + " Engines out.").
  } else if Neng = 0 {
    wait until stage:ready.
    stage.
    set launch_tStage to time:seconds.
    uiBanner("Launch","Stage " + ThisStage + " activated").
  }
  

}

function ascentWarping {
  if stage:solidfuel > 10 and ship:status = "flying" {
    if warp <> 0 {
      set warp to 0. // Don't allow warp while burning SRBs. Change to force warp.
    }
  } else if ship:altitude > body:atm:height {
    set warp to 1. 
  } else {
    if warp <> 0 {
      set warp to 1. 
    }
  }
}

function ascentFairing {
  if ship:altitude > ship:body:atm:height {
    partsDeployFairings().
    uiBanner("Launch","Discard fairings").
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
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Enter ascent loop.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  ascentStaging().
  ascentFairing().
  wait launch_tick.
}

unlock throttle.
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

// Roll with top up.
lock steering to heading (hdglaunch,0). //Horizon, ceiling up.
wait until utilIsShipFacing(heading(hdglaunch,0):vector).

// Get rid of ascent stage if less that 10% fuel remains ... bit wasteful, but
// keeps our burn calculations from being erroneous due to staging mid-burn.
// TODO stop being wasteful; compute burn duration & compare to remaining dv (need fuel flow data, yech!)
if stage:resourceslex:haskey("LiquidFuel") {
  if stage:resourceslex["LiquidFuel"]:capacity > 0 { // Checks to avoid NaN error
    if stage:resourceslex["LiquidFuel"]:amount / stage:resourceslex["LiquidFuel"]:capacity < 0.1 {
      stage.
      uiBanner("Launch","Discarding tank").
      wait until stage:ready.
    }
  }
  // Corner case: circularization stage is not bottom most (i.e. there is an
  // aeroshell ejection in a lower stage).
  until ship:availablethrust > 0 {
    stage.
    uiBanner("Launch","Discard non-propulsive stage").
    wait until stage:ready.
  }
}
// Warp to end of atmosphere
until ship:altitude > body:atm:height {
  ascentWarping().
}

// Give power and communication to the ship
fuelcells on.
panels on.
partsExtendAntennas().
// Release controls. Turn on RCS to help steer to circularization burn.
unlock steering.
unlock throttle.
rcs on.
run circ.
