// Perform a plane-change maneuver to new inclination.
// Derived from https://code.google.com/p/virtualagc/wiki/BasicsOrbitalMechanics

// Givens:
//   Orbit is circular.
//   New inclination is in the range [-90..90]
// Notes:
//   Beware that changing inclination will decircularize your orbit!

// Desired new inclination (degrees)
parameter inc.
// Location of plane change ("an", "dn", "apoapsis", 0)
parameter where.

// Convert a position from SHIP-RAW to SOI-RAW frame.
function soiraw {
  parameter ship.
  parameter pos.

  return pos - obt:body:position.
}

// Find time of equatorial ascending/descending node of ship's orbit.
function obtequnode {
  local t0 is time.
  local p0 is soiraw(ship, obt:position).
  local v0 is obt:velocity:surface.

  local dt is obt:period / 2.
  local t is t0 + dt.

  local p0 is soiraw(ship, obt:position).
  local v0 is obt:velocity:surface.
  local p1 is soiraw(ship, positionat(ship, t)).
  local v1 is soiraw(ship, velocityat(ship, t):orbit).
  local n is 0.

  until abs(p1:y - p0:y) < 10 {
    set n to n + 1.

    if ((p0:y > 0) and (p1:y < 0) and (dt * v0:y < 0)) or
       ((p0:y < 0) and (p1:y > 0) and (dt * v0:y > 0)) {
      set dt to -dt / 2.
    } else {
      set dt to dt / 2.
    }
    set t to t + dt.

    set p1 to soiraw(ship, positionat(ship, t)).
    set v1 to soiraw(ship, velocityat(ship, t):orbit).

    if n >= 32 {
      print "obtequnode: Can't find solution after 32 iterations!".
      return 1 / 0.
    }
  }

  return t.
}

local T is 0.

// Find time of plane-change: next node, at apoapsis, or right now

if where = "an" {
  set T to obtequnode():seconds.
} else if where = "dn" {
  set T to obtequnode():seconds.
} else if where = "apoapsis" {
  set T to (time + (eta:apoapsis)):seconds.
} else {
  set T to time:seconds.
}

local nd is 0.

// Find delta v for plane-change from circular orbit
local theta is (inc - obt:inclination).
local v is velocityat(ship, T):orbit.
local dv is 2 * v:mag * sin(theta / 2).

if v:y > 0 {
  // burn normal at ascending node
  set nd to node(T, 0, -dv, 0).
} else {
  // burn anti-normal at descending node
  set nd to node(T, 0, dv, 0).
}

add nd.
