# 0054. An item-armor-subclass override models mail-armor-contribution passives

- Status: accepted
- Date: 2026-11-10

## Context

`passives.py` closes every aura-142 (`SPELL_AURA_MOD_BASE_RESISTANCE_PCT`) effect with `OUT_OF_SCOPE[142]`
(`'closed: mail armor is out of scope'`). Round 5's `closed-statuses-spec.md` found this correct at the time
for Blessed Padding 301311/301360 ("Increases your Armor contribution from mail items by $s1%..."): the
reference character never equips a mail item, and the generic `armor`/`passive_delta` check would measure a
total-Armor delta the effect does not produce (`Player::UpdateArmor()`, `StatSystem.cpp`, scales only the
`Player::GetItemArmorBySubclass` contribution of the matching item-armor subclass, not total Armor), and closed
it as a harness-capability gap rather than a server defect, out of that item's scope to fix.

Rechecking `SpellInfo::GetItemArmorSubclassMask()` (`SpellInfo.cpp`) this round found a second, real server
defect stacked on top of the harness gap: the function special-cases `SPELL_AURA_MOD_BASE_RESISTANCE_PCT` by a
per-class `SpellFamilyName`/spell-id whitelist, and only ever checked `SpellFamilyName == 24` for Templar, not
25 — the family both Blessed Padding ranks actually carry (`coa-dbc-viewer record`, confirmed this session).
Both ranks' `EffectMiscValueB[0]` is 8 (`1 << ITEM_SUBCLASS_ARMOR_MAIL`, `ItemTemplate.h`), the same shape as
the family-24 shield/mail entries the function already whitelists, but falling through the family check meant
`GetItemArmorSubclassMask()` always returned 0 for these two spells: `Player::UpdateArmor()`'s
`GetTotalAuraMultiplier` lookup then never matches, and the whole +50%/+100% mail-armor bonus is a dead letter
regardless of what the character wears. This is a confirmed server defect ("a new check that shows the server
breaks the tooltip is a server defect: fix the server"), not the tooltip-reading ambiguity the round5 item was
scoped around.

## Considered options

1. Fix only the `SpellInfo.cpp` defect and leave the clause `closed` in the conformance tool, relying on the
   pre-existing standalone scenario `apps/coa-gameplay-test/scenarios/templar-blessed-padding.json` (written,
   never run through this pipeline) for proof. Rejected: that scenario's crude `min`-bound `assert` produces no
   `compare.py` `Verdict`, so it cannot feed the clause ledger's `labels` (which match `Verdict.label` strings),
   and it only covers rank 2.
2. Build a generic armor-by-item-subclass metric and class-file override, fix `SpellInfo.cpp` alongside it, and
   let the existing `passive_delta`/`share` judging prove both ranks through the normal generated-scenario
   pipeline. Chosen: reuses `compare.py`'s existing `share` relation (`delta_readings`: `source * token% `)
   unchanged, needs one new, class-agnostic CoAGameplayTest metric, and produces real `Verdict` rows the clause
   ledger can reference by label.

## Decision

- `CoAGameplayTest.cpp` gains an `item_armor_by_subclass` metric (`subclass` field): returns
  `Player::GetItemArmorBySubclass(subclass)`, the raw per-subclass item Armor the engine already tracks
  independently of any aura, on equip/unequip (`Player.cpp:7372`). `run.py`'s `METRICS`/`METRIC_FIELDS` gain the
  matching entries.
- `SpellInfo::GetItemArmorSubclassMask()` (`SpellInfo.cpp`) gains a `SpellFamilyName == 25` branch for
  301311/301360, returning mask 8 under the same `EffectIndex`/aura/`MiscValue` conditions its sibling
  family-24 branches already use — a Templar-owned fix to a function already organised per class/spell,
  touching no other class's entries.
- A class file's `item_armor_subclass_effects` list (`[{"spell", "effect", "subclass", "item", "slot",
  "citation"}]`) names which aura-142 effect is proven this way. `passives.py`'s `classify()` consults it before
  falling back to `OUT_OF_SCOPE[142]`; a match builds two `MetricPlan`s for the effect: a non-judged
  `item_armor_by_subclass` reference probe and a judged `armor`/`share` plan sourced from that probe's own
  `before` label. `passive_scenario()` equips the declared `item` at `slot` (`add_item` then `equip`) in
  priming, before the `before` measurement, for any rank with a matching entry.
- `classes/templar.json` declares both Blessed Padding ranks against item 1065932 (mail chest) at slot 4,
  the same item the pre-existing standalone scenario already named for this clause. Its `RequiredLevel` is 80
  (verified this round with a `carried_item_required_level` probe scenario; `item_template` is SQL data, outside
  `coa-dbc-viewer`'s DBC scope), above this class file's reference level 60, so each entry carries an optional
  `level` that `passive_scenario()` applies only to that one generated scenario's player, leaving every other
  Templar passive scenario at the class file's own reference level.
- No change to `compare.py`'s `share`-relation judging, `OUT_OF_SCOPE`, or any other aura-142 spell's
  (family 24's shield/mail entries) behaviour: a spell with no `item_armor_subclass_effects` entry still closes
  exactly as before.

## Consequences

- Blessed Padding 301311's and 301360's "Increases your Armor contribution from mail items by $sN%" clauses are
  now provable end to end (DBC → generated scenario → `compare.py` `Verdict` → clause ledger), closing a gap
  round 5 had correctly identified but left for later work.
- The mechanism generalises to any future aura-142 Templar effect (or another class's, through its own class
  file) that names an item-armor subclass, without further tool changes — only a new class-file entry.
- `SpellInfo::GetItemArmorSubclassMask()`'s fix is a live gameplay behaviour change: Blessed Padding's mail-armor
  bonus now actually applies, where it previously did nothing.
