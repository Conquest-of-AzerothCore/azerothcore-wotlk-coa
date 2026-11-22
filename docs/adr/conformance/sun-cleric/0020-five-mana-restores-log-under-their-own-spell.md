# 0020. Five Sun Cleric mana restores log under their own spell, not Vow of Grace

- Status: accepted
- Date: 2026-11-22

## Context

`Mana()` (`AscensionSunCleric.cpp`) energizes through `Unit::EnergizeBySpell` with a default source of 504877
"Vow of Grace" (`AscensionSunCleric.h`). The default was set for every caller by the initial commit e36bc50aad, which
gives no reason for it. 504877 has AttributesEx 0. A restore sent under it therefore:
- names Vow of Grace in the SPELL_ENERGIZE combat log;
- forwards 0.5 threat per point of mana (`ThreatManager::ForwardThreatForAssistingMe`). The call returns early only
  for a spell with `SPELL_ATTR1_NO_THREAT`, or for a player who `GainsManaWithoutThreat`.

The D-100 sweep looked at every default-source call and the live combat logs (coa-history, SPELL_ENERGIZE from
players). Five callers restore mana that live logs credit to another id. The table gives the events, logs, players
and first and last day under that id:

The counts come from this query, run on 2026-11-22 against the combat log index (`coa-history sql`):

```sql
SELECT e.spell_id, COUNT(DISTINCT e.log_id), COUNT(DISTINCT e.source), SUM(e.events), MIN(l.day), MAX(l.day)
FROM spell_events e JOIN logs l ON l.id = e.log_id
WHERE e.spell_id IN (300345, 302896, 504679, 704926, 805360)
  AND e.event = 'SPELL_ENERGIZE' AND e.source_kind = 'player'
GROUP BY e.spell_id;
```

An earlier lookup for Sanctified read 13,775 events in 20 logs. Its query was not recorded, so the table keeps the
figures of the query above.


Sites are in `AscensionSunCleric<File>.cpp`. NT means the live id carries `SPELL_ATTR1_NO_THREAT`.

| Site | Spell and trigger | Live id | Events / logs / players, dates | NT |
|---|---|---|---|---|
| Abilities:233 | Devoted to the Light 681436, a Solar Invocation | 504679 | 511 / 12 / 13, 05-17..08-29 | yes |
| Abilities:369 | Sanctified 300344, healing a Blessed target | 300345 | 14089 / 25 / 4, 05-22..08-31 | yes |
| Auras:224 | Bless 804247, the caster's own tick | 805360 | 2930 / 12 / 4, 08-17..08-31 | yes |
| Events:255 | City of Light 301239, a Radiant Flame tick | 302896 | 1489 / 6 / 5, 05-25..08-09 | yes |
| Events:294 | Bastion of Hope 704928, a critical strike | 704926 | 1863 / 5 / 2, 08-02..08-22 | no |

All dates are in 2026.

The same logs hold 2365 events of 504877 in 14 logs from 9 players (2026-07-12..2026-08-23), which is Vow of Grace's
own restore. Each live id above is the spell the DBC links to its effect. 681436 is passive, as are 300344, 301239
and 704928. 300344 triggers 300345, and 805360 is Bless's own periodic spell. 301239 triggers 302896, and 704928
triggers 704926. 704926's own ENERGIZE effect is turned into a dummy at load (`AscensionSunClericContracts.cpp`), so
its scripted `Mana()` is the only restore.

## Options

- Keep 504877. The amounts stay correct, but five restores name the wrong spell. Four of them also add threat that
  their live spell does not add.
- Pass each site's live id as the source in that one call. `Mana()`'s default stays, so the remaining callers keep
  504877.

## Decision

The second option (mentor decisions D-99, Sanctified, and D-100, the group, 2026-11-22). Each amount is computed
exactly as before, and only the source argument changes.

Out of scope, recorded as observations:
- `AscensionSunClericAbilities.cpp:342`: Gavel of Grace 800614 takes its value from 504722 "Energize 10% Mana", which
  has only 1 live event (1 log, 2026-08-23). 504722 also carries Conquest's refund value.
- `AscensionSunClericEvents.cpp:286`: Blessed Bulwark 680663 takes its value from 504876. The live logs hold no
  events for 504876 or 680663.

Vow of Grace's own restore (`AscensionSunClericEvents.cpp:217`) keeps 504877.

## Consequences

- The five restores appear in the combat log under 504679, 300345, 805360, 302896 and 704926, as they do on live.
- Four of them add no threat any more, because 504679, 300345, 805360 and 302896 carry `SPELL_ATTR1_NO_THREAT`. This
  comes from reading `Unit::EnergizeBySpell` and `ThreatManager`: no existing kind measures threat for these
  triggers. 704926 is not NO_THREAT, so Bastion of Hope's threat is unchanged.
- Readers of the five ids: only the class's own code and class file read them. One Witch Hunter class-file text quotes
  the token `$504679s1`, which is DBC data and is unchanged. No other code or SQL reads these ids as a source, and no
  engine file changes.
- Regressions are entries of `classes/sun_cleric.json`. Each one has a before phase without the passive as its
  control:
  - Devoted to the Light: the four `energize_*` entries read 504679, and `energize_conquest_not_vow` reads no 504877.
  - Sanctified: `refund_bless` and `refund_no_bless` read 300345, and `refund_bless_not_vow` reads no 504877.
  - Bless: `mana_tick_source` reads 143 under 805360, which is 5% of 2868, and `mana_tick_not_vow` reads no 504877.
  - City of Light: `mana_missing` reads 55 under 302896, which is 3% of 2868 - 1023. `mana_missing_control` is the
    control without City of Light, and `mana_missing_not_vow` reads no 504877.
  - Bastion of Hope: `mana_flat`, `mana_sp` and `no_crit_mana` read 704926, and `mana_flat_not_vow` reads no 504877.
- The Bless scenarios `sun-cleric-bless-mana-five-percent.json` and `sun-cleric-bless-periodic-mana-4554.json` read
  805360 in place of 504877.
