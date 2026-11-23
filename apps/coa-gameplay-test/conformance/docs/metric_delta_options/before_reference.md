# Before reference (`metric_delta` `before_reference`, ADR 1172, provisional)

`before_reference` is `{"metric": name, "fields": {...}}`, on an `owned_creature_*` read of a named `fields.entry`
whose before phase owns no such creature (its read would fail). The before read is replaced by the named metric of
the same unit (labelled as the before reading), preceded by `<spell> before_reference count`, the owned count of the
entry, which must read 0; the assert `<spell> before_reference present` (exactly one owned creature) precedes the
after read. The verdict is the plain judge of the reference against the after read, `alert` when the count is not 0
and `unmeasured` when it is missing. No expiry read. Absent, the scenario is unchanged.

Use it for a claim about where a summon stands: the reference is the reading a summon in the failing place would
give (the caster's own distance to the dummy for a ward that should stand beneath the target).

Named points: `check`, `fixtures`, `model`, `verdict`.

Witch Doctor: Hexfire Adept 704500 `ward_beneath` (the Serpent Ward 50587 0 yd from the dummy, against the caster's
20 yd).
