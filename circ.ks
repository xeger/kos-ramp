// Circularize as soon as possible.

if eta:apoapsis < eta:periapsis {
  run node_circ("apoapsis").
} else {
  run node_circ("periapsis").
}

run node.

print "Node: circularization complete; e = " + round(ship:obt:eccentricity, 3).
