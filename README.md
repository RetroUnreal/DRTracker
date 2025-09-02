# DRTracker - Diminishing Returns Tracker for Project-Epoch (3.3.5a)

Tracks Diminishing Returns on your current Target & Focus, in separate movable frames.\
Early version, let me know any bugs. Only tested with Mage and having one of my Rogue friends sap, which triggered my Poly DR correctly.

Needs to be your current target/focus to work. Doesn't track anything else. Blame the shitty CLEU on epoch...\
Although untargeting and retargeting a player you DR'd on should keep the DR.

With "/drt icons" turned ON (default) it will show all your classes DR Categories in the Target/Focus DR Frames with a green border if there is no DR, a yellow border for the first DR and a red border for the third DR and on

With  "/drt icons" turned OFF it will only start showing the DR's in Yellow as soon as they happpen.

The DR will show up on cast, but will refresh after it falls off, since this is how DR's should work. As far as I know the DR starts counting for 18 seconds after the debuff falls off. (in TBC at least...) Might be able to add a command that only starts showing the DR timer after the debuff falls off if you would prefer that. Or if I'm wrong about DR's on Project-Epoch, LMK.

# Commands:
/drt — Shows all commands and their intended usage, and your classes DR Categories below them.

/drt unlock — Unlock and show the target/focus DR frames to move them.

/drt lock — Lock the frames.

/drt scale target <0.5–3.0> — Set scale of the target DR frame. Default: 1.0.

/drt scale focus <0.5–3.0> — Set scale of the focus DR frame. Default: 1.0.

/drt icons — On shows your DR Category icons always with a green border when not Diminished, Off only shows the icons when there is a DR

/drt reset — Factory reset (Reset everything, back to factory settings xd).

/drt debug — Toggle NPC tracking for testing (ON includes NPCs; OFF shows players & pets only).
