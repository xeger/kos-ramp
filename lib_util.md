About utilFaceBurn Function
===========================

Some crafts, specially shuttles and space planes, may have engines thrust vector offset from the craft longitudinal axis. This will lead to some inaccuracies when burning a maneuver node pointing the craft nose to it.

The function utilFaceBurn tries to compensate for that, pointing the craft in a way the true acceleration vector matches the desired direction, not the ship nose. 

How it works
------------

The function uses data from Double-C Seismic Accelerometer and GRAVMAX Negative Gravioli Detector to compute the real acceleration of the craft and make the corrections as needed. 

The function will not compute any corrections for crafts without the required sensors installed. 

This function will save a file called *oss.json* in the same directory it ran. That file contains all persistent data the function computes. It's safe to delete the file, the only effect is a reduced precision in next time the function is used, for few seconds, until it computes new data.

How to use this function in your own scripts
--------------------------------------------

Make sure to include the command *run once lib_util.ks* (or any file that contain the function) before trying to use ti.
Then change any *LOCK STEERING* statement to use the function, exemple:

	LOCK STEERING TO utilFaceBurn(PROGRADE).

About utilRCSCancelVelocity FUNCTION
====================================

This function intends to use the ship's RCS system to zero the magnitude of a vector, usually a manoeuvre node vector or a relative speed vector.
To be able to do that, the function must be able to keep track of such vector while it's running. Usually passing a vector as a parameter to a function, for example:
```
function myFun {
  parameter SomeVector.
  //do something...
}

lock myVec to someNode:deltaV.
myFun(myVec).
```
Makes a copy of `myVec` with the value it had the moment the function was called. So, every time the function checks the value of `SomeVector` parameter, it will be the same, regardless what happens. 
To solve that, usually, the value should be passed *by reference* to the function. That is not an option in KerboScript.
But we can exploit how the `lock` keyword works under the hood. Every time we `lock` a variable to something, for example:
`lock myVal to SHIP:ALTITUDE * 2.`
Under the hood KerboScript compiler do something like this:
```
function myVal {
    return SHIP:ALTITUDE * 2.
}
```
This means we can handle locked variables as functions (because they are indeed functions!) and, for example, use parenthesis, like `myVal()` to access that locked variable from within other script file, or use at sign like `myVal@` to get a *delegate* to that function.
This means that if we pass `myVal@` as a parameter to a function, it will be able to use that delegate (also called handle or pointer in other languages) to access the updated return value of `myVal`.
So, in order to properly use `utilRCSCancelVelocity` we first must lock some variable to the desired vector we want `utilRCSCancelVelocity` to Cancel:
`lock ndDeltaV to -nodeNd:deltav.`
Then we can call `utilRCSCancelVelocity` with a delegate to that variable:
`utilRCSCancelVelocity(ndDeltaV@,0.1,15).`
The other two parameters are optional and are respectively the maximum amount of velocity is tolerable (note that 0 is, in pratice, impossible. There will be ever some very small error) and the maximum time the script should keep trying to zero that speed. The default values are respectively `0.1`m/s and `15`s.
