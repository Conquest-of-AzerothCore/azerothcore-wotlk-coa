# 0013. Expand `@s:` spell markup in conformance tooltips

- Status: accepted
- Date: 2026-11-06

## Context

ADR 0011 leaves every part of a tooltip the reader cannot evaluate in `unreadable`, `@...@` markup included. CoA
tooltips append the tooltip of another spell with `@s:<id>:<flags>@`: Zealotry 92108 reads "Your off-hand auto
attacks now trigger Zealotry.@s:801450:0@", and the number the player sees, "Deals 80% off-hand Weapon Damage as
Holy Damage", is the `$s2` of 801450. Over every rank of the 172 Templar class spells there are 30 such entries in
28 ranks of 22 spells, naming 13 spells, all with flags 0. Left unreadable, the numbers they show are never checked.

The stock 3.3.5a client does not know this markup: it comes from Ascension's `Extensions.dll`. The evidence is the
function-by-function reconstruction of that DLL, github.com/firstoni-dev/ascension-extensions-reconstruction (MIT,
commit a5946de798d70287195abebdca6c5ca915105298, read 2026-11-06). It is a community reconstruction: evidence, not
authority; the live client stays the reference where they disagree.

`src/Ascension/AscSpellText.cpp:549-558`, inside `Markup`:

```cpp
else if (ScanTag(t, pos, s, e, "@s:", "@", "@s:%u:%d@", 2, &id, &flags))
{
    const uint32_t f = flags < 0 ? static_cast<uint32_t>(-flags) : 0;
    if ((((f >> 2) & 1) && !shift) || (((f >> 3) & 1) && shift))
    {
        t.erase(s, e - s);
        hint = true;
    }
    else
        put(Render("SPELL", id, f & 1, (f >> 1) & 1, cached, true, (f >> 4) & 1, (f >> 5) & 1,
                   (f >> 6) & 1, (f >> 7) & 1));
}
```

`Render` (`AscSpellText.cpp:270-306`) draws, for `nameOnly` and `descOnly` false and no range, cooldown, cast or
power line, a divider, then the head `IconTag(...) + " |cffFFFFFF" + <spell name> + "|r"`, then
`"\n" + AscSpellText::Description(id, false, cached, 0)`. `Description` (`AscSpellText.cpp:652-686`) formats the
referenced spell's own record (`FormatSpell(rec, ...)`, the record fetched for `spellId`) and runs `Markup` on the
result, so nested markup expands too. `Markup` (`AscSpellText.cpp:413-417, 643-648`) counts its recursion in
`g_depth` and replaces the text by "Maximum recursion depth exceeded" from the 11th nested call. Flags 0 or more give
`f = 0`: the full rendering. Negative flags select bits: bit 2 shows the text only while shift is up, bit 3 only
while it is down, bits 0 and 1 the name only or the description only, bits 4 to 7 range, cooldown, cast and power
lines.

## Considered options

1. Keep `@s:` unreadable. Rejected: 34 tokens players see stay unchecked.
2. Expand the referenced tooltip as text, then read the result as part of the described spell. Rejected: its `$sN`
   would read the described spell's effects, which is not what the client evaluates.
3. Read the referenced spell's tooltip with a nested reader of that spell and append its values. Chosen.

## Decision

- `@s:<id>:<flags>@` with flags 0 or more expands to the tooltip of spell `<id>`, read by a nested `Tooltip` of that
  spell with the same caster stats (design D13). The header line (icon and name) is text only.
- Expanded tokens join the readout at the markup's place with their own text, `effect_index` `None` (they are not
  effects of the described spell) and `spell_id` the spell they read: the referenced spell for its own tokens and
  for `$d $h $u $i $aN` without an id, the named spell for a token with an id. Their unreadable parts join
  `unreadable`.
- The value checks route an expanded token as a token of another spell (ADR 0011, phase-2 foreign tokens): a token
  without an id belongs to the spell of its `spell_id`. Zealotry's `$s2` is `effect_value` of 801450 effect 1;
  Downfall's `$d` inside Glory 801481 is `spell_duration` of 801482. An unsigned expanded token takes the sign of the
  referenced spell's points.
- Negative flags stay unreadable (`negative flags select a shift or partial rendering`): their output depends on the
  shift key or renders a part we do not model. None of the 30 Templar entries uses them.
- A cycle (a spell already being expanded) and nesting deeper than `MAX_EXPANSION_DEPTH` = 3 expansions are
  unreadable with that reason. The reconstruction's own limit is 10 nested `Markup` calls; 3 is our bound (design
  D13), and no Templar entry nests at all. A missing referenced spell is unreadable
  (`spell <id> is not in Spell.dbc`); the reconstruction renders an error text there.

## Consequences

- Templar, measured over every rank of the 172 class spells: the 30 entries become 34 readable tokens in 16 spells
  (26 effect values, among them 13 Zealotry `$s2`, 7 durations and 1 stack count of the referenced spells) and 2
  unreadable parts, both level-scaled (`EffectRealPointsPerLevel` of 500689 and 807035). The 6 entries naming
  Sacred Restraint 102208 and Oathkeeper 803237 expand to text without a number: Sacred Oath 712346 becomes
  `tooltip without value`.
- An expanded token may share its text with a token of the described spell (Glory 801481 shows `$s1` and `$d` for
  itself, for Downfall and for Redemption; Tome of Light 805422 shows `$d` three times). Consumers that pick a token
  by its text take the first one, which is the described spell's own token in both Templar cases: the markup comes
  after the own tokens.
- Not verified: that the live client renders exactly the reconstruction's text for flags 0. A disagreement found
  in game supersedes this record.
