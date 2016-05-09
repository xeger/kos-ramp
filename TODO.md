TODO.md

Hohmann: maybe find a new way...
  obs: encounter is always T / 2 after burn point
   - if we can determine post-burn T, and positionat reacts to planned changes, I can find closest approach dist!
   - use this to bisect the time line...

- troubleshoot Hohmann
    - not always finding a window
    - buggy Minmus dv
    - runs smack into Mun

- troubleshoot rendezvous/approach
    - node_inc_tgt gets flipped axes sometimes (target orbiting westward?)
    - rendezvous gets stuck on final approach; it cancels forward velocity too well!
    - freeze on "final approach"

- troubleshoot landing
    - final descent far too early? unnecessary braking?

- warp during ascent is too frisky (wait till out of atmo)

- warp during landing

- troubleshoot node runner
    - excessively fussy about residual dv
    - fudge warp for facing-off-target

- troubleshoot node_inc_tgt
    - ???
