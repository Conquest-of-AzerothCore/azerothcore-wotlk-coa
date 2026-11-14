# Pulse targets (`behaviour_metric_delta`, `kind: "pulse_targets"`, ADR 0550)

One creature's area pulses are read per pulse: each dummy's hits are polled with game-time stamps, the dummies
struck between two reads are one pulse's targets, and none may exceed the stated cap (Bonestorm 801411, Animate:
Bone Wraith 805032).
