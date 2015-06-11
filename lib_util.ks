// Determine the time of ship1's closest approach to ship2
function utilClosestApproach {
  parameter ship1.
  parameter ship2.

  local Tmin is time:seconds.
  local Tmax is Tmin + 2*ship1:obt:period.
  local T is 0.

  // Binary search for time of closest approach
  local N is 0.
  until N > 64 {
    local dt is (Tmax - Tmin) / 4.
    set T to  Tmin + (2*dt).
    local Tl is Tmin - dt.
    local Th is Tmax + dt.

    local Rl is (positionat(ship1, Tl)) - (positionat(ship2, Tl)).
    local Rh is (positionat(ship1, Th)) - (positionat(ship2, Th)).

    if Rh:mag < Rl:mag {
      set Tmin to T.
    } else {
      set Tmax to T.
    }

    set N to N + 1.
  }

  return T.
}

function utilHasNextNode {
  local sentinel is node(time:seconds + 9999999999, 0, 0, 0).
  add sentinel.
  local nn is nextnode.
  remove sentinel.
  if nn = sentinel {
    return false.
  } else {
    return true.
  }
}
