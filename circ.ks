parameter alt.

// allow program to be called with no params
// assume circularize "up" to apoapsis.
if alt = 0 {
  set alt to ship:obt:apoapsis.
}

run nodecirc(alt).
run node.

print "Node: circularization complete; e = " + round(ship:obt:eccentricity, 3).
