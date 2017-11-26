// Delta vee math stolen from http://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
// Phase angle math stolen from https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit and here https://forum.kerbalspaceprogram.com/index.php?/topic/122685-how-to-calculate-a-rendezvous/ and from here too https://forum.kerbalspaceprogram.com/index.php?/topic/85285-phase-angle-calculation-for-kos/

parameter MaxOrbitsToTransfer is 5.
parameter MinLeadTime is 30.

runoncepath("lib_ui").
runoncepath("lib_util").

// Compute prograde delta-vee required to achieve Hohmann transfer; < 0 means
// retrograde burn.
function hohmannDv {
  local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
  local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.

  return sqrt(body:mu / r1) * (sqrt( (2*r2) / (r1+r2) ) - 1).
}

// Compute time of Hohmann transfer window.
function hohmannDt {

  local r1 is ship:obt:semimajoraxis.
  local r2 is target:obt:semimajoraxis.

  local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
  local ft is pt - floor(pt).

  // angular distance that target will travel during transfer
  local theta is 360 * ft.
  // necessary phase angle for vessel burn
  local phi is 180 - theta.

  uiDebug("Phi:" + phi).

  // Angles to universal reference direction. (Solar prime)
  set sAng to ship:obt:lan+obt:argumentofperiapsis+obt:trueanomaly. 
  set tAng to target:obt:lan+target:obt:argumentofperiapsis+target:obt:trueanomaly. 

  local timeToHoH is 0.

  // Target and ship's angular speed.
  local tAngSpd is 360 / target:obt:period.
  local sAngSpd is 360 / ship:obt:period.

  // Phase angle rate of change, 
  local phaseAngRoC is tAngSpd - sAngSpd. 

  // Loop conditions variables
  local HasAcceptableTransfer is false.
  local IsStranded is false.
  local tries is 0.
  until HasAcceptableTransfer or IsStranded {

      // Phase angle now.
      set pAng to utilReduceTo360(tAng - sAng).
      uiDebug("pAng: " + pAng).
    
      if r1 < r2 { // Target orbit is higher
        set DeltaAng to utilReduceTo360(pAng - phi).
      }
      else { // Target orbit is lower
        set DeltaAng to utilReduceTo360(phi - pAng).
      }
      set timeToHoH to abs(DeltaAng / phaseAngRoC).
      uiDebug("TTHoh:" + timeToHoH).

      if timeToHoH > ship:obt:period * MaxOrbitsToTransfer set IsStranded to true.
      else if timeToHoH > MinLeadTime set HasAcceptableTransfer to true.
      else {
          // Predict values in future
          set tAng to tAng + MinLeadTime*tAngSpd.
          set sAng to sAng + MinLeadTime*sAngSpd.
      }
      set tries to tries + 1.
      if tries > 1000 set IsStranded to true.
      if IsStranded break.
  }
  if IsStranded return "Stranded".
  else return timeToHoH + time:seconds.  
}

if body <> target:body {
  uiWarning("Node", "Incompatible orbits").
}
if ship:obt:eccentricity > 0.01 {
  uiWarning("Node", "Eccentric ship e=" + round(ship:obt:eccentricity, 1)).
}
if target:obt:eccentricity > 0.01 {
  uiWarning("Node", "Eccentric target e=" +  + round(target:obt:eccentricity, 1)).
}

global node_ri is obt:inclination - target:obt:inclination.
if abs(node_ri) > 0.2 {
  uiWarning("Node", "Bad alignment ri=" + round(node_ri, 1)).
}

uiDebug("Hohmann delta V").
global node_dv is hohmannDv().

uiDebug("Hohmann time").
global node_T is hohmannDt().

if node_T = "Stranded" {
  uiError("Node", "STRANDED").
}
else {
  add node(node_T, 0, 0, node_dv).
  uiDebug("Transfer eta=" + round(node_T - time:seconds, 0) + " dv=" + round(node_dv, 1)).
}
