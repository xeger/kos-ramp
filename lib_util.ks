// Determine the time of ship1's closest approach to ship2.
function utilClosestApproach {
  parameter ship1.
  parameter ship2.

  local Tmin is time:seconds.
  local Tmax is Tmin + 2 * max(ship1:obt:period, ship2:obt:period).
  local Rbest is (ship1:position - ship2:position):mag.
  local Tbest is 0.

  until Tmax - Tmin < 5 {
    local dt2 is (Tmax - Tmin) / 2.
    local Rl is utilCloseApproach(ship1, ship2, Tmin, Tmin + dt2).
    local Rh is utilCloseApproach(ship1, ship2, Tmin + dt2, Tmax).
    if Rl < Rh {
      set Tmax to Tmin + dt2.
    } else {
      set Tmin to Tmin + dt2.
    }
  }

  return (Tmax+Tmin) / 2.
}

// Given that ship1 "passes" ship2 during time span, find the APPROXIMATE
// distance of closest approach, but not precise! Use this iteratively to find
// the true closest approach.
function utilCloseApproach {
  parameter ship1.
  parameter ship2.
  parameter Tmin.
  parameter Tmax.

  local Rbest is (ship1:position - ship2:position):mag.
  local Tbest is 0.
  local dt is (Tmax - Tmin) / 32.

  local T is Tmin.
  until T >= Tmax {
    local X is (positionat(ship1, T)) - (positionat(ship2, T)).
    if X:mag < Rbest {
      set Rbest to X:mag.
    }
    set T to T + dt.
  }

  return Rbest.
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
