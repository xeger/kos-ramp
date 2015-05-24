// Determine orbital velocity at a given altitude.
function obtvel {
  parameter obt.
  parameter alt.

  local mu is constant():G * obt:body:mass.
  local r is obt:body:radius + alt.

  return sqrt( mu * ( (2 / r) - (1 / obt:semimajoraxis) ) ).
}
