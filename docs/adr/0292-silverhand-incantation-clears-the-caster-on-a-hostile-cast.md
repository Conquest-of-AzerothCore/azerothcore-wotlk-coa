# 0292. Silverhand Incantation clears Sacred Restraint from the caster on a hostile cast

- Status: accepted
- Date: 2026-11-12
- Decision by: the owner, status-5 question Q4, option (a) (method-study/owner-rulings-2026-11-10.md, "Owner rulings
  on the Templar status-5 questions")

## Context

Silverhand Incantation 801465: "...charging you to them and removing Sacred Restraint from you and them if they are
an ally." ADR 0188 removed Sacred Restraint 102208 from the caster and the target only when the target is friendly,
and left the hostile case for the owner (Q4). The owner ruled that the restraint leaves the caster on every cast, and
leaves the target only when it is an ally.

## Options

1. Keep both removals behind the friendly check (ADR 0188). Rejected by the ruling.
2. In `templar_casts::OnSpellCast`, remove 102208 from the caster after any cast of 801465 at a unit target other than
   the caster, and from the target only when it is friendly. Chosen.

## Decision

Option 2. OnSpellCast still runs only for a cast that went through, so a refused cast removes nothing. An enemy keeps
its own 102208.

## Consequences

- Regression `templar-silverhand-incantation-sacred-restraint`: the hostile step now asserts the caster's 102208 is
  gone and the dummy's is kept. The refused cast and the ally cast are unchanged and stay its control arms.
- Conformance entry 801465 `dispel_removal` `sacred_restraint`: the hostile arm sets `caster_removed` (ADR 0291).
- Gameplay change: charging to an enemy also reopens the Templar's own Testaments.
