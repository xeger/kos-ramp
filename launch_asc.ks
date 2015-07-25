/////////////////////////////////////////////////////////////////////////////
// Ascent phase of launch.
/////////////////////////////////////////////////////////////////////////////
// Ascend from a planet, performing a gravity turn and staging as necessary.
// Circularize at apoapsis.
/////////////////////////////////////////////////////////////////////////////

// Beginning of gravity turn (m altitude)
parameter gt0.

// End of gravity turn (m altitude)
parameter gt1.

// How steep to turn
parameter sharpness.

// Final apoapsis (m altitude)
parameter apo.

run lib_ui.

global launch_tick is 0.25.          // autostage loop idle time
global launch_interstage is 1.0.     // delay between stages

// A very small amount (of propellant) left in tanks when we auto stage
local epsilon is 1.

// Gravity turn parameters
local gtd is gt1 - gt0.  // overall depth
local k is 90 * sharpness. // sharpness, 90 = pure cosine

// Gravity turn: determine ship elevation for a given altitude.
// Uses a cosine function to turn smoothly.
function launchAscDir {
  parameter altitude.

  local elev is max(0, k * cos(k * (altitude - gt0)/gtd)).
  return heading(90, elev).
}

/////////////////////////////////////////////////////////////////////////////
// Setup booster-separation behavior. Boosters are special because we stage
// the moment they run out, regardless of the status of any other engines.
// This assumes that the vessel's initial stage separation will drop SRBs
// and not other useful engines!
/////////////////////////////////////////////////////////////////////////////

if stage:solidfuel > 0 {
  set ship:control:pilotmainthrottle to 0.5.
  when stage:solidfuel < epsilon then {
    uiBanner("Launch", "Booster separation").
    set ship:control:pilotmainthrottle to 1.
    stage.
  }
} else {
  set ship:control:pilotmainthrottle to 1.
}

/////////////////////////////////////////////////////////////////////////////
// Setup gravity-turn behavior
/////////////////////////////////////////////////////////////////////////////

sas off.
lock steering to heading(90, 90).

when ship:altitude >= gt0 then {
  uiBanner("Launch", "Gravity turn entry").
  lock steering to launchAscDir(ship:altitude).
}

// Shut off throttle exactly at apoapsis
when ship:obt:apoapsis >= apo then {
  set ship:control:pilotmainthrottle to 0.
  uiBanner("Launch", "Coast to apoapsis").
}

/////////////////////////////////////////////////////////////////////////////
// Enter auto-stage loop; separate stage as soon as all engines are flameout
/////////////////////////////////////////////////////////////////////////////

until ship:control:pilotmainthrottle = 0 {
  local Neng is 0.
  local Nout is 0.

  list engines in engs.
  for eng in engs {
    if eng:ignition {
      set Neng to Neng + 1.
      if eng:flameout {
        set Nout to Nout + 1.
      }
    }
  }

  if Neng = Nout {
    wait until stage:ready.
    uiBanner("Launch", "Stage " + stage:number + " separation").
    stage.
    wait launch_interstage.
  } else {
    wait launch_tick.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

lock steering to ship:prograde.
wait until ship:altitude > body:atm:height.

run circ.
