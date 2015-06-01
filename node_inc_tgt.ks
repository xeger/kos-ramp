// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.
//
// stolen from http://pastebin.com/fq3nqj2p
// as linked-to by http://www.reddit.com/r/kos/comments/2zehw6/help_calculating_time_to_andn/

local t0 is time:seconds.
local ship_orbit_normal is vcrs(ship:velocity:orbit,positionat(ship,t0)-ship:body:position).
local target_orbit_normal is vcrs(target:velocity:orbit,target:position-ship:body:position).
local lineofnodes is vcrs(ship_orbit_normal,target_orbit_normal).
local angle_to_node is vang(positionat(ship,t0)-ship:body:position,lineofnodes).
local angle_to_node2 is vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
local angle_to_opposite_node is vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
local relative_inclination is vang(ship_orbit_normal,target_orbit_normal).
local angle_to_node_delta is angle_to_node2-angle_to_node.

local ship_orbital_angular_vel is (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant():pi).
local time_to_node is angle_to_node / ship_orbital_angular_vel.
local time_to_opposite_node is angle_to_opposite_node / ship_orbital_angular_vel.
local time_to_node_minutes is floor((time_to_node)/60).
local time_to_node_seconds is (((time_to_node)/60)-time_to_node_minutes)*60.
local time_to_opposite_node_minutes is floor((time_to_opposite_node)/60).
local time_to_opposite_node_seconds is (((time_to_opposite_node)/60)-time_to_opposite_node_minutes)*60.

local t is t0.

if angle_to_node_delta < 0 {
	set t to t0 + time_to_node.
} else {
	set t to t0 + time_to_opposite_node.
}

local v is velocityat(ship, t):orbit.
local dv is 2 * v:mag * sin(relative_inclination / 2).

if v:y > 0 {
  // burn anti-normal at ascending node
	add node(t, 0, -dv, 0).
} else {
  // burn normal at descending node
	add node(t, 0, dv, 0).
}
