# DRTracker - Diminishing Returns Tracker for Project-Epoch (3.3.5a)

Tracks Diminishing Returns on your current Target & Focus, in separate movable frames.\
Early version, let me know any bugs. Only tested with Mage and having one of my Rogue friends sap, which triggered my Poly DR correctly.

Needs to be your current target/focus to work. Doesn't track anything else. Blame the shitty CLEU on epoch...\
Although untargeting and retargeting a player you DR'd on keeps the DR.

Works for shared DR's as well ! for example if you were a Mage and another Rogue casts Sap on your Target or Focus,\
Your Polymorph will show DR and vice versa.

With "/drt icons" turned ON (default) it will show all your classes DR Categories in the Target/Focus DR Frames:\
No border = No DR\
Green border = First DR\
Yellow border= Second DR\
Red border = Third DR

With  "/drt icons" turned OFF it will only start showing the DR's in the Target & Focus frames as soon as they happpen.

The Yellow/Red DR will show up on CC applied & refreshed,\
18 Second DR Window timer will only show up after the CC ends.\
(Like Diminishing Returns work in TBC, this should be correct but I only tested the DR Window once and 18 seconds wait was enough for a full Polymorph, let me know if you find a bug.)

# Commands:
/drt — Shows all commands and their intended usage, and your classes DR Categories below them.

/drt unlock — Unlock and show the target/focus DR frames to move them.

/drt lock — Lock the frames.

/drt scale target <0.5–3.0> — Set scale of the target DR frame. Default: 1.0.

/drt scale focus <0.5–3.0> — Set scale of the focus DR frame. Default: 1.0.

/drt icons — On shows your DR Category icons always with a green border when not Diminished, Off only shows the icons when there is a DR

/drt reset — Factory reset (Reset everything, back to factory settings xd).

/drt debug — Toggle NPC tracking for testing (ON includes NPCs; OFF shows players & pets only).
