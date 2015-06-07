local Tmin is time:seconds.
local Tmax is Tmin + 2*ship:obt:period.

local T is 0.

// Binary search for closest approach
local N is 0.
until N > 64 {
  local dt is (Tmax - Tmin) / 4.
  set T to  Tmin + (2*dt).
  local Tl is Tmin - dt.
  local Th is Tmax + dt.

  local bp is body:position.
  local R is (positionat(ship, T) - bp) - (positionat(target, T) - bp).
  local Rl is (positionat(ship, Tl) - bp) - (positionat(target, Tl) - bp).
  local Rh is (positionat(ship, Th) - bp) - (positionat(target, Th) - bp).

  if Rh:mag < Rl:mag {
    print "upper".
    set Tmin to T.
  } else {
    print "lower".
    set Tmax to T.
  }

  set N to N + 1.
}

local Vship is velocityat(ship, T):orbit.
local Vtgt is velocityat(target, T):orbit.
local Pship is positionat(ship, T) - body:position.
local dv is Vtgt - Vship.
print "T=" + T.
print "dv=" + dv + " (" + dv:mag + ")".

local r is Pship:normalized.
local p is Vship:normalized.
local n is vcrs(r, p):normalized.
local sr is vdot(dv, r).
local sn is vdot(dv, n).
local sp is vdot(dv, p).
//local r is sr * obt:radial:normalized.
//local n is sn * obt:normal:normalized.
//local p is sp * obt:prograde:normalized.
add node(T, sr, sn, sp).

// alt approach -- steer in realtime. doesn't work too well!
//lock dv to velocityat(target, T):orbit - velocityat(ship, T):orbit.
//lock steering to lookdirup(-(target:velocity:orbit - ship:velocity:orbit), ship:up:upvector).
