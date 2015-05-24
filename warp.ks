// Warp time (while on rails) so that a certain amount of time passes.
declare parameter dt.

// warp (0:1) (1:5) (2:10) (3:50) (4:100) (5:1000)
set dt to round(dt).
set t0 to round(time:seconds).
set t1 to t0 + dt.


if dt > 5 {
  print "Warp: for " + dt + "s".
  if dt > 3000 {
      print "Warp: 5".
      set warp to 5.
  }
  if dt > 3000 {
      when time:seconds > t1 - 3000 then {
          print "Warp: 4".
          set warp to 4.
      }
  }
  if dt > 300 and dt <= 3000 {
      print "Warp: 4".
      set warp to 4.
  }
  if dt > 300 {
      when time:seconds > t1 - 300 then {
          print "Warp: 3".
          set warp to 3.
      }
  }
  if dt > 10 and dt < 300 {
      print "Warp: 3".
      set warp to 3.
  }
  if dt > 60 {
      when time:seconds > t1 - 60 then {
          print "Warp: 2".
          set warp to 2.
      }
  }
  if dt > 30 {
      when time:seconds > t1 - 30 then {
          print "Warp: 1".
          set warp to 1.
      }
  }
  if dt > 10 {
      when time:seconds > t1 - 10 then {
          print "Warp: realtime, " + round(t1-time:seconds) + "s remain".
          set warp to 0.
      }
  }
  wait until time:seconds > t1.

  print "Warp: complete @ " + time:calendar + " " + time:clock.
}
