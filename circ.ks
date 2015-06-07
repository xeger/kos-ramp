// Circularize as soon as possible.

run ui.

if obt:transition = "ESCAPE" or eta:periapsis < eta:apoapsis {
  run node_circ("periapsis").
} else {
  run node_circ("apoapsis").
}

run node.

uiStatus("Circ", "Circularized e=" + round(ship:obt:eccentricity, 3).
