# 0268. The effectiveness of a single-value buff

- Status: accepted
- Date: 2026-11-12
- Amends: ADR 0120 (when a state read counts as behaviour), for "effectiveness of" clauses

## Context

Martyr 300530 says "Increases the effectiveness of Gift of Zeal by $s2%" (claim 34). The counted pair
20261112-035932 / -040026 (build f8370be27d42) casts Gift of Zeal 300923 on the Templar. Agility reads 209 without
Martyr (the control) and 224 with it: 77 becomes int32(77 x 1.2) = 92, +19.5%, inside the band of the stated +20%. The
verdict `300530 behaviour_metric_delta gift` has a learned contrast. `coverage.promised_state` still counts it as data,
because the clause names no stat word. The amendment of 2026-11-12 to rule 4 reads a claim's subject together with the
recorded rulings. FableMentor recorded the reading (lean/owner-questions.md, "Information, decided by FableMentor"):

- When a tooltip increases "the effectiveness of X" and X's tooltip states exactly one value, the claim's subject is
  that value.
- The reading does not extend to a buff with two or more stated values (that case is status 5).
- It does not extend to duration, range or any other unstated property.

## Options

1. Rewrite the claim's words to name Agility. This changes what the ledger says the tooltip states.
2. A ledger field that names X. Coverage adds X's single stated value to the claim's words, for the state-promise
   match only.
3. Leave claim 34 at data.

## Decision

Option 2, under the reading's limit.
- **The field.** A claim entry may carry `"effectiveness_of": <spell id of X>`. Coverage refuses the field in three
  cases: on an entry that is not a claim or that declares `claims`; with a value that is not a spell id; and on a
  clause without the words "effectiveness of".
- **X's stated values.** These are counted across every ledger entry of spell X, whatever its `kind`, so two values in
  one entry and a value in a `no_claim` entry both count. A stated value is a `${...}` formula, a `$` token other than a
  duration (`d`), a radius (`a`) or a range (`r`), or a literal number. Tokens are compared case-blind with their spell
  and index, so `$s1` named in two entries is one value. A period (`$t`), a stack count (`$u`), charges (`$n`) or a
  chance (`$h`) count as stated values. The reading excludes only what the tooltip does not state as an effect amount,
  and keeping these tokens leaves the claim at data, which is the conservative side.
- **The match.** When X states exactly one value, the entries carrying it are appended to the claim's words, so the
  state promise (`promised_state`) can match its stat. With none, or with two or more, the words are unchanged, and a
  state read stays data.
- **Not checked.** The ledger has no spell names, so the id is not compared with the buff the clause names. The id is
  read in review, as the labels are.
- **Unchanged.** Nothing else changes. Labels, conformance and the learned-contrast requirement are the same.

## Consequences

- Claim 34 counts as behaviour: Gift of Zeal 300923 has one stated value ("increasing Agility by $s1") and one duration
  ("for $d").
- Seeded tests:
  - the single-value case counts, with a duration and a range beside the value;
  - the two-value case stays data in three shapes: split over two entries, in one entry, and with the second
    value in a `no_claim` entry;
  - one value named in two entries is one value; a period and a stack count beside
    the value make it a two-value buff;
  - a subject spell with no ledger entry stays data;
  - duration, radius and range tokens state no value;
  - malformed fields are refused.
- No class file or scenario changes, so no regeneration applies. The owner can overturn the reading. Removing the field
  returns claim 34 to data.
