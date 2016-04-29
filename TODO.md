TODO.md

- troubleshoot rendezvous/approach
    - rendezvous gets stuck on final approach; it cancels forward velocity too well!

- rework ascent code to account for vessel aerodynamics to keep it from "tipping"
  due to 1.x aerodynamics model when vessel is massive and/or wide. Two ideas:
    - adjust gt0 and gtScale according to biggest part (ugh)
    - use vessel mass to decide how far ship is allowed to stray from surface velocity vector

- warp during ascent is too frisky (wait till out of atmo)

- troubleshoot Hohmann
    - not always finding a window
    - buggy Minmus dv
    - runs smack into Mun

- warp during landing

- troubleshoot node runner
    - excessively fussy about residual dv
    - fudge warp for facing-off-target

- troubleshoot node_inc_tgt
    - ???
