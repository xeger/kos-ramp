/////////////////////////////////////////////////////////////////////////////
// Change apoapsis.
/////////////////////////////////////////////////////////////////////////////
// Establish new apoapsis by performing a burn at periapsis.
/////////////////////////////////////////////////////////////////////////////

parameter alt.

local mu is constant():G * ship:obt:body:mass.
local rb is ship:obt:body:radius.

// present orbit properties
local vom is velocity:orbit:mag.  // actual velocity
local r is rb + altitude.         // actual distance to body
local ra is rb + periapsis.        // radius in periapsis
local va is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity in periapsis
local a is (periapsis + 2*rb + apoapsis)/2. // semi major axis present orbit

// future orbit properties
local r2 is rb + periapsis.    // distance after burn at periapsis
local a2 is (alt + 2*rb + periapsis)/2. // semi major axis target orbit
local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).

// create node
local deltav is v2 - va.
local nd is node(time:seconds + eta:periapsis, 0, 0, deltav).
add nd.
