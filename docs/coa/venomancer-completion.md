# Venomancer reconstruction policy — 2026-09-10

This pending source reconstruction addresses the 190 original Venomancer audit
findings, including corrections and retained native mechanisms.
It is not a statement of official Ascension server parity or gameplay acceptance.
No configure/build, installation, SQL application, restart or client launch is authorized by it.

## Evidence and precedence

Use the captured installed Spell.dbc records and active primary descriptions first, the archived
changelog as supporting evidence, and the existing native/script implementation where it already
works. The package pins 1,190 spell records and 1,462 changelog matches. Do not replace a working
native effect merely because the original audit found its unrelated obsolete proc field empty.
The retained Venom selection/payloads, native form power and Catalyst have separate original tests.
Venomancy Expert's real five-percent cost aura remains; there is no second scripted discount.

The conflicting Corrupt Mind/Cultist acquisition question is deferred and outside this package.
The pending Pyromancer SQL11, Cultist SQL12 and Sun Cleric SQL13 remain immutable. Venomancer adds
only `rev_20260910_14_venomancer_completion.sql` with matching source.

## Numerical interpretations

- Brood spenders use 1.25, 1.60, 2.05, 2.60 and 3.50 for one through five marks. Extra capacity
  does not extrapolate an unauthored sixth multiplier. Effectiveness multiplies the bonus above 1.
  Costs are reserved before effects; selected delayed hits retain that snapshot. Refund rolls once.
- Molt applies fifteen Exposed stacks independently of the ordinary maximum. Later ordinary procs
  preserve fifteen without increasing it. Reformed uses the actual cleared count while in Beetle.
- Withered increases Withering's spell-power coefficient relatively. The legacy escalating Venom
  provides the local growth model: base tick times completed tick count, capped at fifteen. Base
  and growth are saved separately; reapplication resets growth and loading preserves it.
- Deadly Kiss multiplies final critical damage by its authored percentage. This is an explicit
  interpretation of the ambiguous critical-damage wording, not an assertion about official internals.
- Serpent Lord uses the archived ten-yard threshold, strict greater-than. Its one-second cast time
  is selected before ordinary haste/cast modifiers and only for its native mask in Spider Form.
- Beetle's raw `q2=500` health conversion is five times Intellect plus Agility. Magic Shell gives
  fifteen-percent attributes in Beetle and hit rating equal to three percent of all five attributes.
- Fungic follows the active twenty-percent description, not the stale private ten-percent amount.
  Two stored remaining contributions share the current duration; a third replaces the oldest. Every
  integer remainder is paid by the final tick. Resolved copies do not receive another coefficient.
- Sepsis saves nominal future periodic damage, including future Withering growth; future critical
  events are not predicted. The release retains target mitigation and cannot receive caster scaling
  twice. Only the owner's Venomancer poison auras are removed. Dispel/death do not release the budget.
- Venoxis follows its active thirty-percent damage/attack-haste description. The Fungarian performs
  one authored Nature spell pulse at its attack interval, without an additional auto-attack hit. It
  turns to the owner's current enemy: the owner's attack victim, or a selected unit the owner fights.
- Unspecified summon survival/attack values are local: health 20% and armor 50% of owner; small-pet
  weapon damage uses the 0.05–0.075 AP interval. All authoritative spell coefficients remain separate.

## Ownership, finite effects and saved state

Spell generations prevent a completed/delayed old cast from consuming a refreshed replacement buff.
Venom Weaving has two Alkahests; Vigil has five owned effective HoT events; matured Chrysalis has
twelve direct-damage events. Loading preserves remaining charges. Effective healing excludes overheal.
Periodic extension and spread retain owner, active rank, duration, amounts and next tick.

Spore's parent now owns the ten-second timer and saved one-shot amount, so loading does not start
a new helper. Acidfang and Withering use non-recalculated saved effect amounts. The native family-35
load path restores all amounts before calculating periods, and reconstructs phase from elapsed time.
These are normal aura-save semantics, not a crash journal. GUID host links, transient proc cooldowns,
and temporary summons are not durable across a server crash; real relog still requires acceptance.

Green Salve's delayed heal selects the lowest-health other eligible group ally. Sage spreads only an
owned Balm. Mycelial/Worship/Vigil/Curse checks cannot use another caster's state. Runed Carapace keeps
separate school cooldowns. Native generic aura stacking supplies the reviewed raid-buff exclusivity.

Parasite validates an out-of-combat living player host, blocks attacks and ordinary spells, follows
the host and exits at the last valid same-map position. Exit clears host/root state and starts cooldown
once; enemy hosts receive poison. Burrow's exit requires a destination within thirty yards and LOS.
Lair blocks direct hostile targeting across its boundary; area targeting and friendly actions remain.
Skitter preserves the first ten-second window and starts forty-second cooldown on its third use or
window expiry. These geometry decisions require validation against actual maps and movement.

## Native assets and legacy identities

Five guarded definitions: Fungarian 45896/display 49116 (Elemental); Mushroom 506018/display 128263; Brood Trap
52121/display 23058; Spiderling 999298/display 955; Scarab 999299/display 10005. Their native display,
model and model-info dependencies resolve. The mushroom wears the live Venoshroom display 128263,
`spells\Druid_Wild_Mushroom_03Hostile.M2`, shipped in the client's patch-N.MPQ, at 0.55 scale.
No DBC or client archive edit is needed.

Primary Mycelial Ring follows its client tooltip: twelve mushrooms at random points within the 4 yd radius
of the Mushroom summon 680764, inside its 8 yd ten-second field. Mushrooms are not attackable. Active Coil is 707234;
obsolete summon identity 712357 routes to its mushroom behavior instead of reintroducing the unrelated
archived channel.

Cunning uses existing 800389 for damage/extra Sting stacks instead of missing 804549. Its raw visual
values are unsuitable: 25622 resolves to BloodElfFemale and 29216 is absent. Serpent Lord, Spider Lord,
Brood Lord and Cunning retain their base form appearance as a local cosmetic limitation. Their combat
helpers are implemented. A distinct augmented appearance needs reliable asset identification later.

## Installation and acceptance

SQL14 contains exact coefficient suppression, script bindings and HIT proc metadata, plus ten guarded
creature/model INSERTs. Read-only dependency review establishes that the five templates are absent and
their model-info rows exist. Isolated replay proves idempotence and preservation of conflicting rows;
installation must still reject any non-identical existing definition rather than silently using it.
Install matching source and SQL while preserving earlier class dependencies.
Do not rerun generators over preceding applied/pending SQL files.

Actual-source fixtures, native cost/proc matrices and MSVC `/Zs` have narrower scope than a linked
server. Startup script registration, combat, grouped healing, threat, movement, pet proc forwarding,
model appearance, normal relog and replacement UI require separate acceptance after an explicitly
requested matching build/install. Continue the user's ask-first rule for client test launches.
