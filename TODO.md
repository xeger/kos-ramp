TODO.md

- use global var to control physics warp

- integrate deorbit & landing
  - don't mess up trajectory; use different approach? e.g. positionat(perigee) vs terrain height?

- troubleshoot landing
    - braking burn doesn't work right! fails when coming in "hot"
    - final descent far too early? unnecessary braking?

- troubleshoot rendezvous/approach
    - rendezvous gets stuck on final approach

- warp during landing

Hohmann: maybe find a new way...
  obs: encounter is always T / 2 after burn point
   - if we can determine post-burn T, and positionat reacts to planned changes, I can find closest approach dist!
   - use this to bisect the time line...

- troubleshoot Hohmann
    - not always finding a window
    - buggy Minmus dv
