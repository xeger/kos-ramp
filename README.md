Introduction
============

Getting Started
===============

Roadmap
=======

0. Annotate programs with helpful comments, source citations
1. Generalize nodeplane so plane-change can be planned at any time (not just now).
2. Implement plane-change and align commands. 
3. Hohmann transfer
4. Match velocity

Scratchpad
==========

Tsiolkovsky burn duration
-------------------------

Derived from http://wiki.kerbalspaceprogram.com/wiki/Tutorial:Advanced_Rocket_Design#Delta-V

Basic idea: compute vessel Isp; mass-flow rate of engines; total mass burn;
derive burn duration using Tsiolkovsky formula.

Implemented, but it doesn't work; it gives bogus duration. Need to debug...

    list engines in engs.
    local thrustSum is 0.0.
    local denomSum is 0.0.

    FOR eng IN engs
    {
      local thrust is eng:maxthrust * eng:thrustlimit.
      set thrustSum to thrustSum + thrust.
      set denomSum to denomSum + (thrust / (eng:isp * 9.82)).
    }.

    local Isp is thrustSum / denomSum.
    local massBurn is ((ship:mass * 1000) / constant():e ^ (nd:deltav:mag / Isp)).
    local tsiol is ((ship:mass* 1000) - massBurn) / (thrustSum / Isp).

Plane change derived from MechJeb pseudocode
--------------------------------------------

Stopped port halfway in favor of a simpler technique.

    function clamp360 {
      parameter angle.

      set angle to angle % 360.
      if angle > 180 {
        set angle to angle - 360.
      }

      return angle.
    }

    function clamp180 {
      parameter angle.

      set angle to clamp360(angle).
      if angle > 180 {
        set angle to angle - 360.
      }

      return angle.
    }

    function hdg4inclin {
      parameter inc.
      parameter lat.

      local cosSrfAng is cos(inc) / cos(lat).

      if abs(cosSrfAng) > 1.0 {
        // inclination < latitude; impossible solution
        if clamp180(inc) < 90 {
          return 90.
        } else {
          return 270.
        }
      } else {
        local angEast = acos(cosSrfAng).
        if inc < 0 {
          set angEast = angEast * -1.
        }

        return clamp360(90 - angEast).
      }
    }

    function dvinclin {

    }

    public static Vector3d DeltaVToChangeInclination(Orbit o, double UT, double newInclination)
    {
        double latitude = o.referenceBody.GetLatitude(o.SwappedAbsolutePositionAtUT(UT));
        double desiredHeading = HeadingForInclination(newInclination, latitude);
        Vector3d actualHorizontalVelocity = Vector3d.Exclude(o.Up(UT), o.SwappedOrbitalVelocityAtUT(UT));
        Vector3d eastComponent = actualHorizontalVelocity.magnitude * Math.Sin(Math.PI / 180 * desiredHeading) * o.East(UT);
        Vector3d northComponent = actualHorizontalVelocity.magnitude * Math.Cos(Math.PI / 180 * desiredHeading) * o.North(UT);
        if (Vector3d.Dot(actualHorizontalVelocity, northComponent) < 0) northComponent *= -1;
        if (MuUtils.ClampDegrees180(newInclination) < 0) northComponent *= -1;
        Vector3d desiredHorizontalVelocity = eastComponent + northComponent;
        return desiredHorizontalVelocity - actualHorizontalVelocity;
    }
