// Circularize as soon as possible.

if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis {
  run node_circ("periapsis").
else {
  run node_circ("apoapsis").
}

run node.

print "Circ: circularization complete; e = " + round(ship:obt:eccentricity, 3).
