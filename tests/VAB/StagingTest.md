Launch test can be performed from any of the two cores and there should be only one difference:
running from *sis* won't extend one of *bro's* antennas, because one is tagged *bro*.

Stage 8: Must not stage Hammers until the tanks are empty
Stage 7: Tank-only stage, both must be empty
Stage 6: Sparks must be decoupled when their tanks are empty
Stage 5: -
Stage 4: No staging until all three are flamed-out. Terrier should flame-out before Fleas, but launch script can throttle down and change that.
Stage 3: -

Solar panels and at least one antenna has to be extended when out of atmosphere (both antennas if run from *bro*).
Solar panels and antennas on *sis* **must not** be extended!

Fairings around *sis* will get deployed because `lib_parts` is unable to distinguish between the two decouplers. 
It sees that it is to be decoupled by the upper one, but thinks both have `noauto` tag. Could be improved, 
but I see no real harm (solution would be to double check: find the decoupler and check its tag if `fairing:stage = maxStage`).
Adding tag directly to the fairing should solve it too.
