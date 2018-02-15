Introduction
============

Relatively Adequate Mission Planner (RAMP) is a set of kOS programs that aims
to improve your [KSP](http://kerbalspaceprogram.com) experience in several ways:

 - Maximize the precision of your maneuvers
 - Let you focus on the fun parts of spaceflight by automating the drudgework
 - Teach you about orbital mechanics and physics

You can use the scripts as a kind of autopilot or poke into them to
see how everything works, learn about the underlying science, or customize
them to your needs.

Getting Started
===============

RAMP scripts have a naming pattern: one-word scripts can be executed without any
parameters, and multi-word scripts require parameters. Comments at the top of
every script explain what it does and which parameters it needs.

Run the launch program to ascend to a circular orbit a few hundred km above
your local atmosphere:

    run launch.

After you reach a stable orbit, select a target. Use the transfer or rendezvous script to reach your target.

    set target to vessel("My Other Vessel").
    run rendezvous. // travel to another vessel

    set target to body("Mun").
    run transfer. // or, travel to a moon

The boot, rendezvous and transfer scripts are [idempotent](https://en.wikipedia.org/wiki/Idempotence):
you can safely run them at any time; they either make progress toward your goal, or error out
with an explanation as to why they can't. The [universal boot leader](boot/README.md) is customizable per ship.

Maneuvers
=========

Other idempotent scripts include:

    run circ.             // circularize at nearest apsis
    run circ_alt(250000). // circularize to specific altitude of 250km
    run approach.         // get close to target and stop
    run match.            // match velocity at closest approach to target
    run dock.             // dock with your target

Planning Burns by Hand
----------------------

You can also plan and execute on-orbit maneuvers by hand using the `node_*` scripts.

    run node_apo(1000000). // plan to make our apogee huge!
    run node.              // make it so

Automating a Mission
====================

If you want to script your entire mission end-to-end, it is highly suggested
that you choose `boot` as the boot script for your vessel's main CPU. When
your ship is on the pad, `RUN initialize.` to create a sample Mun mission for
your craft.

To change the mission profile, just edit the startup script that now lives under
`start/YourCraftName.ks` and launch a fresh craft of that name. The sample script
is not very robust; under the `mission/` subfolder, RAMP provides several other
example missions from which you can derive startup files.

You can learn more about bootstrapping in [this file.](https://github.com/xeger/kos-ramp/blob/master/boot/README.md)

Preparing for Launch
--------------------

If your ship will travel farther than 100km from KSC, you should install
a CPU with enough space on the vessel and run `boot` to copy the mission
software onto the primary volume. Running archive scripts is fine in low
orbit, but a space probe needs to be able to think for itself!

Contributing & Customizing
==========================

Clone my repo. Hack to your enjoyment. Pull requests are gladly accepted!

*WARNING*: notice the control flow between programs is fairly flat. I try never
to call more than 2-3 programs deep. This is because the kOS VM seems to have
bugs with programs and functions calling one another. Specifically:

1. Local variables from inner programs sometimes overwrite same-named variables from the outer program
2. Function libraries don't seem to work when they are compiled code

See comments in `node_apo`/`node_peri` for an example of #1.
Try to compile `lib_ui` and run it from another program for an example of #2.

Design Principles
-----------------

RAMP's code should be:

1. Safe: scripts should check for errors and harmful conditions
2. Modular: each script accomplishes a specific purpose
3. Reusable: scripts call library functions rather than copy-pasting code
4. Educational: comments explain each script and provide science and math background
5. Ethical: anything copied or derived from an outside work includes a link to the original

Program Naming
--------------

One-word programs should require no parameters so they can be `run` from the
console. Multi-word programs may accept many parameters and must be called
like a function (generally by another program, or possibly from the console).

Program names must be as short as possible while still conveying the purpose
of the program.

Names must follow lexical ordering, i.e. all programs related to maneuver-node
management begin with `node`: `node_apo`, `node_peri` and so forth. The program
simply named `node` is standalone; it executes the next node, then halts.

The additional words of a program name should convey _what_ the program
accomplishes for single-purpose programs, and _when_ during the mission
the program needs to run, for more complex or long-running program.

1. `node_apo`: create node to change apoapsis
2. `launch_asc`: perform ascent phase of launch

Parameter Passing
-----------------

Whenever possible, programs and functions should accept parameters with
"ordinary" units and frames of reference. The name of the parameter
should convey its unit of measure. Suggested units/frames are:

1. Name of ship orbital position e.g. "apoapsis"
2. Universal time (UT) in seconds after the epoch
3. Altitude (ALT) in meters above SoI surface

Function Libraries
------------------

Programs beginning with `lib_` contain reusable functions and are invoked by
other programs using `RUN ONCE` or `RUNONCEPATH()`.

Beware that libs cannot run other libs! If two library scripts depend on one another's functions, then you must make sure to `RUN ONCE` both scripts from every top-level program that uses either oft hem!

Comments and Documentation
--------------------------

Every program should begin with comments explaining what the program does.
Functions should be likewise commented. Every parameter (to a program _or_ a
function) needs a comment explaining the purpose of the parameter.
