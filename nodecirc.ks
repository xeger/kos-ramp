parameter alt.

local errMax is 3.
local obt is ship:obt.

local apsisR is 0.
local apsisT is 0.

if alt < obt:apoapsis {
  run nodeperi(obt:periapsis).
} else {
  run nodeapo(obt:apoapsis).
}
