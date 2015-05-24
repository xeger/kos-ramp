// Reference-frame conversions.
// Derived from http://ksp-kos.github.io/KOS_DOC/math/ref_frame.html

// Convert a position from SHIP-RAW to SOI-RAW frame.
function soiraw {
  parameter ship.
  parameter pos.

  return pos - ship:body:position.
}

// Convert a position from SOI-RAW to SHIP-RAW frame.
function shipraw {
  parameter ship.
  parameter pos.

  return pos + ship:body:position.
}
