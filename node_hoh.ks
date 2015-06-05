// Delta vee math stolen from http://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
// Phase angle math stolen from https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit

parameter approach.

function synodicPeriod {
  parameter o1, o2.

  if o1:period > o2:period {
    local o is o2.
    set o2 to o1.
    set o1 to o.
  }

  return 1 / ( (1 / o1:period) - (1 / o2:period) ).
}

if body <> target:body {
  print "hohmann: transfer impossible; target orbits (" + target:body:name + ") and ship orbits (" + body:name + ")".
  local die is 1 / 0.
}
if ship:obt:eccentricity > 0.1 {
  print "hohmann: transfer impossible; ship eccentricity (" + round(ship:obt:eccentricity, 3) + ") too great".
  local die is 1 / 0.
}
if target:obt:eccentricity > 0.1 {
  print "hohmann: transfer impossible; target eccentricity (" + round(target:obt:eccentricity, 3) + ") too great".
  local die is 1 / 0.
}
local ri is abs(obt:inclination - target:obt:inclination).
if ri > 0.1 {
  print "hohmann: transfer impossible; relative inclination to target (" + round(ri, 1) + ") too great".
  local die is 1 / 0.
}

local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.

local dv1 is sqrt(body:mu / r1) * (sqrt( (2*(r2-approach)) / (r1+r2-approach) ) - 1).

local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
local ft is pt - floor(pt).

local theta is 360 * ft.
local phi is 180 - theta.
local omega is (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant():pi).

local T is time:seconds.
local Tmax is T + 1.5 * synodicPeriod(ship:obt, target:obt).
local done is false.

local phiT is 0.

until done = true or T > Tmax {
  local p1 is positionat(ship, T) - body:position.
  local p2 is positionat(target, T) - body:position.
  local v1 is velocityat(ship, T):orbit.
  local v2 is velocityat(target, T):orbit.

  // unsigned magnitude of the orbital phiT between ship and target
  set phiT to vang(p1, p2).
  // if r2 > r1, then norm:y is negative when ship is "behind" the target
  local norm is vcrs(p1, p2).
  // < 0 if ship is on opposite side of planet
  local dot is vdot(v1, v2).

  local eta is ((phiT - phi) / omega).

  if r2 > r1 and norm:y > 0 {
    // ship is ahead of target; skip ahead
    set T to T + ship:obt:period / 8.
  } else if r2 < r1 and norm:y < 0 {
    // ship is ahead of target; skip ahead
    set T to T + ship:obt:period / 8.
  } else if dot > 0 {
    // ship is ahead of target; skip ahead
    set T to T + ship:obt:period / 8.
  } else if eta < 0 {
    // ship has already passed the window; skip ahead
    set T to T + ship:obt:period / 2.
  } else {
    set T to T + eta.
    print "found window at " + T.
    print "phiT   " + phiT + " (phi " + phi + ")".
    print "eta     " + eta.
    print "dot     " + dot.
    print "norm:y  " + norm:y.
    set done to true.
  }
}

if done {
  add node(T, 0, 0, dv1).
} else {
  print "Node: failed to find Hohmann transfer window".
  local die is 1 / 0.
}
