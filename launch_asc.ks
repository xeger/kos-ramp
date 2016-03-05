/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

// Final apoapsis (m altitude)
parameter apo.

// Number of seconds to sleep during staging loop
global launch_tick is 1.

// Time of SRB separation
global launch_tSrbSep is 0.

// Time of last stage
global launch_tStage is time:seconds.

/////////////////////////////////////////////////////////////////////////////
// Steering function.
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  local atmo is body:atm:height.
  local gt0 is atmo * 0.1.
  local gt1 is atmo * 0.8.
  local gtd is gt1 - gt0.
  local inclin is max(0, 90 * cos(1 * 90 * (ship:altitude - gt0)/gtd)).
  local gtvector is heading(90, inclin):vector.
  local prodot is vdot(ship:facing:vector, prograde:vector).

  if ship:altitude < gt0 {
    return heading(0, 90).
  } else if ship:altitude < gt1 and prodot < 0.975 {
    return lookdirup(gtvector, ship:facing:upvector).
  } else {
    return lookdirup(prograde:vector, ship:facing:upvector).
  }
}

/////////////////////////////////////////////////////////////////////////////
// Throttle function.
/////////////////////////////////////////////////////////////////////////////

function ascentThrottle {
  local head is vdot(ship:facing:vector, ship:velocity:surface).
  local spd is ship:velocity:surface:mag.
  // TODO adjust cutoff for ship alt & atmo pressure
  local cutoff is 100.

  if spd > 3 and head < 0.95 {
    return 0.
  } else if launch_tSrbSep = 0 and spd > cutoff {
    return 1 - (1 * (spd - cutoff) / 100).
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

if ship:status <> "prelaunch" and stage:solidfuel = 0 {
  // No SRBs; trim for liquid-fueled ascent.
  set launch_tSrbSep to time:seconds.
} else {
  // Turn SAS on during SRB ascent, but turn it off when maneuvering starts.
  sas on.
  when ship:altitude > body:atm:height * 0.8 then {
    sas off.
  }
}

lock steering to ascentSteering().
lock throttle to ascentThrottle().
set ship:control:pilotmainthrottle to 1.

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

// Get rid of ascent stage if less that 20% fuel remains ... bit wasteful, but
// keeps our burn calculations from being erroneous due to staging mid-burn.
// TODO stop being wasteful; compute burn duration & compare to remaining dv (need fuel flow data, yech!)
if stage:resourceslex["LiquidFuel"]:amount / stage:resourceslex["LiquidFuel"]:capacity < 0.2 {
  stage.
}

rcs on.
lock steering to ship:prograde.
until vdot(ship:facing:vector, ship:prograde:vector) > 0.975 {
  wait 1.
}
rcs off.

until ship:altitude > body:atm:height {
  ascentWarping().
}

run circ.
