/////////////////////////////////////////////////////////////////////////////
// Match velocities at closest approach.
/////////////////////////////////////////////////////////////////////////////
// Bring the ship to a stop when it meets up with the target.
/////////////////////////////////////////////////////////////////////////////

run lib_ui.
run lib_util.

// Figure out some basics
local T is utilClosestApproach(ship, target).
local Vship is velocityat(ship, T):orbit.
local Vtgt is velocityat(target, T):orbit.
local Pship is positionat(ship, T) - body:position.
local dv is Vtgt - Vship.

// project dv onto the radial/normal/prograde direction vectors to convert it
// from (X,Y,Z) into burn parameters. Estimate orbital directions by looking
// at position and velocity of ship at T.
local r is Pship:normalized.
local p is Vship:normalized.
local n is vcrs(r, p):normalized.
local sr is vdot(dv, r).
local sn is vdot(dv, n).
local sp is vdot(dv, p).

// figure out the ship's braking time
local accel is uiAssertAccel("Node").
local dt is dv:mag / accel.

// Time the burn so that we end thrusting just as we reach the point of closest
// approach. Assumes the burn program will perform half of its burn before
// T, half afterward
add node(T-(dt/2), sr, sn, sp).
