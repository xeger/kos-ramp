// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.

// Desired orbital inclination
parameter target_inclination.

if hasnode remove nextnode.

local position is ship:position-ship:body:position.
local velocity is ship:velocity:orbit.
local ang_vel is 4 * ship:obt:inclination / ship:obt:period.

local equatorial_position is V(position:x, 0, position:z).
local angle_to_equator is vang(position,equatorial_position).

if position:y > 0 {
	if velocity:y > 0 {
		// above & traveling away from equator; need to rise to inc, then fall back to 0
		set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
	}
} else {
	if velocity:y < 0 {
		// below & traveling away from the equator; need to fall to inc, then rise back to 0
		set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
	}
}

local frac is (angle_to_equator / (4 * ship:obt:inclination)).
local dt is frac * ship:obt:period.
local t is time + dt.

local relative_inclination is target_inclination - ship:obt:inclination.
local vel is velocityat(ship, T):orbit.
local nDv is vel:mag * sin(relative_inclination).
local pDV is vel:mag * (cos(relative_inclination) - 1 ).
local dv is 2 * vel:mag * sin(relative_inclination / 2).


if vel:y < 0 set ndv to -ndv.

add node(T:seconds, 0, ndv, pDV).
