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

  local R is (positionat(ship, T)) - (positionat(target, T)).
  local Rl is (positionat(ship, Tl)) - (positionat(target, Tl)).
  local Rh is (positionat(ship, Th)) - (positionat(target, Th)).

  if Rh:mag < Rl:mag {
    set Tmin to T.
  } else {
    set Tmax to T.
  }

  set N to N + 1.
}

local Vship is velocityat(ship, T):orbit.
local Vtgt is velocityat(target, T):orbit.
local Pship is positionat(ship, T) - body:position.
local dv is Vtgt - Vship.

local r is Pship:normalized.
local p is Vship:normalized.
local n is vcrs(r, p):normalized.
local sr is vdot(dv, r).
local sn is vdot(dv, n).
local sp is vdot(dv, p).
add node(T, sr, sn, sp).

//alt approach: do it in realtime .. doesn't work as expected
//lock steering to lookdirup((target:velocity:orbit - ship:velocity:orbit) - ship:position, ship:up:upvector).
//wait until 0 = 1.
