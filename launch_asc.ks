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

// Maximum observed dynamic pressure
global launch_maxQ is 0.

// Fraction of max-Q that pressure must fall to before we turn to prograde
global launch_fracQ is 0.8.

// Time at which SRB separation occurred
global launch_tSrbSep is 0.

/////////////////////////////////////////////////////////////////////////////
// Steering logic; hidden inside a function so we can re-lock to it later on.
//
// This style of ascent steering relies solely on dynamic pressure (Q) and is
// best for lifting large, ungainly craft through thick atmosphere (i.e. Kerbin
// ascent).
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  set launch_maxQ to max(ship:Q, launch_maxQ).
  local fracQ is 1.0 - ((1 + ship:Q) / (1 + launch_maxQ)).

  if launch_tSrbSep > 0 and (time:seconds - launch_tSrbSep) < 10 {
    return ship:facing:forevector.
  } else if ship:Q >= launch_maxQ {
    return heading(90, 90).
  } else if ship:Q > launch_maxQ * launch_fracQ {
    return heading(90, 90 - 90 * fracQ).
  } else {
    return ship:prograde.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Throttle logic.
/////////////////////////////////////////////////////////////////////////////

function ascentThrottle {
  // TODO guard against going too fast too low (heat?)
  if vdot(ship:facing:vector, ship:velocity:surface) < 0.6 {
    return 0.
  } else {
    return 1.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Staging logic.
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
  } else if (Nout = Neng) {
    wait until stage:ready.
    stage.
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

// don't bother with post-SRB-sep pause
if stage:solidfuel = 0 {
  set launch_tSrbSep to time:seconds.
}

lock steering to ascentSteering().
lock throttle to ascentThrottle().
set ship:control:pilotmainthrottle to 1.

/////////////////////////////////////////////////////////////////////////////
// Enter staging loop. Steering is handled by the LOCK STEERING above.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  ascentStaging().
  ascentWarping().
  wait launch_tick.
}

unlock throttle.
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

rcs on.
lock steering to ship:prograde.
until ship:altitude > body:atm:height {
  ascentWarping().
}
run circ.
