/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

global land_descend is 3.0.  // max speed after braking (m/s)
global land_slip    is 0.01. // transverse speed @ touchdown (m/s)
global land_warp    is 3.    // warp factor during descent
global land_final   is 10.   // height for final descent (m)
sas off.

until status <> "ORBITING" {
  lock steering to lookdirup(retrograde:vector, ship:facing:upvector).
  until status <> "ORBITING" {
    uiBanner("Landing", "Deorbit burn").
  }
}

if status = "SUB_ORBITAL" or status = "FLYING" {
  uiBanner("Landing", "Initial descent").
  lock steering to lookdirup(-ship:velocity:surface, ship:facing:upvector).

  local braking is false.
  local final is false.

  until status <> "SUB_ORBITAL" and status <> "FLYING" {
    local accel is uiAssertAccel("Landing").
    local v is ship:velocity:surface.
    local dtBrake is abs(v:mag / accel).
    local geo is ship:geoposition.
    local ground is geo:position:normalized.
    local vr is vdot(v, ground) * ground.
    local vt is v - vr.

    if final {
      local g is body:mu / (body:position:mag ^ 2).
      local dtGround is (sqrt(4 * g * abs(geo:position:mag) + v:mag^2) - v:mag) / (2*g).
      print "dtBrake  " + round(dtBrake, 1) at(0,0).
      print "dtGround " + round(dtGround, 1) at(0,1).
      print "..." at(0, 2).

      if vt:mag > land_slip {
        set ship:control:translation to vt.
      } else {
        set ship:control:translation to 0.
      }

      if geo:position:mag < land_final {
        set legs to true.
      }

      if dtBrake >= dtGround-1 {
        lock throttle to min(v:mag / accel, 1.0).
      } else {
        lock throttle to 0.
      }
    } else if braking  {
      if v:mag > land_descend {
        lock throttle to min(v:mag / accel, 1.0).
      } else {
        uiBanner("Landing", "Final descent").
        lock steering to lookdirup(-ship:geoposition:position:normalized, ship:facing:upvector).
        rcs on.
        set final to true.
      }
    } else {
      // Predict when we'll need to brake
      local rF is positionat(ship, time:seconds + dtBrake).
      local geoF is body:geopositionof(rF).
      local altF is rf:y - geoF:position:y.

      if altF < land_final {
        uiBanner("Landing", "Braking burn").
        set braking to true.
      } else {

      }
    }
  }
}

if status = "LANDED" or status = "SPLASHED" {
  lock throttle to 0.
  rcs off.
  sas on.
  uiBanner("Landing", "Landing completed").
} else {
  uiError("Landing", "Cannot land from " + status).
}
