# After setup stacks (`metric_delta` `after_setup_stacks`, ADR 1257)

`after_setup_stacks` is a non-empty list of `{"spell": id, "actor": "caster" or "dummy", "stacks": N}` (N a whole number
from 0). In every phase that makes the entry's `setup_casts`, right after the last setup cast (and its
`setup_wait_ms`), before the triggering cast, the scenario reads `aura_stacks` of each spell on its unit, labelled
`<spell> after_setup_stacks <actor> <aura> before|after`. A count other than N makes the run `unmeasured`; so does a
missing after-phase read. A before-phase read is judged when the before phase made the setup casts. A match leaves the
plain verdict. The read is a precondition check: it never makes a verdict `ok` or `alert` and adds no counted label.
A spell names one unit once.

Needs `setup_casts` and no `attack_swings`. Use `after_setup_reads` for a caster aura read as present or absent.

Named points: `setup_cast_steps` (at the last index), `fixtures` (contract sentence), `model`, `verdict`.

Felsworn: Bane of Fire 707901 at 1 stack on the dummy on Bane of Chaos 706420 `one_bane`; Felfury 800058 at 5 stacks on
the caster on Demonic Embrace 520257 `below_six`.
