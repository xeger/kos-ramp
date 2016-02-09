/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Achieve circular orbit with desired apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Final apoapsis (m altitude)
parameter apo.

// Number of seconds to sleep during staging loop
global launch_tick is 1.

// Maximum observed dynamic pressue
global launch_maxQ is 0.

// Fraction of max-Q that pressure must fall to before we turn to prograde
global launch_fracQ is 0.1.

/////////////////////////////////////////////////////////////////////////////
// Steering logic; hidden inside a function so we can re-lock to it later on.
//
// This style of ascent steering relies solely on dynamic pressure (Q) and is
// best for lifting large, ungainly craft through thick atmosphere (i.e. Kerbin
// ascent).
/////////////////////////////////////////////////////////////////////////////

function ascentSteering {
  set launch_maxQ to max(ship:Q, launch_maxQ).
  if ship:Q >= launch_maxQ {
    return heading(0, 90).
  } else if (ship:Q > launch_maxQ * launch_fracQ) {
    // TODO be smarter about choosing a direction, e.g. blend
    // "up" with prograde so we gently cant over
    return heading(90, 85).
  } else {
    return ship:prograde.
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
  } else if (Nout = Neng) {
    wait until stage:ready.
    stage.
  }
}

lock steering to ascentSteering().
lock throttle to 1.
set ship:control:pilotmainthrottle to 1.

/////////////////////////////////////////////////////////////////////////////
// Enter staging loop. Steering is handled by the LOCK STEERING above.
/////////////////////////////////////////////////////////////////////////////

until ship:obt:apoapsis >= apo {
  ascentStaging().
  wait launch_tick.
}

unlock throttle.
set ship:control:pilotmainthrottle to 0.

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

lock steering to ship:prograde.
wait until ship:altitude > body:atm:height.
run circ.
