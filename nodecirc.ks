// Plan a circularization burn by raising apoapsis or lowering periapsis.
parameter alt.

local errMax is 3.
local obt is ship:obt.

local apsisR is 0.
local apsisT is 0.

if alt >= obt:periapsis and alt < obt:apoapsis {
  // User wants a "lower" circularization (to periapsis)
  run nodeperi(obt:periapsis).
} else {
  // User wants a higher circularization (to apoapsis)
  run nodeapo(obt:apoapsis).
}
