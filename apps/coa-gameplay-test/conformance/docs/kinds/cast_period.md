# Cast periods (`behaviour_metric_delta`, `kind: "cast_period"`, ADR 0535)

A real `setup_spell` cast raises creature `entry`; uncommanded for `control_ms` it must cast no `cast_spell`. Then
`trigger_spell` at the dummy and, every `poll_ms` over `window_ms`, the game time and the creature's casts are read. The
first and the last cast are bracketed between stamped reads, and (last - first) / (n - 1) must lie inside `expected_ms`
+- the G-19 band (Animate: Plaguefather 805048: Bone Toss 704706 every 1000 ms).
