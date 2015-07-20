/////////////////////////////////////////////////////////////////////////////
// Run node
/////////////////////////////////////////////////////////////////////////////
// Execute a maneuver node, warping if necessary to save time.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

local nd is nextnode.
local epsilon is 0.25.

local nstages is 0.

lock accel to ship:availablethrust / ship:mass.

// keep ship pointed at node
sas off.
lock steering to lookdirup(nd:deltav, ship:facing:topvector).

// estimate direction & duration
local np is lookdirup(nd:deltav, ship:facing:topvector).
local dob is (nd:deltav:mag / accel).

wait until vdot(facing:forevector, np:forevector) >= 0.95.

run warp(nd:eta - dob/2 - 1).

local tset to 0.
lock throttle to tset.

local done is false.
local dv0 to nd:deltav.

until done
{
    if accel > 0 {
      if vdot(ship:facing:vector, steering:vector) >= 0.99 or nd:deltav:mag < 1 {
        // we're aligned (more or less)
        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/accel, 1.0).
      } else {
        //cut throttle if we're not aligned with the burn vector
        set tset to 0.
      }

      //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
      //this check is done via checking the dot product of those 2 vectors
      if vdot(dv0, nd:deltav) < 0
      {
          lock throttle to 0.
          set done to true.
      } else if nd:deltav:mag < 1
      {
          wait until vdot(dv0, nd:deltav) < 0.1.
          lock throttle to 0.
          set done to true.
      }
    } else {
      // out of fuel; time to auto stage!
      wait until stage:ready.
      uiWarning("Node", "Stage " + stage:number + " separation during burn").
      stage.
      local t0 is time.
      wait until accel > 0 or (time - t0):seconds > 3.
    }
}

unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

if nd:deltav:mag < 0.5 {
  remove nd.
} else {
  uiWarning("Node", "VARIANCE " + round(nd:deltav:mag, 1) + " m/s").
}

sas on.
