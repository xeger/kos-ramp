// Ascend from a planet, performing a gravity turn to help with atmosphere.
// Circularize at apoapsis with e <= 0.01

// Beginning of gravity turn (m altitude)
parameter gt0.

// End of gravity turn (m altitude)
parameter gt1.

// Final apoapsis (m altitude)
parameter apo.

// A very small amount (of propellant) left in tanks when we auto stage
local epsilon is 0.1.

// Gravity turn parameters
local gtd is gt1 - gt0.  // overall depth
local k is 180.          // sharpness, 180 = pure cosine

// Gravity turn: determine ship heading elevation for a given altitude.
function gte {
  parameter altitude.

  return max(0, 90 * cos(k * (altitude - gt0)/gtd)).
}

/////////////////////////////////////////////////////////////////////////////
// Setup auto-stage behavior
/////////////////////////////////////////////////////////////////////////////

if stage:solidfuel > 0 {
  print "Launch: main throttle half".
  set ship:control:pilotmainthrottle to 0.5.
  when stage:solidfuel < epsilon then {
    print "Launch: booster separation; main throttle full".
    set ship:control:pilotmainthrottle to 1.
    stage.
  }
} else {
  print "Launch: main throttle full".
  set ship:control:pilotmainthrottle to 1.
}

when stage:liquidfuel < epsilon or stage:oxidizer < epsilon then {
  print "Launch: initial stage separation".
  stage.

  when stage:liquidfuel < epsilon or stage:oxidizer < epsilon then {
    print "Launch: stage " + stage:number + " separation".
    stage.
    preserve.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Perform gravity turn
/////////////////////////////////////////////////////////////////////////////

print "Launch: initial climb to " + gt0 + " m".

sas on.
lock steering to heading(90,90).

when ship:altitude >= gt0 then {
  print "Launch: gravity turn entry".
  lock steering to heading(90, gte(ship:altitude)).

  when (ship:altitude >= gt1) or (ship:obt:apoapsis >= apo) then {
    print "Launch: gravity turn complete".
  }
}

wait until ship:obt:apoapsis >= apo.

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

print "Launch: main throttle off; coast to apoapsis".
set ship:control:pilotmainthrottle to 0.
lock steering to ship:prograde.

run circ.
