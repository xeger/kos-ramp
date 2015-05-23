global epsilon is 0.001.

parameter gt0.
parameter gt1.
parameter apo.


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
  print "Ascent: main throttle half".
  set ship:control:pilotmainthrottle to 0.5.
  when stage:solidfuel < epsilon then {
    print "Ascent: booster separation; main throttle full".
    set ship:control:pilotmainthrottle to 1.
    stage.
  }
} else {
  print "Ascent: main throttle full".
  set ship:control:pilotmainthrottle to 1.
}

when stage:liquidfuel < epsilon and stage:solidfuel < epsilon then {
  print "Ascent: launch stage separation".
  stage.

  when stage:liquidfuel < epsilon then {
    print "Ascent: stage " + stage:number + " separation".
    stage.
    preserve.
  }
}

/////////////////////////////////////////////////////////////////////////////
// Perform gravity turn
/////////////////////////////////////////////////////////////////////////////

print "Ascent: initial climb to " + gt0 + " m".

sas on.
lock steering to heading(90,90).

when ship:altitude >= gt0 then {
  print "Ascent: gravity turn entry".
  lock steering to heading(90, gte(ship:altitude)).

  when (ship:altitude >= gt1) or (ship:obt:apoapsis >= apo) then {
    print "Ascent: gravity turn complete".
  }
}

wait until ship:obt:apoapsis >= apo.

/////////////////////////////////////////////////////////////////////////////
// Circularize at apoapsis
/////////////////////////////////////////////////////////////////////////////

print "Ascent: coast to apoapsis; main throttle off".
set ship:control:pilotmainthrottle to 0.
lock steering to ship:prograde.

run circ("apoapsis").

run node.
