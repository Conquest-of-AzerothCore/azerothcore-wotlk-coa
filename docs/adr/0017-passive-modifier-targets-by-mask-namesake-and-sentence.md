# 0017. Passive modifier targets: in-mask namesakes, sibling effects and the token's sentence

- Status: accepted
- Date: 2026-11-06
- Supersedes, for the cases below: the target reading of ADR 0012 D5

## Context

ADR 0012 D5 measures a spell modifier on the spells its tooltip names, resolved by name to their rank at the class
level, plus the class mask's spells that are not named. The full Templar run of 2026-11-06 (stamp 20261106-153135)
gave 71 alerts of the form "named outside the class mask and no mask spell shows the expected delta". Read one by
one, none was a server defect:

- A spell name belongs to several spells. Scourgebane is 92111 (the passive), 520007, 801832, 801861 and 804916;
  only the one whose `SpellFamilyFlags` meet the effect's mask can be modified, and a spell with flags [0, 0, 0]
  cannot be matched by any mask (`SpellInfo::IsAffected`). D5 took every namesake.
- The mask covers a helper of the same name that D5 never measured: Righteous Tempest 807274 is the aura, its damage
  spells 570200 to 570205 and 805410 are in the mask of Argent Knight and Focused; `class_level_ranks` kept only the
  chain top 807274, and the unnamed mask spells were selected by name, so the helpers were neither targets nor
  mask spells. Holy Upheaval (807764) and Improved Benediction (801409) are the same case.
- One tooltip names the targets of several effects ("Reduces the Energy cost of Righteous Lunge by $s1 and Sacred
  Swing by $s2"): D5 gave each effect every name, so effect 1 alerted on Righteous Lunge, the target of effect 0.
- Names in another sentence of the tooltip: Legacy of the Silver Hand's `$s2` sentence names Scourgebane only, while
  its first sentence names Argent Blade and Scarlet Hammer as the casts that trigger effect 0.
- `mask_matches` skipped named mask spells, so a named target outside the mask stayed an alert even when a named
  mask spell of the same effect showed the expected delta, contrary to D5.

## Considered options

1. Keep D5 and list these alerts as tool limits. Rejected: an alert must mean a game difference for the owner.
2. Drop every named spell outside the mask. Rejected: a named spell outside the mask that still changes (the server
   moves Legacy of the Silver Hand's mask to Scourgebane 801832) or does not change (Patience on Interdict) is a
   finding.
3. Resolve names against the effect's mask first, give a name to the effect whose mask holds it, read names in the
   sentence of the effect's token, and count named mask spells as matches. Chosen.

## Decision

- D1. A named spell whose ids meet this effect's mask has those ids as targets (in mask, resolved to the ranks the
  class level reaches; ids outside a progression chain are all kept); its ids outside the mask are dropped. A named
  spell with no id in the mask keeps D5: its rank at the class level, outside the mask.
- D2. A named spell with no id in this effect's mask but an id in the mask of a sibling spell-modifier effect of
  the same passive belongs to that sibling and is no target of this effect.
- D3. Names are read in the sentence that holds the effect's token when the token sits in exactly one sentence and
  that sentence names a spell; otherwise in the whole tooltip.
- D4. Mask spells that are not targets are selected by id: every mask spell whose name was not matched.
- D5. A named target outside the mask whose delta does not match is `ambiguous_tooltip` when another target of the
  same effect and metric in the mask, named or not, shows the expected non-zero delta (the D5 rule of ADR 0012, now
  with named mask spells counted); it is `measured`, not judged, when a named spell of the same name shows it (a
  namesake the modifier does not reach); otherwise it stays `alert`.
- D6. A measured delta of 0 against a non-zero expected delta is never `ok` (the deterministic floor of 1 point
  accepted it before); a matching spell must show a non-zero expected delta.
- D7. Spells the tooltip names only as a condition or a consumer ("on enemies affected by your Condemn", "Casting
  Argent Blade ... guarantees") are not detected as such: no rule tells a condition from a target reliably. Those
  outside the mask stay `ambiguous_tooltip` (Templar's Might names the spells Condemn's debuff boosts) and go to
  the player question list; D3 removes the ones in another sentence.
- D8. A mask spell the tooltip does not name is `measured` beside named targets of the same effect and metric
  (ADR 0012 D5). When every such named target is `unmodelled` for that metric (a named spell without the consumer's
  effect: `target <id> has no effect <n>`), the mask spell is `unmodelled` too, its reason naming them: judging it
  as a category target would accept an `ok` on a spell the tooltip does not name. Category judging applies only
  when the tooltip names no target at all.

## Consequences

- The 2026-11-06 Templar run keeps no tool-made modifier-target alert: 69 of the 71 such alerts become `ok` on the
  helper spells, `ambiguous_tooltip` on consumers, `measured` on namesakes, or leave the target list.
- Helper spells that D1 makes targets are judged: Righteous Tempest 570200 to 570205 and 805410 (+30% from Argent
  Knight, +25% from Focused), Righteous Upheaval 807764 (+100%), Benediction 801409 (+15000 ms) read `ok`. Each was
  checked against its mask and the tooltip number.
- A target dropped by D2 or D3 is no longer judged on that effect; an error there loses a check, never makes an `ok`.
- ADR 0012 stays as written; its D5 holds where none of D1 to D7 applies.
