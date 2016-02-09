/////////////////////////////////////////////////////////////////////////////
// Warp time
/////////////////////////////////////////////////////////////////////////////
// Block until dt seconds have elapsed; use physics or rails warp as needed
// to accelerate simulated game time.
/////////////////////////////////////////////////////////////////////////////

declare parameter dt.

// Number of seconds to sleep during physics-warp loop
global warp_tick is 5.

global warp_physics is true.
global warp_t0 is time:seconds.
global warp_t1 is warp_t0 + dt - 1.

lock warp_dt to warp_t1 - time:seconds.
lock warp_atmo to ship:altitude / max(ship:altitude, body:atm:height).

until time:seconds >= warp_t1 {
  if ship:altitude < body:atm:height and ship:status <> "PRELAUNCH" and ship:status <> "LANDED" {
    set warpmode to "physics".
    set warp_physics to true.

    if warp_atmo > 0.8 {
      set warp to 3.
    } else if warp_atmo > 0.6 {
      set warp to 2.
    } else if warp_atmo > 0.2 {
      set warp to 1.
    } else {
      set warp to 0.
    }

    wait warp_tick.
  } else if warp_physics = true {
    // advance warp in case it was interrupted
    set warpmode to "rails".
    warpto(warp_t1).
    wait warp_dt.
    set warp_physics to false.
  }
}

unlock warp_dt.
unlock warp_atmo.
