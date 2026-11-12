# Class conformance: owner rulings and method decisions

This page records the decisions that govern class conformance work.
- Part 1 holds the rules that bind every class.
- Part 2 keeps the Templar-specific rulings as examples and precedent. A later class may cite them, but they decide
  nothing outside the Templar unless their own wording says so.

**Who decided.** Each entry names its author:
- **Owner**: the project owner's own decision;
- **Owner, through the mentor**: the owner's answer, relayed by the mentor;
- **Mentor**: a method or derivation decision by the mentor session that directed the Templar work for the owner (guide,
  section 12, describes the role for every developer). The owner can overturn a mentor decision.

The owner's own words are quoted in French where they were recorded, with an English gloss.

**Where each decision is recorded.** "Recorded in" names the ADR under `docs/adr/` that states or applies the decision.
"No ADR found" means that, at the time of writing, no ADR states it; this page is then its record (listed in the
appendix).

---

## Part 1. Rules that bind every class

### 1.1 What counts as expected behaviour

**G-1. The tooltip governs, read literally.** 2026-11-10, owner, on the Aggramar's Rage decision page.
- The owner's comment: "Si les tooltips mentent à quoi servent-elles ?" ("If the tooltips lie, what are they for?").
- Precedent: "Holy critical strike chance" means every Holy-school critical strike, not a class-mask rewrite.
- Recorded in ADR 0104.

**G-2. Server fixes need independent evidence.** 2026-11-11, owner.
- No server change may rest only on our own check.
- A server fix cites the tooltip text, the Ascension logs or an owner ruling.
- Recorded in ADR 0128 and in the conformance README's "Method rule".

**G-3. A fix proposal needs a reproduced alert.** 2026-11-10, owner, on the mentor's alert-precision finding.
- No server fix goes to the owner on an alert that a behavioural scenario has not reproduced on the current build.
- Context: in round 10, 2 of 8 investigated alerts were server defects; 4 already worked and 2 were wrong tests.
- ADR 0118 records the finding in its Context section. No ADR found stating the rule itself.

**G-4. Ambiguous cases go to the owner with full context.** 2026-11-10, owner.
- The case carries the tooltip, the server behaviour, any log evidence, and the options with their consequences.
- The question format is in the guide, section 8. No ADR found.

**G-5. Sentences pulled in from another spell.** 2026-11-10, owner.
- A sentence that a tooltip pulls in from another spell through an `@s:` reference counts only if that spell is not
  evaluated on its own. It then joins the parent tooltip's clauses.
- ADR 0116 names the `@s:` sentence lister. No ADR found stating the rule.

**G-6. A tooltip percentage on direct damage is that exact increase.** 2026-11-10, owner.
- Case: High General, "to deal $s1% increased direct damage", with $s1 = 100.
- The measurement must show +100%, not the x1.5 the code applied.
- Recorded in ADR 0104.

**G-7. Coefficients follow the spell the player learns or casts.** 2026-11-10, owner.
- A coefficient follows that spell's text, never a triggered spell's own description or a buff tooltip.
- Recorded in ADR 0104, and stated as a rule in `docs/coa/templar-completion.md:104`.
- Every case the rulings name is a Templar spell. Whether the rule binds other classes is open (the guide, section 13).

**G-8. Alignment.** 2026-11-10, owner.
- When several places in the game give contradictory information, every place the project owns is aligned to the
  decision: server DBC fields and SQL, CoA code, class files and expected values, regression scenarios and docs.
- Client-only texts (owner go, 2026-11-10): the server restates them through `coa_client_spell_description`, streamed in
  `SMSG_PATCH_SPELL`.
- Recorded in ADR 0104 and ADR 0105.

**G-9. Older references.** 2026-11-11, mentor.
- A reference older than our data may disagree with our tooltip. If the measurement matches our tooltip, the verdict is
  conformant, and the reference is cited as an older state.
- It becomes a question only when the measurement disagrees with our own tooltip, or when the tooltip is ambiguous.
- No ADR found.

**G-10. Video evidence.** 2026-11-11, mentor.
- A video row is evidence of expected behaviour on the original server at its date, in the same role as a live log. It
  can support an expectation, shape a test or back an owner question.
- It never makes a claim behaviour proven. A video number is never an expected value, because our Spell.dbc is later
  than the videos.
- No ADR found. ADR 0243 cites videos as support only.

**G-11. Reference search first, with a fixed trust order.** 2026-11-11, owner.
- Every agent that judges expected behaviour or designs a test first searches the existing references, and cites what it
  found or writes "nothing found".
- Trust order: server data and owner rulings, then live captures, then official pages, then fan-written notes.
- No ADR found. ADRs 0286-0289 record such searches.
- The order differs from `references/sources.md`; conformance work uses the order above.

**G-12. "No path" needs every grant path.** 2026-11-11, mentor. A conclusion that a spell cannot be obtained lists every
table and code path that can grant it:
- SkillLineAbility, CharacterAdvancement and playercreateinfo;
- the two CoA baseline tables, `AscensionLiveBaselineData.h` and `AscensionCustomClassData.h`, with
  SynchronizeProgression;
- spec and talent learns;
- the scripts.

Otherwise the conclusion reads "not found in the places searched", naming them. No ADR found. `references/sources.md`,
"Obtainability", states the same caution.

**G-13. Words with a ruled meaning.** 2026-11-11, owner (Lorescribe, rule M-3).
- "Spell damage" in a tooltip names the spell power stat, wherever the same words appear.
- ADR 0132 records the Lorescribe case. No ADR found stating the rule.

**G-14. The effectiveness of a single-value buff.** 2026-11-12, mentor; the owner can overturn it.
- When "the effectiveness of X" meets an X that states exactly one value, the claim's subject is that value.
- It does not extend to a buff with two or more values, nor to duration, range or other unstated properties.
- Recorded in ADR 0268.

**G-40. The CoA Knowledge service adds no independent weight for values.** 2026-11-11, mentor.
- Its Spell.dbc layer was built from a client whose Spell.dbc equals ours (same record count; 28 Templar spells compared
  identical).
- Its spell values therefore confirm nothing on their own.
- No ADR found.

### 1.2 What counts as proof

**G-15. Two proof statuses.** 2026-11-10, owner, on the mentor's external review.
- "Data conformant" is a readback of a computed value.
- "Behaviour proven" means the value is shown to be consumed by the path that acts.
- The coverage figure reported to the owner is the behaviour-proven one.
- Recorded in ADR 0120.

**G-16. Mixed proofs.** 2026-11-11, owner.
- A clause counts as behaviour proven only when every claim in it is proven in game. Otherwise it is data conformant.
- Recorded in ADR 0131.

**G-17. One build per verdict.** 2026-11-10, owner.
- Every verdict carries the server commit and the run that produced it.
- Coverage and compare refuse a verdict from another build, for alerts as well as proofs.
- Recorded in ADR 0118 and ADR 0120.

**G-18. Hooked amounts are "not measured".** 2026-11-10, owner.
- A CalcValue readback of an effect whose amount a CalcAmount hook sets is reported "not measured", not as an alert.
- Recorded in ADR 0118.

**G-19. Tolerance band.** 2026-11-11, owner.
- A percent bonus must lie within the larger of 5% of its value and 2 points: "+20%" passes from +18% to +22%.
- Each report states the interval actually excluded. Recorded in ADR 0125.
- Scope (owner, 2026-11-11): the band applies to random measurements (damage, healing, rates). Deterministic stat
  readings are judged to the rounding. Where the rounding cannot separate the stated value, the clause stays data
  conformant. Recorded in ADR 0135.

**G-20. Chance and rate claims beyond what one accelerated scenario holds.** 2026-11-12, mentor. The band is not
widened.
1. First, about 300 casts per arm, recorded as "effect present, interval stated". This is not final.
2. Then a pooled proof to the band, using the pooling extension, which accepts rates as well as damage ratios.
3. If the pooled proof is not done at the cap, or would cost over 90 minutes for one claim, the claim goes to status 5.
   It carries the measured interval and the cast count the full band needs.

Recorded in ADR 0173 and ADR 0195.

**G-21. Rule 4: what a read proves.** 2026-11-11, mentor.
- A damage read counts as behaviour when the value comes from a damage event actually applied in the run: the health the
  unit lost, or the event the server sent for that hit.
- It is a readback when the harness calls a calculation function or reads a stored modifier with no hit applied.

The amendment, 2026-11-12, mentor, points 1-6: the claim's subject sets the scope, not the code the read passes through.
1. A damage or healing claim is proven only by a hit or heal actually applied. A stat read, a calculation call or an
   aura amount is a readback for it.
2. A stat or unit-property claim is observed through the live unit's value. The read counts as behaviour only when all
   four hold:
   - (a) the value comes from server state, or from the function the engine calls at use time, and is not recomputed
     from DBC values;
   - (b) the change came from a real application (a real cast, a learned talent, an equipped item), never a direct
     write;
   - (c) there is a contrast on one build;
   - (d) the client-visible field is preferred, and the verdict names the read.
3. A stat read never upgrades a damage or healing claim. A claim with both parts is split by part.
4. A claim's subject is read together with the recorded rulings. For example, G-13 makes "Holy spell damage" a stat
   claim.
5. A crit field read after a harness-forced `UpdateCritPercentage` meets 2a. The verdict states that limit.
6. A harness-set aura (`set_aura`) is acceptable only as a precondition fixture, and only when all three hold:
   - the subject is a different effect, applied for real with a contrast arm;
   - the outcome is an applied event or a live state;
   - the verdict names the fixture.

   It is never acceptable when the aura itself is the subject. Where a real cast costs about the same, the author uses
   the cast.

Clarification (2026-11-12, mentor): "prefer the client field" is a preference, not a condition. A spell power read on
Holy only is accepted when the wording is general or about Holy. The verdict then says "read on Holy; other schools by
the aura's school mask in the data".

No ADR states rule 4 or its amendment. ADRs 0258 (point 2), 0263 (point 2b) and 0287 (point 6) apply it.

**G-22. Stat-gain contrast.** 2026-11-12, mentor. A cast's stat gain counts as behaviour only when all of these hold:
- attribution: the aura is read absent before the cast and present after, and the delta matches;
- the verdict lists the cast's other auras, and a no-aura arm is added if one of them touches the same stat;
- the stat returns after removal or expiry;
- the cleared state is verified by a read.

Recorded in ADR 0258.

**G-23. Testing a subset of covered spells.** 2026-11-12, mentor, on Combat Training (the ruling's "2 of 13 Oaths in
game"; the measured split is 3 of 13 percent Oaths). If running every spell an effect covers is not cheap, a subset is
accepted only when all three hold:
- one effect with one class mask covers them all;
- every scripted one is tested;
- the tested ones differ in shape.

The verdict states the split. No ADR found.

**G-24. Terminal "no behaviour route".** 2026-11-11, owner.
- A clause that only a data check can verify, because no behaviour route exists, takes the terminal status "data
  conformant, no behaviour route", with the reason written.
- A second agent must first attempt a route.
- Recorded in ADR 0136.

**G-25. Five final statuses, and gaps are not one of them.** 2026-11-11, owner, in the Templar completion goal.
- Every claim ends with one of five final statuses (guide, section 2).
- A tool gap is closed by extending the tool:
  - the smallest extension;
  - seeded tests;
  - a mutant that must alert;
  - existing scenarios regenerating byte-identical;
  - a one-off clock line.
- A gap becomes status 5 only after two different extension designs have failed, or when one claim would cost more than
  90 agent-minutes. That status 5 records the cost estimate and the designs tried.
- No ADR found. The ledger schema has no field for statuses 2, 4 and 5 (the guide, section 13).

### 1.3 Known engine behaviour (accepted, not fixed)

These are stock-engine results that differ from a literal reading of the tooltip and are accepted for every class. Each
needs evidence in the verdict.

**G-26. Rounding 1: percent-derived stats.** 2026-11-11, owner ("Sturdy, no server change"). It supersedes an earlier
ruling to fix the rounding in the core, given with the words "1,049 arrondi devrait donner 1,05, à corriger donc"
("1.049 rounded should give 1.05, so fix it").
- A percent-derived stat that reads exactly 1 below the tooltip value is "conformant, known engine rounding" when
  emulating the engine's float computation reproduces the observed value. The emulation covers the factor built by
  AddPct in float, the product and the truncation. The verdict carries the computed float value.
- One above, two or more away, or a one-below that the emulation does not reproduce stays a deviation.
- Scope: stats reached through the percent modifier path only (max health, max power, the five stats, armor,
  resistances). Never damage, healing, durations or anything else.
- Reason given: the same float truncation sits in about twenty stat casts of that shape in StatSystem.cpp, for every
  class, and nobody knows what the lost server showed.
- Recorded in ADR 0141.

**G-27. Rounding 2: int32 truncation of formula values.** 2026-11-11, owner. Accepted for damage and healing amounts
when all three hold:
- the reading is at most 1 below the tooltip range, toward zero;
- the engine's computation reproduces it: the formula value, then the int32 truncation at `SpellEffectInfo::CalcValue`;
- the verdict carries the computed value.

Recorded in ADR 0145.

**G-28. Rounding 3: per-level truncation.** 2026-11-11, owner, option (a). The stock CalcValue truncates the per-level
term early.
- The rule applies to all 21 classes (ADR 0147). Reason given with the ruling: this is stock arithmetic on 9,881 spells
  of the server Spell.dbc, 1,568 of them CoA class spells (counted for the ruling; not in the ADR).
- A read is ok only when the full engine computation reproduces it exactly: the per-level truncation, the percent effect
  modifiers and the final int32 truncation, plus the multipliers and the tick count for a hit or a periodic total. There
  is no flat "1 below" band.
- Where the tool cannot yet model the computation, the read stays an alert labelled "per-level truncation, engine
  computation not modelled".
- A mutant of the same size that the computation does not explain still alerts.
- Recorded in ADR 0147.

**G-29. Effective radius.** 2026-11-12, owner, question Q-rad-1, option (a). The engine's effective radius is accepted
as known engine behaviour, by mechanism:
- **The caster's leeway, 2.66 yd.** It applies to a player caster on implicit-target area spells, when the caster is not
  jumping or falling and its run speed exceeds 4.97, which holds for a standing player too.
- **The target's combat reach.** It applies when the caster is player-controlled and the target is not.
- **Both object sizes, with no leeway.** This applies to area auras and script distance checks.

The leeway is this core's rule, from upstream AzerothCore. It is not proven live behaviour: live Ascension evidence was
not looked for. The owner accepted it on that basis. A contributor must not cite it as how the original server worked.

Proof conditions (mentor, 2026-11-12):
- bracket the edge to 0.5 yd, centre to centre, with the combat reach read from the server;
- give the arithmetic with file:line for every term;
- run a stock area spell as a control.

Recorded in ADR 0253 and ADR 0288.

**G-30. Truncated target counts.** 2026-11-12, owner, question Q-r3b-2, option (a): "Truncation is accepted for target
counts."
- Ruled on Combat Training ("Increases the effectiveness of Oaths by 20%") applied to Holy Cleave's one extra target:
  int32(1 x 1.2) = 1.
- No ADR found. The wording is general, but it was ruled on one Templar case (the guide, section 13).

**G-31. Shared engine arithmetic.** 2026-11-11, owner, on the Staffguard and Sturdy scope.
- A shared core calculation is fixed for everyone, in the core, or not at all. It is never fixed through a per-class
  hook.
- The rule against cross-class links concerns reused spell effects, not shared engine arithmetic.
- The later Sturdy ruling (G-26) applied "not at all".
- No ADR found. ADR 0141 records the Sturdy outcome.

### 1.4 Levels

**G-32. Level policy.** 2026-11-11, mentor method decision, with the owner's amendment and the mentor's refinement.
- Players are at or below 60, at 60 by default.
- A lower player level is used only when the claim is about level. Both arms then use the same gear and stats, and the
  expected value is computed at each level.
- Targets are at 60 for a claim about what a spell does.
- Targets at 61 to 63 (elites and bosses) are used only when the claim or scenario is about higher-level targets. The
  scenario states the gap, and its verdict accounts for the gap's effects.
- Players above 60 and targets above 63 are never used.

ADR 0154 applies it to generated fixtures ("keep generated fixtures at the class level"). No ADR found stating the whole
policy.

**G-33. The realm cap is 60.** 2026-11-11, owner, through the mentor.
- "The game can in theory reach level 80, but production, the PTR and most CoA servers are capped at 60. Nobody has gone
  above 60 and nobody will."
- The migration of the dev and test configs to 60 is parked until the Templar work is finished. New conformance
  scenarios use level 60 already.
- No ADR found.

### 1.5 Streamed client texts

**G-34. Judge against the streamed text.** 2026-11-11, mentor.
- Where a spell has a streamed description, its claims are judged against the streamed text, and the ledger names the
  text used.
- Recorded in ADR 0192.

**G-35. Provenance of streamed texts.** 2026-11-11, mentor.
- A streamed override is written by this project, so a server that matches it proves nothing unless the override rests
  on an owner ruling or a live source.
- Claims that rest only on "align the text with the server" are marked "judged against a project-written text, no
  independent expectation". The DBC text stays visible beside it.
- Recorded in ADR 0198.

**G-36. The text_correction basis.** 2026-11-12, mentor.
- It qualifies only when the tool confirms that every number, duration, count and named spell in the claim's sentence is
  identical in the DBC text and the streamed text.
- Any difference sends the claim back to an owner ruling, a live source or "project-written text".
- Recorded in ADR 0198.

### 1.6 Working terms (fixes, questions, extensions)

These were set for the Templar completion goal. For other developers, a mentor session takes the mentor's part (G-41);
without one, the working agent applies G-37 strictly and sends what G-38 leaves open to the owner.

**G-37. When the mentor can approve a server fix.** 2026-11-11, mentor. All four must hold:
1. the tooltip, or a recorded ruling, states the expectation without ambiguity;
2. the measurement contradicts it;
3. the cause is in CoA code;
4. the change stays in the class's own code.

If one fails, the claim goes to status 5 with a written question. No ADR found.

**G-38. What the mentor settles.** 2026-11-11, mentor.
- The mentor settles method, tools, proof standards, derivations from an existing ruling, incorrect tests and
  older-reference cases.
- Expected behaviour that no tooltip, ruling or reference decides goes to status 5 at once.
- No ADR found.

**G-39. Tool extensions.** 2026-11-11, mentor.
- A tool extension needs no approval beforehand; it is reported in the batch report.
- A harness C++ change beyond reading and recording needs a note first: to the mentor, or without one to the owner.
- Precedent: raising the harness MaximumCreatures from 8 to 12 was ruled a tool extension (ADR 0221).
- No ADR found for the term itself.

**G-41. A mentor session is recommended, not required.** 2026-11-12, owner. "il faut que le développeur dédie un autre
agent à cela et il faut le prévenir si cela manque. il doit pouvoir faire sans cela dit, ce n'est pas obligatoire, juste
moins efficace." ("The developer should dedicate another agent to it, and must be warned if it is missing. They must be
able to work without it, though: it is not mandatory, just less efficient.")
- Each developer dedicates a second agent session to the mentor role, separate from the working agent.
- The working agent tells the developer at the start if no mentor session is set up.
- Without a mentor, the working agent applies G-37 strictly and sends every doubtful case to the owner.
- No ADR found. The mentor's brief is in the guide, section 12.

**G-42. What every contributor has.** 2026-11-12, owner. "ils auront comme moi les dbc, les logs, et le mcp. pour les
videos c'est optionnel et chacun est libre de le faire ou non." ("They will have, like me, the DBCs, the logs and the
MCP. Videos are optional, and each is free to use them or not.")
- The reference search rests on the server DBC set, the combat logs and the CoA Knowledge MCP.
- Combat logs (owner, 2026-11-12): "chacun utilise les siens, les devs doivent les demander à un autre dev au pire"
  ("each uses their own; at worst, developers ask another developer for them"). The repository provides no shared
  archive.
- Videos are optional.
- Other reference snapshots are used if a contributor has them.
- No ADR found.

---

## Part 2. Templar rulings (precedent)

Each is binding for the Templar only. "Applies as precedent" marks wording that a later class may meet again.

### 2.1 Meaning of tooltip words

| Date, author | Spell and tooltip words | Ruling | Owner's words | Recorded in |
|---|---|---|---|---|
| 2026-11-12, owner | "High Threat" (Sacred Swing: "dealing $s2% High Threat Weapon Damage"; Faith Guard; Armor of Faith) | One meaning: threat x2 on damage, flat threat kept. Sacred Swing goes from 2.25 to 2. The owner scoped it to Templar tooltips; applies as precedent | "j'avais tout x2 je crois car les tanks manquaient fortement de threat" ("I think I had everything at x2, because tanks badly lacked threat") | ADR 0296 |
| 2026-11-12, owner | Absolution "Taunt all enemies within 8 yds" | "All" sets no count cap; the radius is the limit. Applies as precedent for "all enemies" | "pourquoi limiter en nombre ? all n'induit pas cette notion de limite. par contre on limite par rapport à la distance je pense" ("why limit the number? 'all' does not imply a limit. We do limit by distance, I think") | ADR 0288 |
| 2026-11-12, owner | Lightkeeper "to up to $561277i1 enemies"; Norgannon's Wrath / Pulverizing "to up to $524740i enemies" | "N in all": the target counts among the N. Applies as precedent | not recorded | ADR 0294 |
| 2026-11-12, owner | Duty Calls "increases your damage dealt and movement speed by 2%" | Everything included, Physical too | "tout inclus" ("everything included") | ADR 0287 |
| 2026-11-12, owner | Eternal Blessing "Increases your Holy damage and healing done by $s1%" | Healing done, not healing received | not recorded | ADR 0286 |
| 2026-11-12, owner | Testament of Resolve "granting immunity to fear, charm, and horrify effects" | "Charm" means mind control; immunity added in Templar code | "oui" ("yes"), confirming the mind-control reading | ADR 0297 |
| 2026-11-12, owner | Crusader's Brand "preventing them from mounting, fleeing, or increasing their movement speed" | "Fleeing" is the low-health flee of creatures; fear still applies | not recorded | ADR 0298 |
| 2026-11-12, owner | Legacy of the Silver Hand "Increases the critical damage of Scourgebane by $s2%" | The bonus reading: the crit bonus grows, not the whole hit | not recorded | No ADR found |
| 2026-11-12, owner | Argent Blade, which "unleashes Scourgebane, dealing [formula] Holy damage" | The server is right: one strike spell, including Scourgebane's 50% weapon damage | not recorded | No ADR found |
| 2026-11-12, owner | Silverhand Incantation "removing Sacred Restraint from you and them if they are an ally" | Removed from the caster in every case, from the target only when it is an ally | not recorded | ADR 0292 |
| 2026-11-12, owner | Disciplined Mind (Benediction dispel) under Holy Cleave stacks | Benediction dispels every ally it heals | not recorded | ADR 0293 |
| 2026-11-12, owner | Blade of Faith "Consumes your Oaths, dealing additional damage for each consumed" | Each consumed Oath whose data add nothing to the ticks strengthens them by +10%, a provisional tuning value; the other Oaths keep their own effects. Stacking is additive (mentor, following a Templar precedent) | "ok, alors disons +10% pour le moment et voir ce que ça donne comparé aux autres" ("ok, let's say +10% for now and see how it compares with the others") | ADR 0289 |
| 2026-11-10, owner | Faith Guard "High Threat" | Threat x2 on damage, flat +100 kept (later generalised, see the first row) | not recorded | ADR 0104 |
| 2026-11-10, owner | Devotion of Khaz'goroth and Crusader's Presence, "Does not stack with similar effects." | Devotion: the same-type party haste auras of one spell group. Crusader's Presence: only the strongest mounted-speed bonus counts | not recorded | ADR 0104 |
| 2026-11-10, owner | Sacred Swing "Only usable after avoiding an attack." | Dodge or parry only | not recorded | ADR 0104 |
| 2026-11-10, owner | Aggramar's Rage "Holy critical strike chance" | Every Holy-school critical strike (literal reading) | "Si les tooltips mentent à quoi servent-elles ?" | ADR 0104 |
| 2026-11-10, owner | Improved Benediction armour "based on your Agility and Stamina" | Conformant if armour rises with both; the current code (Agility + Stamina) is kept | "Bonus d'armure en pourcentage de l'agilité et l'endurance.. Par exemple 10% ?" ("an armour bonus as a percentage of Agility and Stamina, for example 10%?"), then "keep the current code" | ADR 0104 |
| 2026-11-11, owner | Scourgebane "Direct damage dealt now has a 20% chance to strike" | Weapon hits and direct-damage abilities roll; a Scourgebane strike never triggers another | not recorded | ADR 0130; ADR 0301 supersedes its "20% per weapon hit" summary |
| 2026-11-11, owner | Bursting Impact "Increases your off-hand weapon damage by 25%." on Zealotry | Must raise Zealotry, which deals a share of off-hand weapon damage. The fix stays in Templar code; stacking with Blade Sermon is multiplicative (mentor) | not recorded | ADR 0146 |
| 2026-11-11, owner | Disciplined Mind rank 2 "causes it to dispel 2 poison and disease effects" | 2 poison and 2 disease; rank 1 stays at 1 of each | not recorded | ADR 0159 |
| 2026-11-11, owner | Untainted, a DBC formula with m1 = -10 | The intended amount is 10 + 10% of Stamina; the DBC sign is a client-data error | not recorded | No ADR found for this ruling (ADR 0105 covers Untainted's streamed text) |
| 2026-11-11, owner | Keeping the Oath "delay 40% of direct damage taken, instead taking it over 8 sec" | 8 payments over 8 s; a second hit joins the remaining debt over the refreshed duration; payments continue every second across hits | not recorded | ADR 0155, ADR 0157 |

### 2.2 Values, coefficients and data

| Date, author | Ruling | Recorded in |
|---|---|---|
| 2026-11-10, owner | Patience lengthens Interdict's cooldown by 5 s (literal tooltip "Increases"), against the DBC's -5001 | ADR 0104 |
| 2026-11-10, owner | Divine Charge trample radius: 3 yd, the DBC radius, not the code's 5 yd | ADR 0104 |
| 2026-11-10, owner | Coefficients from the spellbook or talent tooltip: Righteous Tempest $SP*0.3; Scourgebane AP x0.25; Chakra of Light from the talent; Force of Golganneth AP x0.25, Holy | ADR 0104 |
| 2026-11-11, owner | Staffguard: the server's 0.25 parry and dodge per rating point is accepted; the tooltip gives no coefficient | No ADR found |
| 2026-11-11, owner | Force of Golganneth: 6 Zealotry triggers (one at the cast, then 5 periodic) are accepted, as there is no evidence that 6 is wrong. Conformant by ruling, and the regression asserts that shape | No ADR found |
| 2026-11-11, mentor | Zealotry at 80% and Oath Flow at +3 s are conformant: our tooltip and the measurement agree, and the references are older (G-9) | No ADR found |
| 2026-11-11, mentor | Light's Chosen spell penetration: a sign error in Templar code is a confirmed defect | ADR 0156 |

### 2.3 Equipment and reachability

| Date, author | Ruling | Recorded in |
|---|---|---|
| 2026-11-11, owner (checked on a video) | The live Zealot wields two one-hand weapons, so Zealotry's off-hand trigger is a reachable case | No ADR found (ADR 0142 records the off-hand measurement) |
| 2026-11-11, mentor | Every Templar already learns Dual Wield at login; no change | ADR 0142 |
| 2026-11-11, owner, then mentor | Blessed Padding: first ruled "unreachable", because only a level-80 chest was known. Withdrawn: a level-60 mail item (Void Slayer's Tunic) satisfies the passive, so the fixtures move to it | ADR 0154 |

### 2.4 Process decisions taken during the Templar work

| Date, author | Decision | Recorded in |
|---|---|---|
| 2026-11-11, owner | Method: the lean method plus the prototype's carried-over parts (the prove runner with the flip rule and pilot sizing, the two proof statuses, per-verdict build, the Spell.dbc guard, not_measured, event timestamps, the proof gate, expiry pairs) | ADR 0116 |
| 2026-11-11, owner | Batch protocol: the author keeps its context through triage and review fixes; only the review is an independent agent; a script builds a per-spell packet first; the proof gate refuses a behaviour check without its control arm | No ADR found |
| 2026-11-11, mentor | ADR 0045's per-level credit list rested on our own check only and is removed under a superseding ADR (G-2) | ADR 0148 |
| 2026-11-12, mentor | At most three gameplay sets at once on the shared test bench, tracked in a slots list (no repository tool) | No ADR found |
| 2026-11-12, mentor | A harness-simulated landing is accepted for a fall claim, with conditions; the report says it is simulated | ADR 0237 |
| 2026-11-12, mentor | A real second cast right after the GCD, against a refused control, proves a removed cooldown; the verdict states the GCD limit | ADR 0238 |
| 2026-11-12, mentor | An owner question quotes the tooltip in full (Duty Calls) | No ADR found |

---

## Appendix. Decisions recorded only on this page

No ADR states these decisions; this page is their record:
- **General rules:** G-3 (the rule; ADR 0118 has only the finding), G-4, G-5 (the rule), G-9, G-10, G-11, G-12, G-13
  (the rule), G-21 (rule 4 and its amendment, applied in ADRs 0258, 0263 and 0287), G-23, G-25, G-30, G-31, G-32 (as a
  whole), G-33, G-37, G-38, G-39, G-40, G-41 and G-42.
- **Templar rulings:** the live Zealot dual wield (owner, checked on a video), Legacy of the Silver Hand, Argent Blade,
  Untainted, Staffguard, Force of Golganneth, Zealotry and Oath Flow, the batch protocol, the three-set limit and "quote
  the tooltip in full".

The check covered ADR titles and texts at feat/coa-class-conformance bc391cd7bc, by phrase.
