// Change altitude on opposite side of the burn.
// Default parameters circularize at periapsis.
// NOTE: circularizing at apoapsis by default may sound better but it would crash for e >= 1.

// desired altitude
parameter alt is periapsis.
// time of burn
parameter t1 is time:seconds+eta:periapsis.

// pre-burn conditions
local p1 is positionAt(ship, t1)-body:position.
local r1 is p1:mag.
local v1 is velocityAt(ship, t1):orbit.

// prograde, normal and radial-out normalized
local pv is v1:normalized.
local nv is vcrs(v1,p1):normalized.
local rv is vcrs(nv,v1):normalized.

// post-burn conditions
local r2 is alt+body:radius.
local v2 is sqrt(body:mu*(2/r1-2/(r1+r2))) * vcrs(p1,nv):normalized.

// create node
local dv is v2 - v1.
add node(t1, vdot(dv,rv), vdot(dv,nv), vdot(dv,pv)).
// note that vdot(dv,rv) is zero if you burn at peri/apo-apsis
// and vdot(dv,nv) should always be zero (not changing inclination)

