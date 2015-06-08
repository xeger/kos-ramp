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

// Final apoapsis (m altitude)
parameter apo.

run lib_ui.

// A very small amount (of propellant) left in tanks when we auto stage
local epsilon is 1.

// Gravity turn parameters
local gtd is gt1 - gt0.  // overall depth
local k is 180.          // sharpness, 180 = pure cosine

// Gravity turn: determine ship heading elevation for a given altitude.
function gte {
  parameter altitude.

  return max(0, 90 * cos(k * (altitude - gt0)/gtd)).
}

function flameout {
    return (stage:liquidfuel < epsilon) or (stage:oxidizer < epsilon).
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
    uiStatus("Launch", "Booster separation").
    set ship:control:pilotmainthrottle to 1.
    stage.
  }
} else {
  set ship:control:pilotmainthrottle to 1.
}

/////////////////////////////////////////////////////////////////////////////
// Setup gravity-turn behavior
/////////////////////////////////////////////////////////////////////////////

sas on.
lock steering to heading(90,90).

when ship:altitude >= gt0 then {
  uiStatus("Launch", "Gravity turn entry").
  lock steering to heading(90, gte(ship:altitude)).
}

// Shut off throttle exactly at apoapsis
when ship:obt:apoapsis >= apo then {
  set ship:control:pilotmainthrottle to 0.
  uiStatus("Launch", "Main throttle off; coast to apoapsis").
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
    uiStatus("Launch", "Stage " + stage:number + " separation").
    stage.
  } else {
    wait 1.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

lock steering to ship:prograde.
wait until ship:altitude > body:atm:height.

run circ.
