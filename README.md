Introduction
============

Getting Started
===============

Run the launch program to ascend to a circular orbit 20km above your local
atmosphere:

    run launch.

After you reach a stable orbit, plan maneuvers using the `node-` programs and
execute them using the program whose name is simply `node`.

    run nodeapo(180000). // plan periapsis burn to raise apo to 180km
    run node.            // make it so!

Automating a Mission
--------------------

If you want to automate your entire mission end-to-end, it is highly suggested
that you copy the `launch` program into a program named `mission` that lives
on your vessel.

The `mission` program should be capable of running any phase of your mission;
when executed, it should inspect the state of the world to determine which
phase is current and resume operation starting with that phase.

kOS halts execution when you switch away from a vessel. By creating an
idempotent mission script, you will save yourself from endless frustration
having to reprogram your CPUs and remember your progress every time you restore
a saved game!

Preparing for Launch
--------------------

TODO - implement/discuss `prep` script to precompile all programs & copy them
onto the vessel's CPUs.


Contributing & Customizing
==========================

Program Naming
--------------

One-word programs should require no parameters so they can be `run` from the
console. Multi-word programs may accept many parameters and must be called
like a function (generally by another program, or possibly from the console).

Program names must be as short as possible while still conveying the purpose
of the program.

Names must follow lexical ordering, i.e. all programs related to maneuver-node
management begin with `node-`: `nodeapo`, `nodecirc` and so forth. The program
simply named `node` is standalone; it executes the next node, then halts.

The additional words of a program name should convey _when_
the program is designed to run. For example:

1. `nodeapo`: create node at apoapsis to change periapsis altitude
2. `launchascend`: perform ascent phase of launch

Parameter Passing
-----------------

Whenever possible, programs and functions should accept parameters with
"ordinary" units. The name of the parameter should convey its unit of measure.
Preferred units are:

1. Name of orbital position e.g. "apoapsis"
2. Universal time (UT) in seconds after the epoch
3. Altitude (ALT) in meters
4. Estimated time (ETA) in seconds after current time

Function Libraries
------------------

The programs under `lib/` are reusable code that you can copy-paste into
programs in order to save time. kOS doesn't support true code sharing, but we
can share code by being good citizens and curating our library.

Comments and Documentation
--------------------------

Every program should begin with comments explaining what the program does.
Functions should be likewise commented. Every parameter (to a program _or_ a
function) needs a comment explaining the purpose of the parameter and whether it
is optional.

Roadmap
=======

0. Annotate programs with helpful comments, source citations
1. Rethink how plane-change is planned
      - at equ AN/DN are handy (esp for inclined circular orbits)
      - cheaper would be at apoapsis (for elliptical orbits)
      - compare w/MechJeb planning
      - build recircularization into the burn?
2. Implement align-plane-to-target command
      - grok http://www.braeunig.us/space/orbmech.htm#maneuver (grep for '#4.24')
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
