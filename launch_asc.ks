/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo.

// Number of seconds to sleep during ascent loop
global launch_tick is 1.

// Time of SRB separation
global launch_tSrbSep is 0.

// Time of last stage
global launch_tStage is time:seconds.

// Starting/ending height of gravity turn
// TODO adjust for atmospheric pressure; this works for Kerbin
global launch_gt0 is body:atm:height * 0.1.
global launch_gt1 is body:atm:height * 0.8.

// "Sharpness" of gravity turn; we use a cosine function to modulate the
// turn, and the sharpness is a scaling factor for the input to the cosine
// function. Higher numbers are sharper, lower numbers are gentler.
// TODO get rid of this once we solve "tipping" issue
global launch_gtScale is 1.

/////////////////////////////////////////////////////////////////////////////
// Steering function that uses the launch_gt* to perform a gravity turn.
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  // How far through our gravity turn are we? (0..1)
  local gtPct is (ship:altitude - launch_gt0) / (launch_gt1 - launch_gt0).

  // Ideal gravity-turn azimuth (inclination) and facing at present altitude.
  local inclin is min(90, max(0, 90 * cos(launch_gtScale * 90 * gtPct))).
  local gtFacing is heading(90, inclin):vector.

  local prodot is vdot(ship:facing:vector, prograde:vector).

  if gtPct <= 0 {
    return heading(0, 90).
  } else {
    return lookdirup(gtFacing, ship:facing:upvector).
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
  local spd is ship:velocity:surface:mag.

  // TODO adjust cutoff for atmospheric pressure; this works for kerbin
  local cutoff is 200 + (400 * max(0, atmPct)).

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
  local Nout is 0.

  list engines in engs.
  for eng in engs {
    if eng:ignition {
      set Neng to Neng + 1.
      if not eng:allowshutdown {
        set Nsrb to Nsrb + 1.
      }
      if eng:flameout {
        set Nout to Nout + 1.
      }
    }
  }

  if (Nsrb > 0) and (stage:solidfuel < 10) {
    stage.
    set launch_tSrbSep to time:seconds.
    set launch_tStage to launch_tSrbSep.
  } else if (Nout = Neng) {
    wait until stage:ready.
    stage.
    set launch_tStage to time:seconds.
  }
}

function ascentWarping {
  if stage:solidfuel > 10 and ship:status = "flying" {
    set warp to 1.
  } else if ship:altitude > body:atm:height {
    set warp to 1.
  } else {
    set warp to 0.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Perform initial setup; trim ship for ascent.
/////////////////////////////////////////////////////////////////////////////

sas off.

if ship:status <> "prelaunch" and stage:solidfuel = 0 {
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
  ascentWarping().
  wait launch_tick.
}

unlock throttle.
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Coast to apoapsis and hand off to circularization program.
/////////////////////////////////////////////////////////////////////////////

sas on.

// Get rid of ascent stage if less that 20% fuel remains ... bit wasteful, but
// keeps our burn calculations from being erroneous due to staging mid-burn.
// TODO stop being wasteful; compute burn duration & compare to remaining dv (need fuel flow data, yech!)
if stage:resourceslex:haskey("LiquidFuel") and stage:resourceslex["LiquidFuel"]:amount / stage:resourceslex["LiquidFuel"]:capacity < 0.2 {
  stage.
  wait until stage:ready.
}
// Corner case: circularization stage is not bottom most (i.e. there is an
// aeroshell ejection in a lower stage).   
until ship:availablethrust > 0 {
  stage.
  wait until stage:ready.
}

rcs on.

until ship:altitude > body:atm:height {
  ascentWarping().
}
set warp to 0.

run circ.
