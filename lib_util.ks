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
  local bignumber is 999999999.
  local sentinel is node(time:seconds + bignumber, 0, 0, 0).
  add sentinel.
  local nn is nextnode.
  remove sentinel.
  if nn = sentinel {
    return false.
  } else {
    return true.
  }
}

FUNCTION OffsetSteering {

// This function is intended to use with shuttles and spaceplanes that have engines not in line with CoM.
// Usage: LOCK STEERING TO OffsetSteering(THEDIRECTIONYOUWANTTOSTEER).
// Example: LOCK STEERING TO OffsetSteering(PROGRADE).
// 2017 FellipeC - Released under https://creativecommons.org/licenses/by-nc/4.0/

  PARAMETER DIRTOSTEER. // The direction you want the ship to steer to
  LOCAL NEWDIRTOSTEER IS DIRTOSTEER. // Return value. Defaults to original direction.

  LOCAL OSS IS LEXICON(). // Used to store all persistent data
  LOCAL trueacc IS 0. // Used to store ship acceleration vector

  FUNCTION HasSensors { 
    // Checks if ship have required sensors:
    // - Accelerometer (Double-C Seismic Accelerometer) 
    // - Gravity Sensor (GRAVMAX Negative Gravioli Detector)
    LOCAL HasA IS False.
    LOCAL HasG IS False.
    LIST SENSORS IN SENSELIST.
    FOR S IN SENSELIST {
      IF S:TYPE = "ACC" { SET HasA to True. }
      IF S:TYPE = "GRAV" { SET HasG to True. }
    }
    IF HasA AND HasG { RETURN TRUE. }
    ELSE { RETURN FALSE. }
  }

  IF HasSensors() { // Checks for sensors
    LOCK trueacc TO ship:sensors:acc - ship:sensors:grav.
  }
  ELSE { // If ship have no sensors, just returns direction without any correction
    RETURN DIRTOSTEER. 
  }

  FUNCTION InitOSS {
    // Initialize persistent data.
    LOCAL OSS IS LEXICON().
    OSS:add("t0",time:seconds).
    OSS:add("pitch_angle",0).
    OSS:add("pitch_sum",0).
    OSS:add("yaw_angle",0).
    OSS:add("yaw_sum",0).
    OSS:add("Average_samples",0).
    OSS:add("Average_Interval",1).
    OSS:add("Average_Interval_Max",5).
    OSS:add("Ship_Name",SHIP:NAME:TOSTRING).
    
    RETURN OSS.
  }

  IF EXISTS("oss.json") { // Looks for saved data
    SET OSS TO READJSON("oss.json"). 
    IF OSS["Ship_Name"] <> SHIP:NAME:TOSTRING {
      SET OSS TO InitOSS(). 
    }
  }
  ELSE {
    SET OSS TO InitOSS(). 
  }

  // Only account for offset thrust if there is thrust!
  if throttle > 0.1 { 
      local dt to time:seconds - OSS["t0"]. // Delta Time
      if dt > OSS["Average_Interval"]  {
        // This section takes the average of the offset, reset the average counters and reset the timer.
        SET OSS["t0"] TO TIME:SECONDS.
        if OSS["Average_samples"] > 0 {
          // Pitch 
          SET OSS["pitch_angle"] TO OSS["pitch_sum"] / OSS["Average_samples"]. 
          SET OSS["pitch_sum"] to OSS["pitch_angle"].
          // Yaw
          SET OSS["yaw_angle"] TO OSS["yaw_sum"] / OSS["Average_samples"]. 
          SET OSS["yaw_sum"] to OSS["yaw_angle"].
          // Sample count
          SET OSS["Average_samples"] TO 1.
          // Increases the Average interval to try to keep the adjusts more smooth.
          if OSS["Average_Interval"] < OSS["Average_Interval_Max"] { 
            SET OSS["Average_Interval"] to max(OSS["Average_Interval_Max"], (OSS["Average_Interval"] + dt)) .
          } 
        }
      }
      else { // Accumulate the thrust offset error to be averaged by the section above
          
          // Thanks to reddit.com/user/ElWanderer_KSP
          // exclude the left/right vector to leave only forwards and up/down
          LOCAL pitch_error_vec IS VXCL(FACING:STARVECTOR,trueacc).
          LOCAL pitch_error_ang IS VANG(FACING:VECTOR,pitch_error_vec).
          If VDOT(FACING:TOPVECTOR,pitch_error_vec) > 0{
            SET pitch_error_ang TO -pitch_error_ang.
          }

          // exclude the up/down vector to leave only forwards and left/right
          LOCAL yaw_error_vec IS VXCL(FACING:TOPVECTOR,trueacc).
          LOCAL yaw_error_ang IS VANG(FACING:VECTOR,yaw_error_vec).
          IF VDOT(FACING:STARVECTOR,yaw_error_vec) < 0{
            SET yaw_error_ang TO -yaw_error_ang.
          }
          //LOG "P: " + pitch_error_ang TO "0:/oss.txt".
          //LOG "Y: " + yaw_error_ang TO "0:/oss.txt".
          set OSS["pitch_sum"] to OSS["pitch_sum"] + pitch_error_ang.
          set OSS["yaw_sum"] to OSS["yaw_sum"] + yaw_error_ang.
          SET OSS["Average_samples"] TO OSS["Average_samples"] + 1.
      }
      // Set the return value to original direction combined with the thrust offset
      //SET NEWDIRTOSTEER TO r(0-OSS["pitch_angle"],OSS["yaw_angle"],0) * DIRTOSTEER.
      SET NEWDIRTOSTEER TO DIRTOSTEER.
      IF ABS(OSS["pitch_angle"]) > 1 { // Don't bother correcting small errors
        SET NEWDIRTOSTEER TO ANGLEAXIS(-OSS["pitch_angle"],SHIP:FACING:STARVECTOR) * NEWDIRTOSTEER.
      }
      IF ABS(OSS["yaw_angle"]) > 1 { // Don't bother correcting small errors
        SET NEWDIRTOSTEER TO ANGLEAXIS(OSS["yaw_angle"],SHIP:FACING:UPVECTOR) * NEWDIRTOSTEER.
      }
  } 
  // Saves the persistent values to a file.
  WRITEJSON(OSS,"oss.json").
  RETURN NEWDIRTOSTEER.
}
