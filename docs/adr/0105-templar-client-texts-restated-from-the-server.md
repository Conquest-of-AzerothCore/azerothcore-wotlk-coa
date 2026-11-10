# 0105. Templar client texts that state a losing option are restated from the server

- Status: accepted
- Date: 2026-11-10
- Supersedes: ADR 0104's choice "Leave them and list them for the owner" (Options, client texts) and the last
  sentence of its D7, for the five texts below

## Context

ADR 0104 D1 chose the text of the spell the player learns or casts. Five texts the client shows still bill the
losing option (server `Spell.dbc`, sha256 d3dd6072…):

- Force of Golganneth's buff (500694 ToolTip): `$AP*.4+$SP*.25} Physical damage`.
- Scourgebane's strike (801832 Description): `+$AP*0.15} Holy Damage over $d`.
- Righteous Tempest's tick spells (805410, 570200 to 570205 Description): `${$m1+0+$SP*.15}`.
- Chakra of Light's heal (803160 Description): `${$m1+0+$SP*0.14+$AP*0.08}`.
- Righteous Tempest ranks 1 to 7 (805409, 807269 to 807274 ToolTip): `plus $805410s1` (each rank its own tick id),
  the base without spell power.

The server already restates client texts: `coa_client_spell_description` rows are streamed to every player in
`SMSG_PATCH_SPELL` rows (`AscensionCompat.cpp`, `BuildSpellPatchRows`), as Untainted does
(`rev_20261029_240_templar_untainted_tooltip.sql`). A row's `Description` always replaces the client's; an empty
`ToolTip` keeps the client's. On 2026-11-10 the owner approved writing the five texts there
(`owner-rulings-2026-11-10.md`, "Client texts").

Chakra of Light's heal is one spell for both talent ranks (803159 and 803844 both trigger 803160), and the server
takes its base from the rank the player holds (`AscensionTemplarContracts.cpp`, `HasAura(803844) ? 803844 : 803159`).

## Options

For Chakra of Light's heal:

1. Name rank 1's base (`$803159m1`). Wrong for a rank 2 holder.
2. Drop the number ("the talent's healing amount"). Never wrong, but no longer states the ruling's base plus 35%.
3. A known-spell conditional, `$?s803844[${$803844m1+$SP*0.35}][${$803159m1+$SP*0.35}]`. Chosen: the client's own
   texts use this form with an expression in each branch (27 server `Spell.dbc` strings, for example
   `$?s552011[${$1153483m1/-1000}][${$m1/-1000}]`), and a held talent rank is a spell the character owns
   (`.agents/docs/systems/ascension-talents.md`). `$?a` was not used: the talent's passive aura is not sent to the
   client (`Aura::CanBeSentToClient`).

## Decision

`rev_20261110_02_templar_client_texts.sql` writes seventeen rows. Each changes only the ruling's terms and keeps the
client's other field and wording:

- 500694 ToolTip: `${$803153m1+$803153ppl1+$AP*0.25+$sph*.25} Holy damage`; Description as the client has it.
- 801832 Description: `+$sph*0.25+$AP*0.25} Holy Damage to up to $i nearby enemies.`; ToolTip kept.
- 805410, 570200 to 570205 Description: `Deals Weapon Damage plus ${$m1+0+$SP*0.3}.`
- 803160 Description: `for $?s803844[${$803844m1+$SP*0.35}][${$803159m1+$SP*0.35}].`
- 805409, 807269 to 807274 ToolTip: `plus ${$<tick>m1+$SP*0.3} to nearby enemies.`, the rank's own tick id;
  Description as the client has it.

## Consequences

- Regression: `templar-ruling-client-texts` asserts the streamed rows carry each new string and none of the old terms.
- That the genuine client renders these streamed strings, and evaluates `$?s803844` for a rank 2 holder, is not
  verified here; the owner's go asks for a lab client check next.
- A spell link is rendered with the viewer's own values: another player sees Chakra of Light's rank from their own
  spells, as for every `$?s` and `$SP` token.
- The conformance tool still reads the server `Spell.dbc` texts, not the streamed rows; the clause ledger's entries
  for these spells are unchanged.
