/////////////////////////////////////////////////////////////////////////////
// Warp time
/////////////////////////////////////////////////////////////////////////////
// Block until dt seconds have elapsed; use physics or rails warp as needed
// to accelerate simulated game time.
/////////////////////////////////////////////////////////////////////////////

declare parameter dt.

set TW to kuniverse:timewarp.

if dt > 0 {
  set TW:MODE to "RAILS".
  tw:warpto(time:seconds + dt).
  wait dt.
  wait until tw:ISSETTLED.
}

if false { // This section should be obsolete

// Number of seconds to sleep during physics-warp loop
global warp_tick is 1.

global warp_physics is true.
global warp_t0 is time:seconds.
global warp_t1 is warp_t0 + dt . 

// special case: negative interval means skip all loop iterations & return
if dt < 0 {
  set warp_t1 to warp_t0.
}

lock warp_dt to warp_t1 - time:seconds.
lock warp_atmo to ship:altitude / max(ship:altitude, body:atm:height). 


until time:seconds >= warp_t1 {
  if ship:altitude < body:atm:height and ship:status <> "PRELAUNCH" and ship:status <> "LANDED" {
    set warpmode to "physics".
    set warp_physics to true.

	// To enable Atmosphere Time Warp (Physics warp), change the values 0 to the Warp value you want:
	// 0 = No Warp (1x)
	// 1 = 2x Warp
	// 2 = 3x Warp
	// 3 = 4x Warp 
	// WARNING! Physics warp may lead to inaccuracies in the physics calculation, possibly damaging the vessel. Complex, long, and highly-accelerated vessels are at risk of destruction if physical time warp is enabled. Wobbling becomes much more likely with physics warp turned on. It is therefore recommended not to have more than 2x physical time warp with high-thrust engines enabled. (Text from KSP Wiki)
	
    if warp_atmo > 0.8 {
      set warp to 0. // CHANGE HERE TO ENABLE PHYSICS WARP. Suggestion: 3
    } else if warp_atmo > 0.6 {
      set warp to 0. // CHANGE HERE TO ENABLE PHYSICS WARP. Suggestion: 2
    } else if warp_atmo > 0.2 {
      set warp to 0. // CHANGE HERE TO ENABLE PHYSICS WARP. Suggestion: 1
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
}