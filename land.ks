/////////////////////////////////////////////////////////////////////////////
// Land
/////////////////////////////////////////////////////////////////////////////
// Make groundfall
/////////////////////////////////////////////////////////////////////////////

run lib_ui.

global land_descend is 3.0.  // max descent rate
global land_slip    is 0.01. // transverse speed @ touchdown (m/s)
global land_fall    is 0.1.  // vertical speed @ touchdown (m/s)
global land_final   is 10.   // touchdown distance (m)

sas off.

until status <> "ORBITING" {
  lock steering to lookdirup(retrograde:vector, ship:facing:upvector).
  until status <> "ORBITING" {
    uiBanner("Landing", "Deorbit burn").
  }
}

if status = "SUB_ORBITAL" or status = "FLYING" {
  local braking is false.
  local final is false.

  until status <> "SUB_ORBITAL" and status <> "FLYING" {
    local accel is uiAssertAccel("Landing").
    local geo is ship:geoposition.
    local ground is -geo:position:normalized.
    local v is ship:velocity:surface.
    local vy is vdot(v, ground).           // vertical speed (down < 0)
    local height is geo:position:mag.
    local dtBrake is abs(v:mag / accel).
    local dyBrake is abs((vy * (dtBrake+2)) - (0.5 * accel * dtBrake^2)).

    print "acc  " + round(accel) + "    " at(0,0).
    print "dyB  " + round(dyBrake) + "    " at(0,1).
    print " tB  " + round(dtBrake, 1) + "    " at (0,2).
    print "alt  " + round(height) + "    " at(0,3).
    print "..." at(0,4).

    if final {
      set legs to true.
      local vr is ground * vdot(v, ground).  // radial velocity
      local vt is v - vr.                    // transverse velocity
      if vt:mag > land_slip and vy < land_fall {
        lock steering to lookdirup(-v, ship:facing:upvector).
        lock throttle to min(v:mag/accel, 1.0).
      } else if vy < land_fall {
        lock steering to lookdirup(ground, ship:facing:upvector).
        lock throttle to min(v:mag/accel, 1.0).
      } else {
        lock steering to lookdirup(ground, ship:facing:upvector).
        lock throttle to 0.
      }
    } else if braking {
      if vy < -land_descend {
        lock steering to lookdirup(-v, ship:facing:upvector).
        lock throttle to min((v:mag-land_descend)/accel, 1.0).
      } else {
        lock steering to lookdirup(ground, ship:facing:upvector).
        lock throttle to 0.
      }
    } else if height < land_final {
      uiBanner("Landing", "Final descent").
      set final to true.
    } else if height < dyBrake {
      uiBanner("Landing", "Retro burn").
      set braking to true.
    } else {
      lock steering to lookdirup(-v, ship:facing:upvector).
      lock throttle to 0.
    }
  }
}

if status = "LANDED" or status = "SPLASHED" {
  lock throttle to 0.
  sas on.
  uiBanner("Landing", "Landing completed").
} else {
  uiError("Landing", "Cannot land from " + status).
}
