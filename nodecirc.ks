// Circularize by raising apoapsis or lowering periapsis.

// Location of circularization burn: "apoapsis" or "periapsis".
parameter where.

local obt is ship:obt.

if where = "periapsis" {
  run nodeperi(obt:periapsis).
} else if where = "apoapsis" {
  run nodeapo(obt:apoapsis).
} else {
  print "nodecirc: unrecognized location " + where.
  return 1 / 0.
}
