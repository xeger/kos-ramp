// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.
//
// stolen from http://pastebin.com/fq3nqj2p
// as linked-to by http://www.reddit.com/r/kos/comments/2zehw6/help_calculating_time_to_andn/

set target_inclination to target:obt:inclination.

set t0 to time:seconds.
set ship_orbit_normal to vcrs(ship:velocity:orbit,positionat(ship,time:seconds)-ship:body:position).
set target_orbit_normal to vcrs(target:velocity:orbit,target:position-ship:body:position).
set lineofnodes to vcrs(ship_orbit_normal,target_orbit_normal).
set angle_to_node to vang(positionat(ship,t0)-ship:body:position,lineofnodes).
set angle_to_node2 to vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
set angle_to_opposite_node to vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
set relative_inclination to vang(ship_orbit_normal,target_orbit_normal).
set angle_to_node_delta to angle_to_node2-angle_to_node.

set ship_orbital_angular_vel to (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant():pi).
set time_to_node to angle_to_node / ship_orbital_angular_vel.
set time_to_opposite_node to angle_to_opposite_node / ship_orbital_angular_vel.
set time_to_node_minutes to floor((time_to_node)/60).
set time_to_node_seconds to (((time_to_node)/60)-time_to_node_minutes)*60.
set time_to_opposite_node_minutes to floor((time_to_opposite_node)/60).
set time_to_opposite_node_seconds to (((time_to_opposite_node)/60)-time_to_opposite_node_minutes)*60.

local t is time:seconds.

if angle_to_node_delta < 0 {
	set t to (time + time_to_node):seconds.
} else {
	set t to (time + time_to_opposite_node):seconds.
}

local v is velocityat(ship, t):orbit.
local dv is 2 * v:mag * sin(relative_inclination / 2).

if v:y > 0 {
  // burn anti-normal at ascending node
  set nd to node(t, 0, -dv, 0).
} else {
  // burn normal at descending node
  set nd to node(t, 0, dv, 0).
}

add nd.
