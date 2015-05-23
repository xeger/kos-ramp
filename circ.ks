parameter circAt.

local errMax is 10.
local obt is ship:obt.

if circAt = "apoapsis" {
  local apoR is obt:apoapsis.
  local apoT is TIME + eta:apoapsis.

  local nd is node(apoT:seconds, 0, 0, 0).
  add nd.

  local sma is (apoR + obt:body:radius).

  local err0 is (sma - nd:orbit:semimajoraxis).
  lock err to (sma - nd:orbit:semimajoraxis).
  until err < errMax {
    set nd:prograde to nd:prograde + 100 * abs(err / err0).
  }

  local a is ship:maxthrust/ship:mass.
  local dT is nd:prograde/a.
  print "Node: circularization burn in " + round(nd:eta) + " s".
} else if circAt = "periapsis" {

} else {
  print "Don't know how to circularize at " + circAt.
  set error to 1 / 0.
}
