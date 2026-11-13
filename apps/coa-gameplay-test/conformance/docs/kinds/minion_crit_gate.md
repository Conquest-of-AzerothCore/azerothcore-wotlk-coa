# Minion crit gate (`behaviour_metric_delta`, `kind: "minion_crit_gate"`, Necromancer ADR 0045)

An internal cooldown on a minion-crit cooldown cut ("Can only occur once per sec."). `spell` is learned and two
minions of distinct entries are raised (`raises`: `[spell, creature entry, settle_ms]`); they attack the dummy with
the caster, and `crit_aura` (`[spell, amount]`, harness `set_aura` by owned entry, refreshed each window) makes each
landed swing crit. In each of `windows` windows `observe_spell` is cast (`observe_power` set first), and its
`cooldown_ms`, the game time and each minion's `pet_melee_crits` are read before and after `window_ms`. The cooldown
removed beyond the elapsed time, in units of `cut_ms`, counts the accepted crits. Two minions swinging together cut
on about half their crits (0.5); the judge accepts 0.4 to 0.75. An ungated cut reads 1.0, a gate of 3 s or more 0.33
or less. Fewer than 6 crits, or a cooldown that runs out inside a window, is unmeasured.

Necromancer: Dominion of Frost 537208, Unholy Frenzy 805029 cut by 3000 ms, Ghoul 50073 and Lesser Skeletal Warrior
50065 (claim 105.0).
