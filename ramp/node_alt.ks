/////////////////////////////////////////////////////////////////////////////
// Change altitude
/////////////////////////////////////////////////////////////////////////////
// Perform an immediate burn to establish a new orbital altitude opposite
// the burn point.
/////////////////////////////////////////////////////////////////////////////

parameter alt.
parameter nodetime is time:seconds + 120.

local mu is body:mu.
local br is body:radius.

// present orbit properties
local vom is ship:velocity:orbit:mag. // current velocity
local r is br + altitude. // current radius
local v1 is velocityat(ship, nodetime):orbit:mag. // velocity at burn time
local sma1 is orbit:semimajoraxis.

// future orbit properties
local r2 is br + ship:body:altitudeof(positionat(ship, nodetime)).
local sma2 is (alt + br + r2) / 2.
local v2 is sqrt( vom ^ 2 + (mu * (2 / r2 - 2 / r + 1 / sma1 - 1 / sma2 ) ) ).

// create node
local deltav is v2 - v1.
local nd is node(nodetime, 0, 0, deltav).
add nd.
