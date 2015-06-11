/////////////////////////////////////////////////////////////////////////////
// Match velocities at closest approach.
/////////////////////////////////////////////////////////////////////////////
// Bring the ship to a stop when it meets up with the target.
/////////////////////////////////////////////////////////////////////////////

run lib_util.

// Figure out some basics
local T is utilClosestApproach(ship, target).
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
