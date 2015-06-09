/////////////////////////////////////////////////////////////////////////////
// Change altitude
/////////////////////////////////////////////////////////////////////////////
// Perform an immediate burn to establish a new orbital altitude opposite
// the burn point.
/////////////////////////////////////////////////////////////////////////////

parameter alt.

local mu is constant():G * ship:obt:body:mass.
local rb is ship:obt:body:radius.

// present orbit properties
local vom is velocity:orbit:mag.  // actual velocity
local r is rb + altitude.
local va is sqrt( vom^2 ). // velocity in periapsis
local a is (periapsis + 2*rb + apoapsis)/2. // semi major axis present orbit

// future orbit properties
local r2 is rb + altitude.
local a2 is (alt + 2*rb + periapsis)/2. // semi major axis target orbit
local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).

// create node
local deltav is v2 - va.
local nd is node(time:seconds, 0, 0, deltav).
add nd.
