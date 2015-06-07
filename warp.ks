// Warp time (while on rails) so that a certain amount of time passes.
declare parameter dt.

// NOTES:
// warp (0:1) (1:5) (2:10) (3:50) (4:100) (5:1000)
// physics (0:1) (1:2) (2:3) (3:4)

set t0 to time:seconds.
set t1 to t0 + dt.

if ship:altitude < body:atm:height and ship:status <> "PRELAUNCH" and ship:status <> "LANDED" {
  set warpmode to "physics".

  if dt > 5 {
    set warp to 3.
    wait until time:seconds >= t1 - 5 or ship:altitude > body:atm:height.
  }

  set warp to 0.
  set warpmode to "rails".
  set dt to t1 - time:seconds.
}

if dt > 5 {
  if dt > 3000 {
      set warp to 5.
  }
  if dt > 3000 {
      when time:seconds > t1 - 3000 then {
          set warp to 4.
      }
  }
  if dt > 300 and dt <= 3000 {
      set warp to 4.
  }
  if dt > 300 {
      when time:seconds > t1 - 300 then {
          set warp to 3.
      }
  }
  if dt > 10 and dt < 300 {
      set warp to 3.
  }
  if dt > 60 {
      when time:seconds > t1 - 60 then {
          set warp to 2.
      }
  }
  if dt > 30 {
      when time:seconds > t1 - 30 then {
          set warp to 1.
      }
  }
  if dt > 5 {
      when time:seconds > t1 - 5 then {
          set warp to 0.
      }
  }
  wait until time:seconds >= t1.
}
