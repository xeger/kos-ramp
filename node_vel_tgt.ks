/////////////////////////////////////////////////////////////////////////////
// Match velocities at closest approach.
/////////////////////////////////////////////////////////////////////////////
// Bring the ship to a stop when it meets up with the target.
/////////////////////////////////////////////////////////////////////////////

local Tmin is time:seconds.
local Tmax is Tmin + 2*ship:obt:period.

local T is 0.

// Binary search for time of closest approach
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

// Figure out some basics
local Vship is velocityat(ship, T):orbit.
local Vtgt is velocityat(target, T):orbit.
local Pship is positionat(ship, T) - body:position.
local dv is Vtgt - Vship.

// project the ship's velocity vector onto the radial/normal/prograde
// direction vectors to convert it from an (X,Y,Z) delta vee into
// burn parameters
local r is Pship:normalized.
local p is Vship:normalized.
local n is vcrs(r, p):normalized.
local sr is vdot(dv, r).
local sn is vdot(dv, n).
local sp is vdot(dv, p).

// figure out the ship's braking distance so we can
// begin our burn before we get there
local accel is ship:availablethrust / ship:mass. // kN over tonnes; 1000s cancel
local dt is dv:mag / accel.

// Time the burn so that we end thrusting just as we reach the point of closest
// approach. Assumes the burn program will perform half of its burn before
// T, half afterward
add node(T-(dt/2), sr, sn, sp).
