# 0104. Templar owner rulings of 2026-11-10: which text governs, and aligning every owned place to it

- Status: accepted
- Date: 2026-11-10
- Supersedes: the last Decision item of ADR 0075 (Patience's `ModifySpellCooldown` literal flipped to `-5000`,
  "lengthening Interdict's cooldown by Patience instead of shortening it" called the defect)
- Qualifies: ADR 0011's sign rule (Expected values), for a token whose effect a class contract rewrites at load
- Superseded in part by: ADR 0105 (the five client texts are restated from the server)

## Context

The Templar conformance rounds left cases where two places in the game state different things for one mechanic.
The owner answered them on two decision pages on 2026-11-10:

- Righteous Tempest's spellbook text bills `$SP*0.3` per tick; the Description of its tick spells (805410, 570200 to
  570205) bills `$SP*.15`. Scourgebane's passive (92111, 520007) and Argent Blade (807268) bill `$AP*.25`; the
  Description of the strike 801832 bills `$AP*0.15` "over $d". Chakra of Light's talent (803159, 803844) bills
  `${$m1+$SP*0.35}`; the heal 803160 bills `${$m1+0+$SP*0.14+$AP*0.08}`. Force of Golganneth's spellbook text (500694
  Description) bills `$AP*0.25` Holy damage; its buff tooltip (500694 ToolTip) bills `$AP*.4` Physical damage.
- Patience 712678 reads "Increases the duration of Interdict by $/1000;s1 sec and its cooldown by $/1000;s2 sec.";
  its `Spell.dbc` effect 1 is -5001 (a 5 sec reduction). ADR 0075 had made the script shorten the cooldown.
- High General 524617 reads "to deal $s1% increased direct damage" with `$s1` = 100; the script multiplied by 1.5.
- Aggramar's Rage 560650/561346 reads "Holy critical strike chance"; the server had rewritten its crit effect into a
  class-mask spell modifier that reached Chastise, Scarlet Hammer and the Physical Blade of Faith only.
- Divine Charge's trample searched 5 yd; Divine Trample 527269's own radius is 3 yd (`SpellRadius` 15).
- Six readings of page 1 (Crusader's Brand "fleeing,", Devotion of Khaz'goroth and Crusader's Presence "Does not stack
  with similar effects.", Faith Guard "High Threat", Improved Benediction "based on your Agility and Stamina", Sacred
  Swing "Only usable after avoiding an attack.") needed a stated reading before a test could judge them.

## Options

For the coefficient source of a damage or heal that two texts describe:

1. The Description of the spell that deals the damage or heal. Rejected: the player never learns that spell and sees
   its text only through a spell link; Ascension's logs contradict the strike's "over $d" (17 486 direct
   `SPELL_DAMAGE` events of 801832, no periodic one) and Force of Golganneth's buff tooltip "Physical" (3 610 events
   of 803153, all Holy).
2. The text of the spell the player learns or casts (spellbook, talent window). Chosen.

For texts only the player's client shows that state the losing option:

1. Leave them and list them for the owner. Chosen by the owner.
2. Restate them from the server through `coa_client_spell_description`, which the server streams in `SMSG_PATCH_SPELL`
   rows (`AscensionCompat.cpp`, as done for Untainted in `rev_20261029_240_templar_untainted_tooltip.sql`). Not done:
   a player-visible text change the owner has not asked for.

## Decision

- D1. A coefficient follows the text of the spell the player learns or casts. Righteous Tempest: `$SP*0.3`.
  Scourgebane: 25% attack power plus 25% Holy spell power. Chakra of Light: the talent rank's base plus 35% healing
  power. Force of Golganneth: 25% attack power plus 25% Holy spell power, Holy school. The current
  `AscensionTemplarData.h` rows already apply these; no value changes.
- D2. A tooltip's verb governs a signed modifier when the owner rules so: Patience lengthens Interdict's cooldown by
  5 sec. `AscensionTemplarContracts.cpp` rewrites effect 1's points to 4999 and the cast hook adds that amount. The
  class file's `effect_overrides` entry carries `base_points: 4999`, so the unsigned `$s2` expects +5000 (the
  exception documented in `conformance/docs/generate-and-compare.md`, Sign rule).
- D3. A tooltip percentage on direct damage is that exact increase: High General adds 100%.
- D4. A tooltip's mechanism words are read literally: Aggramar's Rage is a Holy-school spell crit chance aura, so every
  Holy ability gains it and Physical abilities do not.
- D5. A radius the tooltip leaves as "nearby" is the DBC radius of the spell that deals the damage: Divine Charge
  tramples within Divine Trample's 3 yd, combat reaches added.
- D6. The page 1 readings keep the current server behaviour: "fleeing," is a creature's low-health flee for
  assistance; Devotion of Khaz'goroth's non-stacking is the strongest of the same-type party haste auras of spell
  group 2000182; Crusader's Presence's is the engine's strongest mounted-speed bonus; "High Threat" on Faith is threat
  x2 on damage with the flat +100 kept; Improved Benediction's armor is Agility + Stamina; Sacred Swing opens after a
  dodge or parry only.
- D7. Alignment: when places disagree, every place the project owns states the ruling: server DBC fields as rewritten
  by the load contracts, SQL, CoA code, the conformance class file and its expected values, regression scenarios and
  docs. Texts only the client shows stay unchanged and are listed for the owner.

## Consequences

- `docs/coa/templar-completion.md` lists the rulings. Regressions: `templar-patience-lengthens-interdict-cooldown`,
  `templar-high-general-chastise-damage`, `templar-aggramars-rage`, `templar-aggramars-rage-holy-crit-rolls`,
  `templar-divine-charge-trample-dbc-radius`.
- The D6 readings still need their contrast tests (fleeing creature marked against unmarked, max-not-sum haste and
  mounted speed, threat slope x2, armor rising with Agility and with Stamina, Sacred Swing after hit, miss and block);
  until then those clauses stay unproven. The Templar clause ledger holds Improved Benediction's armor clause with no
  label, and marks the tick spell 805410's `$SP*.15` clause `no_claim` under D1
  (`apps/coa-gameplay-test/conformance/docs/clause-ledger.md`).
- Player-visible texts that contradict a ruling remain: the tick spells' `$SP*.15`, the strike's `$AP*0.15` "over $d",
  the heal's `$SP*0.14+$AP*0.08`, Force of Golganneth's buff tooltip (Physical, `$AP*.4`) and Righteous Tempest's buff
  tooltip, which bills `$570205s1` without spell power. Changing them is a separate owner decision (option 2 above).
- ADR 0075 is not edited; only its Patience item is superseded.
