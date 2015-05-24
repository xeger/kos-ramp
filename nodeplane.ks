// Perform a plane-change maneuver to new inclination.
// Derived from https://code.google.com/p/virtualagc/wiki/BasicsOrbitalMechanics

// Givens:
//   Orbit is circular.
//   New inclination is in the range [-90..90]
// Notes:
//   Limit change to 60 degrees (else launching a new vessel takes less dV!)

// Desired new inclination (degrees)
parameter inc.

// Convert a position from SHIP-RAW to SOI-RAW frame.
function soiraw {
  parameter ship.
  parameter pos.

  return pos - ship:body:position.
}

// Find orbital velocity at a given position relative to reference body's CENTER
// (vector from center, not altitude from surface).
function obtvelpos {
  parameter obt.
  parameter pos.

  local mu is constant():G * obt:body:mass.

  return sqrt( mu * ( (2 / pos:mag) - (1 / obt:semimajoraxis) ) ).
}

local deltaI is (inc - ship:obt:inclination).
local v is obtvelpos(ship:obt, soiraw(ship, ship:obt:position)).
local deltav is 2 * v * sin(deltaI / 2).

local nd is node(time:seconds, 0, deltav, 0).
add nd.
