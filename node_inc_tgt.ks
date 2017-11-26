// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.
//
// stolen from http://pastebin.com/fq3nqj2p
// as linked-to by http://www.reddit.com/r/kos/comments/2zehw6/help_calculating_time_to_andn/


if hasnode remove nextnode. wait 0.

local t0 is time:seconds.
local ship_orbit_normal is vcrs(ship:velocity:orbit,positionat(ship,t0)-ship:body:position).
local target_orbit_normal is vcrs(target:velocity:orbit,target:position-ship:body:position).
local lineofnodes is vcrs(ship_orbit_normal,target_orbit_normal).
local angle_to_node is vang(positionat(ship,t0)-ship:body:position,lineofnodes).
local angle_to_node2 is vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
local angle_to_opposite_node is vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
local relative_inclination is vang(ship_orbit_normal,target_orbit_normal).
local angle_to_node_delta is angle_to_node2-angle_to_node.

local ship_orbital_angular_vel is 360 / ship:obt:period.
local time_to_node is angle_to_node / ship_orbital_angular_vel.
local time_to_opposite_node is angle_to_opposite_node / ship_orbital_angular_vel.

// the nearest node might be in the past, in which case we want the opposite
// node. test this by looking at our angular velocity w/r/t the node. There's
// probably a more straightforward way to do this...
local t is 0.
if angle_to_node_delta < 0 {
	set t to (time + time_to_node):seconds.
} else {
	set t to (time + time_to_opposite_node):seconds.
}

local v is velocityat(ship, t):orbit.
local vt is velocityat(target, t):orbit.
local diff is vt - v.
local nDv is v:mag * sin(relative_inclination).
local pDV is v:mag * (cos(relative_inclination) - 1 ).
local dv is 2 * v:mag * sin(relative_inclination / 2).

// Now we have almost all the variables to burn. We just don't know which way to burn yet
// If the target ship (or body) is ahead of our ship less than 180 degrees at the node (that we dont know if is ascending or descending) and it's position vector dot product our normal orbit vector is positive, that means that we must burn normal to reach that plane. If the dot product is negative it means we need to burn anti-normal to reach that plane.
// Also if the target ship is ahead more than 180 degress (or behind) the situation is inverse. Setting the normal delta v to a negative value takes care of it. 

set tFuturePos to positionat(target,t).
set sFutureVel to velocityat(ship,t):obt.

if vdot(sFutureVel,tFuturePos) < 0 set nDv to -nDv. 
if vdot(ship_orbit_normal,tFuturePos) < 0 set nDv to -nDv. 

add node(t, 0, ndv, pDv).

