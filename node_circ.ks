// Circularize by raising apoapsis or lowering periapsis.

// Location of circularization burn: "apoapsis" or "periapsis".
parameter where.

local obt is ship:obt.

if where = "periapsis" or obt:transition = "ESCAPE" {
  run node_apo(obt:periapsis).
} else if where = "apoapsis" {
  run node_peri(obt:apoapsis).
} else {
  print "node_circ: unrecognized location " + where.
  print 1 / 0.
}
