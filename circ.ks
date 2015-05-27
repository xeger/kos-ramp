// Circularize as soon as possible.

if eta:apoapsis < eta:periapsis {
  run nodecirc("apoapsis").
} else {
  run nodecirc("periapsis").
}

run node.

print "Node: circularization complete; e = " + round(ship:obt:eccentricity, 3).
