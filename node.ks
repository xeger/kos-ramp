// Execute a maneuver node.
local nd is nextnode.
local epsilon is 0.25.

local nstages is 0.

if (ship:maxthrust/ship:mass < epsilon) or (stage:liquidfuel < epsilon) {
  hudtext("ENGINE FAULT        MANUAL BURN", 10, 4, 36, RED, true).
} else {
  lock a to ship:maxthrust/ship:mass.
  sas off.

  print "Node: burn at T+" + round(nd:eta) + "; " + round(nd:deltav:mag/a) + " s @ " + round(a) + " m/s^2".

  // keep ship pointed at node
  lock steering to lookdirup(nd:deltav, ship:facing:topvector).

  // estimate direction & duration for waiting purposes
  set np to lookdirup(nd:deltav, ship:facing:topvector).
  set dob to (nd:deltav:mag / a).

  wait until vdot(facing:forevector, np:forevector) >= 0.999.
  print "Node: oriented to burn".

  run warp(nd:eta - dob/2).

  print "Node: burn start".
  local tset to 0.
  lock throttle to tset.

  local done to false.
  local dv0 to nd:deltav.

  until done
  {
      if (a = 0) or (stage:liquidfuel < epsilon) {
        local t0 is time.
        stage.
        set nstages to nstages + 1.
        wait until (a > epsilon) or ((time - t0):seconds > 3).

        if nstages > 1 {
          hudtext("ENGINE FAULT        MANUAL BURN", 10, 4, 36, RED, true).
          break.
        }
      } else {
        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/a, 1).
      }

      //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
      //this check is done via checking the dot product of those 2 vectors
      if vdot(dv0, nd:deltav) < 0
      {
          lock throttle to 0.
          set done to true.
      }

      else if nd:deltav:mag < 1
      {
          wait until vdot(dv0, nd:deltav) < 0.1.
          lock throttle to 0.
          set done to true.
      }
  }

  local dvf is nd:deltav:mag.

  if dvf < 0.5 {
    print "Node: burn complete; residual dV=" + round(dvf,1) + " m/s".
    remove nd.
  }

  // just in case
  unlock steering.
  unlock throttle.
  set ship:control:pilotmainthrottle to 0.
  sas on.
}
