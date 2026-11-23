# 0031. Overflowing Juju scales Malefic Arrow

- Status: accepted (contributor decision 2026-11-22); amends 0016
- Date: 2026-11-22

## Context

Overflowing Juju 707405: "Increases the spell power scaling of Malefic Wrath, Shadowflare, and Bad Juju by $s1%."
0016 left Malefic Arrow out because the tooltip does not name it. Malefic Arrow replaces Malefic Wrath (707854
"Transforms your Malefic Wrath into Malefic Arrow", and the Shadowhunter form), and its ranks share the Malefic Wrath
class bit 32768 that the talent's mask covers, so the game data applies the talent to it. The live combat logs cannot
show whether a character held the talent, so they settle nothing. The contributor chose to scale the Arrow.

## Decision

- `witch_doctor_scaling` multiplies the folded spell power coefficient for every spell the talent's mask covers,
  Malefic Arrow included.

## Consequences

- Regression: catalog `witch-doctor-overflowing-juju-scales-spell-power`, the Arrow arm now expects 1.16 to 1.22.
