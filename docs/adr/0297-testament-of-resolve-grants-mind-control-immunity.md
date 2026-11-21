# 0297. Testament of Resolve grants charm and mind-control immunity in Templar code

- Status: accepted
- Date: 2026-11-12

## Context

Testament of Resolve 804228 reads "Bless an ally with heightened resolve, granting immunity to fear, charm, and
horrify effects". Its Spell.dbc record grants fear (Effect[0] aura 147 `SPELL_AURA_MECHANIC_IMMUNITY_MASK`, mask 512,
which `SpellInfo` turns into `SPELL_AURA_MOD_FEAR` state immunity) and horror (Effect[2] aura 77, `MECHANIC_HORROR`).
Effect[1] applies Sacred Restraint 102208. Nothing names charm, and the conformance entry measured Domination 37122
(Mechanic 1, aura 6 `SPELL_AURA_MOD_CHARM`) landing with Testament up. The owner ruled on 2026-11-12
(`method-study/owner-rulings-2026-11-10.md`, status-5 section, Q2): option (a), charm immunity in Templar code, and
"charm" means mind control. The reference snapshots (sidekick `data.js`, coabuildhub `skills_templar.json`) repeat the
tooltip and say nothing more.

## Options

- A contract on 804228's effects. There is no free effect slot. The aura 147 mask maps no bit to charm, and rewriting
  aura 147 or 77 would cost fear or horror.
- An aura script that adds the immunities through the stock `Unit::ApplySpellImmune`, as the Guardian's Advance does
  (`AscensionGuardianAbilities.cpp`). Chosen.

## Decision

`aura_ascension_templar_lifecycle` is bound to 804228 (`rev_20261112_22_templar_testament_of_resolve_script.sql`). On
the aura's first effect it applies, and on removal it clears, three immunities on the aura's target under 804228's
id:
- `IMMUNITY_MECHANIC` `MECHANIC_CHARM`, for a spell whose own Mechanic is charm (Domination 37122, Mind Control 605);
- `IMMUNITY_STATE` `SPELL_AURA_MOD_CHARM`, for a charm aura without that mechanic;
- `IMMUNITY_STATE` `SPELL_AURA_MOD_POSSESS`, for mind control.

`SPELL_AURA_AOE_CHARM` and `SPELL_AURA_MOD_POSSESS_PET` are controls on the caster's side, not auras put on the
victim, and are not covered. Removal erases every entry of the spell id, so a refresh leaves no extra entry. A charm
already active at the cast is not broken; the ruling does not ask for that.

## Consequences

- Catalog `templar-testament-of-resolve-charm-immunity.json` reads native immunity from the dummy: 37122 and 605 at
  0 before the cast, 1 while 804228 is up and 0 after it expires. Fear 12096 and Psychic Horror 64044's effect 0 follow
  the same pattern from the DBC effects, as the control. 64044's effect 1 trigger has no immunity, so the whole spell
  never reads immune.
- Conformance `charm_immunity` entries for 37122 and for a new Mind Control 605 entry: the charm lands without
  804228 (the control) and is refused with it.
