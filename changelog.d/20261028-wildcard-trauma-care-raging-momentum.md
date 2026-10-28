# Wildcard Raging Momentum and Trauma Care

- Raging Momentum285362: its unresolved randomizer previously prevented cooldown reduction. A normal card proc script
  now reduces one other tooltip-listed ability's cooldown by3seconds after an eligible completed cast. Unknown or
  inactive abilities remain eligible without rerolling; the used ability is excluded.
- Trauma Care274205: finishing moves now use captured combo points for the authored20%per-point chance to grant
  native274211. Its instant, increased, two-target Greater Heal and native two-charge behavior are preserved.

Native effects184/196 were not redefined. Fire Arsenal and Roll the Bones remain blocked by missing pool/child contracts.
Migration rev_20261028_02_wildcard_trauma_raging.sql is pending. Formatting/static checks passed; runtime unverified.
