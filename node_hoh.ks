// Delta vee math stolen from http://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
// Phase angle math stolen from https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit

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
// TODO check relative inclination

local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.

print "r1 " + r1.
print "r2 " + r2.

local dv1 is sqrt(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1).
local dv2 is sqrt(body:mu / r2) * (1 - sqrt( (2*r1) / (r1+r2) )).

local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
local ft is pt - floor(pt).

local theta is 360 * ft.
local phi is 180 - theta.
local omega is (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant():pi).

local T is time:seconds.
local Tmax is T + (5 * ship:obt:period).
local done is false.

local angle is 0.
local eta is 0.

until done = true or T > Tmax {
  local p1 is positionat(ship, T) - body:position.
  local p2 is positionat(target, T) - body:position.
  local v1 is velocityat(ship, T):orbit.
  local v2 is velocityat(target, T):orbit.

  // unsigned magnitude of the orbital angle between ship and target
  set angle to vang(p1, p2).
  // if r2 > r1, then norm:y is negative when ship is "behind" the target
  local norm is vcrs(p1, p2).
  // < 0 if ship is on opposite side of planet
  local dot is vdot(v1, v2).

  set eta to ((angle - phi) / omega).

  if r2 > r1 and norm:y > 0 {
    // ship is ahead of target; skip ahead
    set T to T + ship:obt:period / 4.
  } else if dot > 0 {
    // ship is ahead of target; skip ahead
    set T to T + ship:obt:period / 4.
  } else if eta < 0 {
    // ship has already passed the window; skip ahead
    set T to T + ship:obt:period / 2.
  } else {
    print "eta     " + (T - time:seconds).
    print "dot     " + dot.
    print "angle   " + angle + " (phi " + phi + ")".
    print "norm:y  " + norm:y.
    set done to true.
  }
}

if done {
  print "DONE! node eta is " + eta.
  add node(T + eta, 0, 0, dv1).
} else {
  print "Node: failed to find Hohmann transfer window".
  local die is 1 / 0.
}
