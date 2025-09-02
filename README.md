# DRTracker - Diminishing Returns Tracker for Project-Epoch (3.3.5a)

Tracks Diminishing Returns on your current Target & Focus, in separate movable frames.\
Early version, let me know any bugs. Only tested with Mage and having one of my Rogue friends sap, which triggered my Poly DR correctly.

Needs to be your current target/focus to work. Doesn't track anything else. Blame the shitty CLEU on epoch...

The DR will show up on cast, but will refresh after it falls off, since this is how DR's should work. As far as I know the DR starts counting after the debuff falls off. (in TBC at least...) Might be able to add a command that only starts showing the DR after the debuff falls off if you would prefer that. Or if I'm wrong about DR's LMK.

Commands:\
/drt unlock — Unlock and show the target/focus DR frames to move them.

/drt lock — Lock the frames.

/drt scale target|focus <0.5–3.0> — Set scale of the target/focus DR frames. Default: 1.0.

/drt icons — On shows your DR Category icons always with a green border when not Diminished, Off only shows the icons when there is a DR

/drt reset — Factory reset (Reset everything, back to factory settings xd).

/drt debug — Toggle NPC tracking for testing (ON includes NPCs; OFF shows players & pets only).
