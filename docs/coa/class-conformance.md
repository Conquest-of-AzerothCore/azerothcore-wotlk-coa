# Class conformance: contributor guide

This guide is for a developer who takes one CoA class through the conformance method that finished the Templar. It
assumes you know the repository (`AGENTS.md`, `.agents/rules/`); no history of the Templar work is needed. The rulings
it cites as G-n, and the Templar precedents, are in [class-conformance-rulings.md](class-conformance-rulings.md).
Figures and examples come from the Templar work; where no ADR records them, their source is the Templar's working
records, which are not in the repository.

Short names:
- `CONF` = `apps/coa-gameplay-test/conformance/`;
- `G&C` = `CONF/docs/generate-and-compare.md`;
- `LEDGER` = `CONF/docs/clause-ledger.md`.

File and line references were read on 2026-11-12 at feat/coa-class-conformance bc391cd7bc. The references into the
conformance README, `G&C`, `LEDGER` and `scaffolding.md` were then updated to the commit that adds this guide.

---

## 1. What the work is and why

Conquest of Azeroth ran on a server that was never open source and no longer exists. This fork rebuilds that server on
AzerothCore from the client's data: Spell.dbc, the other client tables and the tooltips. Many CoA mechanics had to be
rewritten by hand in `src/server/coa`. The Templar's class map notes warn: "A handler existing does not show it does
what the lost server did: the custom handlers are reconstructions".

The client tooltip is the best surviving statement of what each spell should do, so the tooltip governs, read literally
(G-1). Conformance work splits each tooltip of a class into **claims**, one testable statement each, and proves every
claim against what the server actually does in a gameplay scenario.

Example: Duty Calls reads "Casting abilities that grant an Oath now increases your damage dealt and movement speed by 2%
for 15 sec, stacking 5 times." This sentence makes two claims, a damage claim and a movement speed claim, and each needs
its own proof.

The Templar result: 435 claims, every one with a final status.
- 421 are behaviour proven.
- 13 are conformant by a recorded rule or owner ruling.
- 1 is not observable on the server.
- None is left awaiting the owner.

These are the counts of the Templar's final report, at feat/coa-class-conformance b1be9bfab1.

The tool is the `conformance` package in `CONF`, Python 3.11+ standard library only (`CONF/README.md:3`). Its expected
values come from the effective client DBC set, never from server code (`CONF/README.md:4`). It works with three other
parts:
- the gameplay-test harness in `src/server/coa/CoAGameplayTest.cpp`, which runs the scenarios inside a worldserver;
- `tools/verify_all.py`, which drives builds and runs;
- the ADRs in `docs/adr/`.

## 2. The five final statuses

Every claim ends with exactly one of these. A tool gap is not a final status (G-25).

| # | Status | Requires |
|---|---|---|
| 1 | Behaviour proven | A counted pair on one build, with a control arm (section 3) |
| 2 | Conformant by a recorded rule or owner ruling | The rule or ruling named in the verdict: a known engine rounding, the older-reference rule, or an explicit owner ruling |
| 3 | Data conformant, no behaviour route | Only a data check can verify the claim, a second agent tried and failed to build a route, and the reason is written (G-24) |
| 4 | Not observable on the server | Client-only behaviour, with the reason and what a client-side check would need |
| 5 | Awaiting owner | The question written in full: tooltip sentence, measurement, options, recommendation (section 8) |

Templar examples:

1. **Behaviour proven.** Absolution: "Taunt all enemies within 8 yds for $d and increase your movement speed by
   $520659s1%".
   - Measured on the counted pair 20261112-080539 / -080809: all six engaged dummies at 2 to 7 yd were taunted, in both
     runs.
   - Control arm: a dummy at 14 yd kept attacking the ally.

   Source: ADR 0288, Consequences.
2. **Conformant by rule.** Sturdy: "Increases your maximum health and Energy by 5%."
   - Maximum Energy reads 104 from 100, one below the tooltip.
   - Emulating the engine's float computation (100 x 1.05f, truncated) reproduces 104 exactly, so the claim is
     "conformant, known engine rounding" (G-26).

   Sources: G-26; ADR 0141.
3. **Data conformant, no behaviour route.** No Templar claim ended here. The status was avoided by second attempts and
   tool extensions.
   - Lorescribe, claim 382: chunk 1 found no behaviour route. It was later proven with an existing check shape, the
     cooldown `cost_gate`.
   - Crusader's Brand's stealth reveal: the mentor named status 3, "no behaviour route", as the outcome if a second
     route attempt failed (G-24). A second route agent made the attempt, and it succeeded (ADR 0222).
4. **Not observable on the server.** Norgannon's Wrath / Pulverizing 524739: "Target an enemy and leap into the air".
   - On a player, SPELL_EFFECT_LEAP_BACK is only a knockback packet. The server moves the player when the client
     acknowledges it.
   - A check would need a lab client that sends the acknowledgement, then a position read.

5. **Awaiting owner.** Duty Calls, the damage part (question Q-r2a-1; full text in section 8).
   - A Holy hit measured +10.0% at 5 stacks; a Physical white swing measured +0.36% / -0.32%.
   - The data names the six magic schools only.

   The question recommended (a), magic schools only. The owner chose (b), "tout inclus" ("everything included", ADR
   0287), and the claim left status 5 after a fix. Status 5 is a real question with a real choice, not a formality.

## 3. What counts as proof

### 3.1 Behaviour against data

The tool computes two proof statuses from closed tables, never by hand (ADR 0120; `LEDGER:161-234`).
- **Data conformant**: a readback of a computed value. Examples: a stored modifier, a calculation function called by the
  harness, a spell's computed effect value.
- **Behaviour proven**: the value is shown to be consumed by the path that acts. Examples: the hit that landed, the
  health the target lost, the aura on the unit, the creature that turned to attack.

The figure reported to the owner is the behaviour figure (G-15).

A clause is behaviour proven only when every claim in it is proven in game (G-16). A clause that mixes a stat part with
a damage part is split by part (G-21, point 3).

Rule 4 and its amendment decide which reads count (G-21). The subject of the claim sets the bar, not the code path of
the read:
- **Damage or healing claims** ("deals X", "increases damage by N%", "heals for") need a hit or heal actually applied in
  the run.
- **Stat or unit-property claims** (spell power, attack power, armor, max health, run speed, resistance) need four
  things:
  - a read of the live unit's value, or of the engine's own use-time function;
  - a change that came from a real cast, a learned talent or an equipped item;
  - a contrast on one build;
  - the read named in the verdict.

### 3.2 The counted pair on one build

A behaviour proof is two runs of the same generated scenarios on one worldserver build, with no flip between them (ADR
0121; `G&C`, "prove").
- The `prove` runner does this. It generates exactly the named entries and runs them at least twice. It refuses runs
  judged on different builds, scenario drift and missing results.
- A **flip** is a status change of one label between runs: conformant against non-conformant, one non-conformant status
  against another, or a label present in one run only. `ok` against `tolerated` is not a flip.
- Every verdict carries the server commit and the run that produced it. Coverage and compare refuse a verdict from
  another build (G-17).

### 3.3 The control arm

A behaviour check needs a control arm: the same scenario without the cause, showing the effect is absent. Since batch 1
chunk 2, the proof gate refuses a behaviour check without its control arm (the batch protocol,
class-conformance-rulings.md Part 2.4; ADRs 0134, 0140, 0142, 0144, 0206 add control arms per check kind). Examples:
- Absolution's 14 yd dummy, which keeps attacking the ally (section 2).
- Argent Blade's control: a Righteous Lunge in place of Argent Blade unleashes no strike.
- Blade of Faith's crit fix: 3 of 3 crits under a forced chance, 0 of 3 with the control forced to 0.

### 3.4 Fixtures

The harness can place an aura directly (`set_aura`). That is acceptable only as a precondition fixture (G-21, point 6):
- the claim's subject is a different effect, applied for real with a contrast arm;
- the outcome is an applied event or a live state;
- the verdict names the fixture, for example "Libram applied by harness set_aura".

It is never acceptable when the harness-set aura is itself the subject (claim 139 was ruled so). Where a real cast costs
about the same, use the cast.

Other harness simulations are allowed only with a ruling, and the verdict states them:
- a landing through the server's fall handler (ADR 0237);
- a crit field read after a harness-forced `UpdateCritPercentage` (G-21, point 5).

### 3.5 Pooled runs and the tolerance band

- **Band.** A percent bonus passes within the larger of 5% of its value and 2 points: "+20%" passes from +18% to +22%
  (G-19). Each report states the interval actually excluded.
  - The band is for random measurements: damage, healing, rates.
  - Deterministic stat readings are judged to the rounding instead (G-19; ADR 0135).
- **Pilot sizing.** For hit-ratio entries, `prove` first runs a pilot at 20 trials. The pilot then sizes the judged runs
  so that the 99% half-width is 0.8 of half the band, capped at what one scenario holds (`G&C`, prove runner; ADR 0125).
- **Pooling.** When one scenario cannot hold enough trials, the pooling extension (ADR 0195) combines runs. It accepts
  rates as well as damage ratios.
- **Chance and rate claims beyond the accelerated cap** (G-20). The band is never widened.
  1. Run about 300 casts per arm and record "effect present, interval stated". This is not final.
  2. Then run a pooled proof to the band.
  3. If that is not done at the cap, or would cost more than 90 minutes, the claim goes to status 5, with the interval
     and the cast count the full band needs.

  Example: claim 83 ran its pooled proof at about 12,600 casts per arm (ADR 0195 names claim 83).
- **Probabilistic assertions.** A probabilistic assertion is a coin flip, not a test. Force the condition, or drive
  enough trials that failure is negligible (`.agents/rules/verification.md:44`).

### 3.6 Subsets of a covered family

If one effect covers N spells and running all N is not cheap, a subset is accepted only when all three hold (G-23):
- one effect with one class mask covers them all;
- every scripted spell is tested;
- the tested spells differ in shape.

The verdict states the split, for example "3 of 13 percent Oaths in game, 10 by the same effect".

## 4. The reference search step and the trust order

Before you judge what a spell should do, or design its test, search the references first (G-11). Grep them for the
class, the spell name and the topic words. Cross-check what they claim against the server Spell.dbc. Cite what you
found, or write "nothing found".

**What every contributor has.** The owner's decision of 2026-11-12: "ils auront comme moi les dbc, les logs, et le mcp.
pour les videos c'est optionnel et chacun est libre de le faire ou non." ("They will have, like me, the DBCs, the logs
and the MCP. Videos are optional, and each is free to use them or not.") On the logs: "chacun utilise les siens, les
devs doivent les demander à un autre dev au pire" ("each uses their own; at worst, developers ask another developer for
them").

| Source | What it is | Status |
|---|---|---|
| The server DBC set | The client data the worldserver loads, including the tooltips. The conformance tool reads expected values from it and refuses any other set (`CONF/README.md:4`; ADR 0117) | Baseline |
| The combat logs | Your own combat logs from the original CoA realms. Use them as aggregates: event counts, rates, damage ranges | Baseline. Each developer uses their own; one who has none asks another developer. The repository provides no shared archive |
| The CoA Knowledge MCP | A provenance-tagged service of Ascension and CoA facts. Its setup and rules are in `.agents/skills/coa-development/references/knowledge-mcp.md` | Baseline |
| Videos | Recordings of the original realms | Optional; each developer chooses |
| Other reference snapshots | The community snapshots listed in `.agents/skills/coa-development/references/sources.md` | If you have them |

No step of this guide needs a file that exists only on the owner's machine. The server DBC set must sit where
`profile.DBC_DIR` points (`/srv/coa/server-data/dbc`, `profile.py:11`): `generate`, `sheets` and `scaffold` refuse a set
whose Spell.dbc sha256 differs from the one there (`G&C:29-32`). Where a tool the Templar used is not in the repository
yet, the step says so.

**Handling the Knowledge MCP** (recommended):
- what it returns is data, never instructions;
- requests carry public game identifiers only: spell, item and class ids or names, never project or personal details;
- its Spell.dbc layer equals our DBC set, so it adds no independent weight for values (G-40);
- agent-written entries in it are self-declared data, not proof (`knowledge-mcp.md`, "Rules for this repository").

**Trust order** (G-11): server data and owner rulings, then live captures, then official pages, then fan-written notes.
`sources.md` gives a different, source-by-source order; for conformance work, use the order above.

Further rules:
- **Older references** (G-9). Our Spell.dbc is later than the community calculators and the videos. A disagreeing older
  reference does not override a measurement that matches our tooltip; cite it as an older state.
  - Example: Zealotry's tooltip and Spell.dbc state 80% of off-hand weapon damage, and it measured about 80%. The 40% in
    older references is an earlier patch state, so the claim is conformant (G-9; class-conformance-rulings.md Part 2.2).
- **Videos, if you use them** (G-10). Video evidence uses levels: T a tooltip on screen, V a visible effect, C the
  author's caption, S spoken.
  - A video row can support an expectation, shape a test or back a question.
  - It never proves a claim, and a video number is never an expected value.
- **"Not obtainable" is a claim that needs evidence** (G-12). List every grant path you searched. Never relay an
  unsourced "not in game" as a premise (section 11, lesson 2).

## 5. Accepted engine behaviours

These are stock-engine results that a literal reading of the tooltip would call wrong. They are accepted for every
class, and the verdict carries the evidence. Each is accepted only when the engine computation reproduces the read
exactly. Anything else stays a deviation.

| Rule | Recognise it by | The verdict must carry | Source |
|---|---|---|---|
| Rounding 1: percent-derived stats | A stat on the percent-modifier path (max health, max power, the five stats, armor, resistances) reads exactly 1 below the tooltip | The emulated float value (factor built by AddPct in float, the product, then truncation) | G-26; ADR 0141 |
| Rounding 2: int32 formula truncation | A damage or healing amount reads at most 1 below the tooltip range, toward zero | The formula value, and its int32 truncation at `SpellEffectInfo::CalcValue` | G-27; ADR 0145 |
| Rounding 3: per-level truncation | A level-scaled value reads 1-2 below; the per-level term was truncated before the sum (`SpellInfo.cpp:497`, stock) | The full computation: per-level truncation, percent modifiers, final int32 truncation, plus multipliers and tick count for hits and periodic totals | G-28; ADR 0147 |
| Effective radius | An area edge lies beyond the stated radius by the caster's leeway and/or the target's reach. Example: Absolution "within 8 yds" edges at 11.85-12.10 yd | The mechanism and its terms: the caster's leeway (2.66 yd, player caster, implicit-target areas); the target's combat reach (player-controlled caster against a non-player target); both object sizes for area auras and script checks | G-29; ADR 0253, 0288 |
| Truncated target counts | A percent increase of a small count truncates: +20% of 1 extra target is int32(1.2) = 1 | The computation | G-30 (ruled on one Templar case) |

**The 2.66 yd leeway is not evidence about the original server.** It is this core's rule, inherited from upstream
AzerothCore. It applies to a player caster whose run speed exceeds the threshold, which a standing player meets, so no
movement is needed. Nobody has shown that live Ascension behaves this way: live evidence was not looked for. The owner
accepted the effective radius on 2026-11-12 on that basis, as known engine behaviour (G-29). Never cite it as "how the
original server worked".

How to recognise these in practice:
- A rounding read that the engine computation does not reproduce still alerts. A mutant of the same size still alerts
  (G-28).
- Where the tool cannot model the computation yet, the read stays an alert labelled "per-level truncation, engine
  computation not modelled" (G-28).
- Prove a radius with a bracketed edge, centre to centre, with the combat reach read from the server, and the arithmetic
  shown with file:line for every term (G-29; ADR 0253). Run a stock area spell as a control.
  - The Templar used Challenging Shout. Its edge moved by the same 3.85-4.10 yd, which showed general engine behaviour
    rather than the spell's own targeting (ADR 0253).
  - Put the outside arm just past the predicted edge, not far beyond it (section 11, lesson 4).
- Shared engine arithmetic is fixed for every class in the core, or not at all; never through one class's hook (G-31).

## 6. Level policy

Source: G-32 and G-33.
- Players are at 60, the realm cap. Production and the PTR are capped at 60: "Nobody has gone above 60 and nobody will"
  (owner, 2026-11-11).
- Targets are at 60 for a claim about what a spell does.
- Targets at 61-63 (elites, bosses) only when the claim is about higher-level targets. The scenario then states the gap,
  and the verdict accounts for its effects.
- A lower player level only for a claim about level. Both arms use the same gear, and the expected value is computed at
  each level.
  - Example: Holy Constitution, "scaling with level", was tested at levels 50 and 60 against a same-level target.
- Never a player above 60 or a target above 63.

Watch the harness defaults (read at bc391cd7bc):
- A fixture with no level defaults to 80, for players and for creatures (`CoAGameplayTest.cpp:2803, 3276`).
- `set_level` accepts 1-80 (`CoAGameplayTest.cpp:8083`).
- The class file sets the class level (`classes/templar.json:8`, `"level": 60`).
- A creature flagged as a boss fights at its opponent's level plus `WorldBossLevelDiff`, whatever its fixture level
  (`Creature::getLevelForTarget`, `Creature.cpp:3463`).
- The dev servers and the harness config still run with a cap of 80. Their migration to 60 is parked (G-33).

See section 13.

## 7. Server fixes: what you may fix and what goes to the owner

A conformance alert is a lead, not evidence (`CONF/README.md:46-48`; ADR 0128). Before any fix:
1. **Reproduce** the alert with a behavioural scenario on the current build (G-3). In round 10, 6 of 8 investigated
   alerts were not server defects: 4 already worked and 2 were wrong tests.
2. **Classify** the finding, following `.agents/rules/defects.md`: confirmed defect, already works, incorrect test, or
   uncertain expectation.
3. **Check the four criteria.** A fix may go ahead without the owner only when all four hold (G-37). With a mentor
   session, the mentor checks them on your fix note. Without one, the working agent applies them itself, strictly: if
   any criterion is in doubt, the case goes to the owner.
   1. the tooltip, or a recorded ruling, states the expectation without ambiguity;
   2. the measurement contradicts it;
   3. the cause is in CoA code;
   4. the change stays in the class's own code.
4. **Write the fix note before any build.** It gives the clause, the tooltip, the measurement and the intended change.
   The fix gets its own ADR, its own commit and a regression with a control arm. A counted pair at level 60 shows the
   before and after.
5. If your measurement contradicts the plan's expectation, stop that fix and return with the numbers before changing
   anything further.

**What goes to the owner (status 5)**, by the same rule:
- any case where one of the four criteria fails;
- expected behaviour that no tooltip, ruling or reference decides (G-38).

Typical cases:
- the cause is in client data, not CoA code. Example: Duty Calls' MiscValue 126 leaves Physical out.
- the tooltip is ambiguous. Example: "High Threat" states no factor.
- the fix would need a shared engine edit, or would change gameplay with no independent evidence.

**What can be settled without the owner:** method, tools, proof standards, derivations from an existing ruling,
incorrect tests and older-reference cases (G-38). With a mentor session, the mentor settles them. Without one, the
working agent settles only what an existing rule or ruling decides outright, and sends the rest to the owner as a
question (section 12).

**Never** (G-2):
- change the server on our own check alone: "No server change whose only evidence is our own check" (ADR 0128);
- add CoA code that makes the test's reading pass. The Scourgebane chain was added that way in round 10 and reverted:
  the live logs show about one chained strike where a chain would give about 64 (ADR 0128, Context).

## 8. How to write an owner question

Each question carries five parts (G-4 sets the content; the recommendation is the Templar practice):
1. **the tooltip sentence, in full**, with its token values. The mentor required this for Duty Calls: "the owner
   question quotes the Duty Calls tooltip in full" (class-conformance-rulings.md Part 2.4).
2. **the measurement**: the counted pair ids, the build, the arms and their numbers, and what alerted;
3. **the cause**: the data, the code or the engine path, with file:line;
4. **the options**, each with its gameplay consequence;
5. **a recommendation**, with its reason.

State also the references searched and what they said, or "nothing found". Order the open list by the number of claims
each answer unlocks.

The Templar's owner question Q-r2a-1 shows the format (pair ids are `verify_all` run stamps, and the build is the
worldserver binary's sha256 prefix; the runs are not in the repository):

> **Q-r2a-1. Duty Calls [705286], claim 193: does "damage dealt" include Physical damage?** (1 claim part; the
> movement speed part is proven)
>
> - Tooltip (in full): "Casting abilities that grant an Oath now increases your damage dealt and movement speed by 2%
>   for 15 sec, stacking 5 times." The claim is "increases your damage dealt and movement speed by $560834s1%".
> - Measured (counted pair 20261112-013915 / -013954, build c27e2d92f32f, author r2-a), Duty Calls' buff 560834 at
>   its cap of 5 stacks against a control without it:
>   - a Holy Scourgebane 801832 hit: +10.0% (99% interval +9.99 to +10.01), ok;
>   - a Physical main-hand white swing: +0.36% and -0.32% (99% intervals about -1.3 to +2.6 points), against the
>     stated +10%: alert;
>   - movement speed: 1.0 to 1.02 after one Oath-granting Righteous Lunge, ok (claim part proven).
> - Data: Spell.dbc 560834 Effect[0] is aura 79 SPELL_AURA_MOD_DAMAGE_PERCENT_DONE with EffectMiscValue 126, the six
>   magic schools only. Physical (1) is left out. No Templar code touches 560834's effect; the cause is the client
>   data, so the mentor's fix term 3 (cause in CoA code) does not hold.
> - References: the community snapshots carry the same sentence, with no school. No video row bears on it. The
>   combat logs were not queried: they record hits, not their modifiers.
> - Options:
>   - (a) magic-only is intended. The tooltip's "damage dealt" is loose, and the claim is conformant by ruling.
>   - (b) Physical is meant too. A contract in the Templar's own code would set 560834's MiscValue to 127, which
>     changes gameplay: Physical abilities and white swings gain up to +10%.
> - Recommendation: (a), unless a live log shows Physical swings rising under Duty Calls.

The owner chose (b): "tout inclus" ("everything included"; ADR 0287). A recommendation is advice. The question must make
the other option easy to choose, as this one did.

## 9. Workflow for a new class, start to finish

The commands below are quoted from their sources. `W` is your worktree. Gameplay and source checks go through
`tools/verify_all.py` only (`.agents/rules/verification.md`). The Templar briefs call it through `coa-verify --worktree
W --ram`, which forwards its arguments to `verify_all.py`. `coa-verify`, its in-RAM MySQL route and
`coa-worktree-cleanup` are optional local tooling from the separate coa-server-guide project, not part of this
repository. They are never required: the repository-native equivalents are `tools/verify_all.py` and `git worktree
remove`. `prove` defaults to `coa-verify` (`prove.py:57`; section 13).

### 9.0 Before you start

- **First step: check for a mentor session.** The working agent's first action is to ask the developer whether a second
  agent session is set up as mentor (section 12). If there is none, it tells the developer before any other work. It
  says that the work can go ahead without one but will be less efficient, and that every doubtful case will then go to
  the owner as a question.
- **One class at a time.** Get the owner's go for the class. The Templar goal forbade starting another class.
- **A worktree and branch of your own**, created from freshly fetched `origin/main`. Follow
  `.agents/rules/git-safety.md`. Each worktree needs its own build: about 22 GB each, with a first build of about
  150-190 s.
- **A test bench slot.** These limits apply when gameplay runs share one in-RAM MySQL, as on the optional guide-tooling
  bench (`coa-verify --ram`; the in-RAM MySQL is described in `docs/coa/verification.md`).
  - At most three gameplay sets run at once (class-conformance-rulings.md Part 2.4).
  - Pass `--gameplay-db-workers 4` while others run.
  - Check the disk before each batch: `docker exec coa-test-mysql df -h /var/lib/mysql`. Above 97%, start no new
    parallel run. A run that fails for lack of space is not a verdict.

### 9.1 Class map first

The class map reads the server DBC set and the source tree, and maps every spell of all 21 CoA classes to the code that
touches it. Its documentation is `CONF/docs/class-map.md`. Run it from the repository root:

    python3 -B apps/coa-gameplay-test/conformance/class_map.py --worktree W --out OUT [--dbc-dir DIR] \
      [--log-events EVENTS.csv]

`--dbc-dir` defaults to the conformance tool's server DBC set. `--log-events` is optional: it adds event counts from
your own combat logs, in the CSV format described in `class-map.md`. The output (`OUT/class-map.json`,
`OUT/class-map-table.md`) stays out of Git. Each developer regenerates it, because the log counts come from their own
logs.

For every spell the map gives:
- `risk`: scripted, family_mask, core_script, data_row or stock;
- `gap`: unhandled, script_only, none or covered_by_code;
- `custom_mechanics`: effects of 165 and above, auras of 317 and above, modifier operations of 29 and above;
- log event counts, when `--log-events` is given.

Test where the risk is: scripted spells and custom mechanics first. `conformance.py packets --class-map
OUT/class-map.json` adds the map's fields to each packet.

### 9.2 The aura 354 check

Aura 354 is `SPELL_AURA_ASCENSION_PROC_PERCENT_EVENT` (`SpellAuraDefines.h:398`).
- The core acts on it only for 8 hard-coded spell ids, in `AuraEffect::CheckEffectProc` (`SpellAuraEffects.cpp:1316-
  1353`). `HandleAscensionPercentEventProc` (`:7283-7299`) returns early for any other id.
- Any other spell with this aura therefore does nothing unless class code takes it over.
  - The Templar does: its contracts rewrite the 354 effects as `SPELL_AURA_DUMMY`, and its event script carries the
    behaviour.
  - Other classes hook it with `OnEffectProc += AuraEffectProcFn(..., AuraType(354))`, for example
    `AscensionPrimalistSecondary.cpp:134`.

No repository command runs this check; one is future work. Steps:
1. Build the class map (9.1).
2. List the class's aura-354 spells with this read-only query. It is not a repository command:

       python3 -c "import json; d=json.load(open('OUT/class-map.json'));
       [print(s['spell'], s['name'], s['risk'], s['custom_mechanics'], s['code_hits'][:3]) for s in
       d['classes']['<id>']['spells'] if any(m.endswith(': aura 354') for m in s['custom_mechanics'])]"

3. Read each result by its `risk`:
   - **`scripted`**: class code names the spell. Check that the code really handles the 354 effect, through an
     `AuraType(354)` hook or a contract rewrite. Then prove the claim with a `triggers` entry (`trigger_count`). For "X%
     of the damage", use `kind: magnitude_ratio` (ADR 0066; the Templar model is Deliverance 704116).
   - **`stock` or `data_row`**: no class code exists, so the proc probably never fires. This is a candidate defect:
     reproduce it before any fix (`.agents/rules/defects.md`).

   Do not rely on `gap` here. The map marks a `nullptr` aura as unhandled only when no code names it, and aura 354 is
   named in code.

On a class map built from feat/coa-class-conformance bc391cd7bc on 2026-11-12, 131 spells carry aura 354 over the 21
classes, 6 of them Templar. Four have no class code:
- Tempest Calling 707615 (class 16);
- Rapid Strikes 560341 (class 21);
- Windsage 705568 (class 32, through 705569);
- Decoder 706523 (class 32).

### 9.3 Class file and reference character

Create a class file from data. `scaffold` writes a minimal `classes/<name>.json` for a CoA class (12-32) and leaves the
coverage fields empty (`CONF/docs/scaffolding.md:3-10`):

    conformance.py scaffold --class N --out FILE --config WORLDSERVER_CONF --mysql MYSQL [--dbc-dir DIR] [--level N]

Measure the reference stats with a naked scenario (`CONF/docs/scaffolding.md:43-51`):

    python3 -c "import json, scaffold; cf = json.load(open('FILE')); \
      json.dump(scaffold.naked_scenario(cf), open('NAKED.json', 'w'), indent=2)"
    python -B ../../../tools/verify_all.py --stages gameplay --scenario NAKED.json
    python3 -c "import json, scaffold; cf = json.load(open('FILE')); \
      result = json.load(open('.cache/verify-all/STAMP/gameplay/exploratory/<key>/result.json')); \
      cf['reference_stats'] = scaffold.reference_stats_from_result(result, cf); \
      json.dump(cf, open('FILE', 'w'), indent=2)"

### 9.4 The clause ledger

The ledger is `classes/<name>_clauses.json`: a JSON array of `{spell, clause, labels, kind}` entries, with optional
`claims`, `tool_gap`, `text_source`, `no_behaviour_route` and `effectiveness_of` (`LEDGER:7-47`).
- `kind` is `claim` or `no_claim`. A `no_claim` row comes only from the initial generation or an owner ruling
  (`LEDGER:88-92`).
- Other workstreams never edit the ledger directly. They write a fragment, and the integrator merges it by `(spell,
  clause)` (`LEDGER:73-92`).

**No repository tool builds a class's first ledger.** This is future work.
- The Templar ledger was added once, in commit e32d5308b5 (2026-11-09), from a round 10 clause audit of 450 rows that
  agents wrote. ADR 0052 calls it "generated once"; the conversion step was never committed. The commit adds the ledger
  and no generator.
- In that audit, agents split each tooltip into rows, batch by batch. The script that prepared the batches, the written
  splitting instructions and the merge into one file were never committed.
- ADR 0052 gives the target shape: one entry per audit row, with `kind` `claim` or `no_claim`, and the audit's own note
  as `reason`. The document it cites, `docs/ledger-format.md`, was never committed; ADR 0302 points to this section
  and to `LEDGER` instead.
- Since then, rows change only by merged fragments and by owner rulings. At b6529634cb and at bc391cd7bc the ledger
  held 452 entries: 435 claims and 17 `no_claim`. ADR 0052's 450 rows (434 claims, 16 `no_claim`) are the ledger as
  e32d5308b5 added it.

**Ledger fields** (`LEDGER`, "File format"):
- `spell`, `clause` (the exact tooltip words) and `kind` (`claim` or `no_claim`);
- `labels`: the verdict labels that prove the clause. A label without ` #n` stands for every ` #n` occurrence;
- `reason`: required on `no_claim`. On a claim it may record the ruling or evidence the proof relies on;
- `claims`: at least two `{claim, labels}`, used instead of `labels` (ADR 0123);
- `tool_gap` and `no_behaviour_route`: `{reason, attempts[{agent, report}]}`. A tool gap may also carry an
  `owner_acceptance` (ADR 0127, ADR 0136);
- `text_source`: the `coa_client_spell_description` row, with `spell, file, commit, pr, basis, ruling, dbc_differs`.
  `dbc_clause` keeps the DBC words when the streamed text changed them (ADR 0192, ADR 0198);
- `effectiveness_of`: the spell id of X in a clause "the effectiveness of X" (ADR 0268).

**Splitting tooltips into claims.** No written rule set exists. The rules below are the ones the Templar ledger and
`coverage.py` apply. Write a new class's ledger by them.
- **Sentence to clauses.** A sentence is cut where a part carries its own effect or value. Each clause is one row with
  the exact tooltip words. The cut is not fully regular.
  - Absolution, "Taunt all enemies within 8 yds for $d and increase your movement speed by $520659s1% for $520659d.",
    gives three rows: "Taunt all enemies within 8 yds", "for $d" and "increase your movement speed by $520659s1% for
    $520659d".
  - Rows can overlap: Sacred Defense 705306 has the whole sentence, with `claims`, and its second half as a separate
    row.
- **Stated claims** (`LEDGER`, "Stated claims"; ADR 0123).
  - A clause states one claim per value it gives: magnitude, duration, stacks, radius, period, chance, count, or a
    literal such as "8 yds".
  - It also states one claim per quantity that one value moves through a separate effect.
  - It closes only when every claim is proven. When its labels measure only some claims, the entry declares `claims`.
    Example: Absolution's "Taunt all enemies within 8 yds" declares "Taunt all enemies" and "within 8 yds", each with
    its own labels.
  - `coverage.stated_values` counts the `${...}` formulas, the `$` tokens other than d/a/r, and the literal numbers.
- **`no_claim`.** A row carries no mechanic. Only the first generation or an owner ruling sets it. The 17 Templar rows
  are:
  - 14 level labels, for example "Level 20 Passive", each with a reason such as "A level-availability label, carries no
    gameplay claim to verify." or "Label line, not a gameplay claim.";
  - one empty tooltip (Shoot 3018);
  - one acquisition note (Tithe 804781);
  - one owner ruling: Righteous Tempest's tick 805410. Its Description is not the governing text (ADR 0104), and the
    spellbook clause carries the value.
- **Streamed text** (G-34 to G-36; ADR 0192, ADR 0198).
  - `streamed.py` replays `coa_client_spell_description` from `data/sql/updates/{db_world,pending_db_world}/*.sql`.
  - When a spell has a streamed row, its clauses use the streamed words, and every entry must carry `text_source`.
    Otherwise coverage stops with `EvidenceError`.
  - A clause with `dbc_clause` counts only when the basis is `owner_ruling` or `live_source`, or `text_correction` with
    identical figures. Any other such clause counts as unproven.
- **Tokens to labels** (`values.py`; `#n` is the token's position in the tooltip, counted from 0):
  - `$s1` and `$m1` give `<rank> effect_value e<i> #n`, plus `aura_amount e<i>` for an aura;
  - `$<id>s1` gives `<rank> effect_value <id>e<i> #n`;
  - `$d` gives `<rank> aura_duration_ms #n`, and `$<id>d` gives `<rank> spell_duration <id> #n`;
  - `$u` gives `max_stacks`, `$a` gives `effect_radius`, and `$t` gives `aura_amplitude_ms`;
  - `${...}` gives `effect_value ... #n`, read with the measured stats.

  A `$h` chance cannot be measured as a value. Behaviour and prose claims cite the labels of class-file entries instead,
  such as `<spell> trigger_count`, `<spell> proc_rate` or `<spell> behaviour_<kind> <part>`.
- **Split by part** (G-21, points 3 and 4). A stat read never proves a damage or healing part, so a clause with both is
  split by part. A mixed entry counts as data (ADR 0131). Read the subject together with the rulings: G-13 makes "Holy
  spell damage" a spell-power stat claim.

The five final statuses of section 2 have no field in the ledger. The Templar tracked them outside the repository
(section 13).

### 9.5 Generate, run, compare

From `CONF` (`CONF/README.md:28-37`):

    python3 -B conformance.py generate --class 19 --out $W/.cache/conformance/templar
    python3 -B conformance.py generate --class 19 --stack --out $W/.cache/conformance/templar/stack
    python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/scenarios/*.json
    python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/stack/scenarios/*.json
    python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/manifest.json \
      --results $W/.cache/verify-all/STAMP --out OUT
    python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/stack/manifest.json \
      --results $W/.cache/verify-all/STACK_STAMP --out OUT/stack

Use your class id in place of 19.
- These runs end `INCOMPLETE` by design: exploratory scenarios leave the gameplay stage `unavailable` even when every
  scenario passes (`CONF/README.md:39-40`). Only `PASSED` is a passing `verify_all`, so these runs are verdict evidence,
  not a pass.
- `generate` refuses a DBC set whose Spell.dbc sha256 differs from the server set's (`G&C:29-32`).
- `compare --build` refuses runs of another build (`G&C:40-46`).
- `generate` also takes `--behaviour`, `--target-gate` and `--learned-hit` to select class-file entries
  (`conformance.py:662-669`).

Coverage against the ledger (`LEDGER:238-239`):

    python conformance.py coverage --before <dir> --after <dir> --clauses classes/templar_clauses.json

### 9.6 Batches

Sample a batch by script, with no agent judgement. The unit is the spell (`G&C:364-377`):

    python3 -B conformance.py sample --buckets BUCKETS.json --seed SEED --total 40 --bucket U --bucket D --bucket A \
      --minimum A=4 --first-chunk 10 --out SAMPLE.json

Build one packet per spell before the author starts (class-conformance-rulings.md Part 2.4, batch protocol;
`G&C:382-402`). A packet holds:
- the tooltip with its token values;
- the Spell.dbc fields;
- the script hits;
- the bucket rows and the class-file entries;
- the nearest entry of each check kind;
- the fixtures;
- the class map fields.

The command:

    python3 -B conformance.py packets --class 19 --sample SAMPLE.json --chunk 2 --buckets BUCKETS.json \
      --class-map CLASS-MAP.json --out PACKETS/

**The bucket file is built by scripts that are not in the repository.** This is future work. The Templar used two
uncommitted, Templar-only scripts with hard-coded paths and no arguments:
- a coverage audit, which runs `coverage.clause_coverage` on the ledger with merged verdicts;
- a bucket builder.

The bucket file is a JSON array of rows, one per ledger claim. Its readers on the branch read these fields:

| Field | Type | Required by | Meaning |
|---|---|---|---|
| `spell` | integer | `sample` (`sample.load_buckets`), `packets` | The ledger row's spell |
| `bucket` | string | `sample`, `packets` | `A`, `U`, `D` or `out_of_scope` (below) |
| `index` | integer | `packets` (`ledger_rows`, `packets.py:185`; a missing `index` raises KeyError) | The claim's position in the ledger; the sample's chunks name rows by it |
| `clause` | string | `packets` (packet text) | The ledger clause |
| `labels` | list of strings | `packets` (optional; `row.get('labels', [])`) | The ledger labels, used to find the nearest check kinds |
| `script_touch_hits` | object `{hit_id: {"id": [...], "family": [...]}}` | `packets` (optional; `packets.py:205`) | Class-code hits by id and by family mask |
| `evidence`, `token_kind`, `script_touch`, `readable_token`, `label_statuses` | as below | `packets` (optional, printed only) | Context for the author |

What the Templar's builder wrote into them:
- **`bucket`**:
  - `A` when a standing alert applies: an alert label, an uncited alert verdict that quotes the clause, or an unsettled
    alert;
  - otherwise `out_of_scope` when the clause is behaviour proven, `U` when it is unproven and `D` when it is data
    conformant;
  - `A` wins over `D` and over behaviour proven.
- **`evidence`**: `behaviour`, `data` or `unproven`, from `coverage.clause_coverage`.
- **`token_kind`**: from the clause's `$` tokens, by letter.
  - s/m/w/b/e value, d duration, h chance, o periodic_total, t period, a radius, r range, u stacks, x/i/n count;
  - `${` formula, `$<` variable.

  Kinds are sorted and joined by `+`; `literal` is added for a number outside a token, and a clause with neither is
  `prose`.
- **`script_touch`** and **`script_touch_hits`**: matches in the class code, by id or by family mask; the first is the
  flag, the second the hits in the shape above.

The order of commands on the Templar was scaffold, generate and compare (9.3, 9.5), the ledger (9.4), the two scripts
above, then `sample` and `packets` (this section).

Batch sizes used on the Templar:
- batch 1: about 40 clauses, with a first chunk of 10;
- chunk 2: 32 clauses;
- the two-author trial: 60 clauses, 30 per specialization.

Roles:

| Role | Model used | Scope |
|---|---|---|
| Author | Opus | One continuing author per batch or side, from the packets. Writes the class-file entries, makes the counted pair, runs the source stage once, triages its own alerts, keeps a progress file after each spell |
| Route agent | Opus | Only on clauses the author reports as "no behaviour route": the independent second attempt that status 3 requires |
| Review | Opus, high effort | Independent. Gets the diff, the verdicts and the packets, but not the author's report or triage |
| Fixes | The author, continued | Fixes the review's Critical and Important findings |
| Integrate | Sonnet | Copies the verdicts out, merges, checks the regeneration identity, builds, runs source, recomputes coverage |

Rules for a batch:
- Message an author only after it returns, never while it runs.
- Authors write their questions in the progress file and carry on with another clause. The controller batches the
  questions: with a mentor session, to the mentor; without one, the working agent applies section 7 and sends the rest
  to the owner in the section 8 format.
- Fix notes go the same way, before any build: with a mentor, to the mentor; without one, the four criteria of section 7
  are applied strictly and anything in doubt goes to the owner.
- Agents never wait in the background. The progress file carries a timestamp after each spell, and the controller
  watches it.

When two authors work in parallel:
- data files are partitioned by spell;
- tool, test, doc, ADR and harness files go through a lock file and cherry-picks;
- ADR numbers are reserved in blocks per author.

Each batch sets a stop rule before it starts, in minutes per resolved clause.

To prove chosen entries deterministically and write a ledger fragment (`G&C:257-315`):

    python3 -B conformance.py prove --class 19 [--behaviour SPELL ...] [--proc AURA ...] [--trigger AURA ...] \
        --out DIR --worktree W [--runs 2] [--build] [--timeout-ms 600000] [--clauses LEDGER]

Exit codes: 0 no flip, 1 a flip, 2 scenario drift, 3 a scenario without result, 4 a failed run.

### 9.7 Tool gaps and extensions

When the tool cannot express a claim, extend it:
- the smallest extension;
- seeded tests;
- a mutant that must alert (server mutants: `conformance.py mutate`, `k3`, ADR 0129);
- every existing scenario regenerating byte-identical;
- a one-off clock line.

A tool extension needs no prior approval and is reported in the batch report. A harness C++ change beyond reading and
recording needs a note first (G-39): to the mentor, or without one to the owner. A gap becomes status 5 only after two
different designs have failed, or when one claim would cost more than 90 agent-minutes.

A new check or metric needs a row in the closed evidence tables first (`coverage.EVIDENCE`, `METRIC_EVIDENCE`, ADR
0120). Without the row the coverage run fails.

### 9.8 Review and integration

Integration steps, in order:
1. Copy the counted verdict files, run reports and manifests out of each worktree's `.cache`, before anything is
   removed.
2. Merge: fast-forward the first branch, rebase the second, and resolve conflicts only by the ownership rules.
3. **Regeneration identity check**: `conformance.py generate --class N` at the merged HEAD. Each side's counted
   scenarios must come out byte-identical; re-run any that differ, twice.
4. Run `python -B tools/verify_all.py --stages build`, then `--stages source --base origin/main`, once each. With the
   optional guide tooling, the Templar ran them as `coa-verify --worktree <wt> --ram --stages ...`.
5. Recompute coverage on the merged ledger with the stored verdicts.
6. Compute the clock.
7. Remove the worktree with `git worktree remove <wt>`, without force, and keep the branches. With the optional guide
   tooling, `coa-worktree-cleanup <wt>` prints its plan first and acts only with `--yes`
   (`references/guide-tooling.md:128`).

Before a PR, `python -B tools/verify_all.py --stages source --base origin/main` (`CONF/README.md:94`). Run the codestyle
linters on changed C++ and SQL files. SQL goes only under `data/sql/updates/pending_db_*/`.

### 9.9 Finishing

Write the class report. The Templar's sections were:
- coverage by final status;
- the server fixes with their evidence;
- every open owner question;
- the tool gaps;
- the cost by batch;
- what could not be verified.

Publication (push, PR) needs the owner's go.

## 10. Measured costs

All figures were measured on the Templar: section 10.1 from its cost totals, 10.2 from its batch clock and integration
reports, and 10.3-10.4 from its cost profile and timing analyses, all computed from session transcripts and run reports.
Those working records are not in the repository. Estimates are not quoted. A "resolved claim" is one the integrator's
recount moved to a final state. The authors' own counts were higher (R2: 51 against 42; R3 side b: 24 against 8), so
quote the recount and say so.

### 10.1 Whole Templar effort

| Figure | Value |
|---|---|
| Elapsed span | 163.1 h (2026-11-05 to 11-12) |
| Active hours, all sessions | 121.5 h |
| Agent-hours (sum of subagent transcript spans) | 236.3 h over 798 transcripts |
| Input tokens | 12,492.5 M, of which 12,283.1 M cache reads |
| Output tokens | 45.06 M |
| The final goal run alone (2026-11-11 20:50 to 11-12 09:13) | 40.25 agent-h, 2,448.5 M input, 6.75 M output, plus the controller's 8.4 h |

The dollar cost is known only up to 2026-11-09. Much of the 163 h went into methods that were replaced. Section 10.2 is
the useful planning figure.

### 10.2 Per claim, by method

Measured like for like:

| | Round 10 (stateless workflow steps, Sonnet) | Lean batches R1-R3 (continuing authors, Opus) |
|---|---|---|
| Agent-minutes per resolved claim | 16.8 to 29.8 | 7.76 / 8.75 / 10.22 (8.68 overall) |
| Wall-minutes per resolved claim | 4.63 to 9.72 | 3.64 / 4.92 / 5.23 |
| Input tokens per resolved claim | 17.7 to 35.7 M | 9.6 to 11.8 M |
| Output tokens per resolved claim | 55k to 99k | 22k to 27k |

The comparison is not exact. The models differ. The unit differs too: a clause proven against a recomputed status-1
claim. Round 10 counts step agents only, while R1-R3 include review and integration.

Wall time per resolved claim for each lean batch:

| Batch | Clauses | Wall-minutes per resolved claim |
|---|---|---|
| Chunk 1 | 10, 6 resolved | 12.5 min |
| Chunk 2 | 32, 25 resolved | 6.26 min |
| Gap batch | 6 gap spells, 11 resolved | 10.1 min |
| Two-author trial | 60, 52 resolved | 4.11 min |
| R1 | two authors, 54 resolved | 3.64 min |
| R2 | two authors, 42 resolved | 4.92 min |
| R3 | two authors, 30 resolved | 5.23 min |

- **Fixed cost per class**: the preparation step took 26.4 min wall and 100.6k output tokens.
- **Two authors** gave a 1.69 to 1.92 speed-up.
- **Merge and conflict time** of two authors was 6 to 31 min per batch. That is 1.4% to 11.7% of the authoring phase,
  under the 20% gate.

### 10.3 Per stage

- **Gameplay run**: median about 30 s for 1 to 11 scenarios. A fit gives 33.4 s plus 0.24 s per scenario, so start-up
  dominates. Batch your scenarios: 66 in one run took 52 s, against about 32 min as 66 runs.
- **Build**: an incremental build takes 25-31 s; the first build in a new worktree 148-186 s.
- **Source stage**: 330 s before its speed-up and 38-42 s after. In rounds 1-4 it ran 42-62 times a round, 14.35 h in
  all, the largest verify cost. In round 10, 35% of source runs failed, mostly on style and comment rules. Run it once
  per item, after the last edit.

### 10.4 What drove the cost

As the reports state it:
1. **Re-reading the code in every stateless step.** This took 45% of step time and 58% of input tokens in round 10.
   Continuing authors that keep their context through triage and fixes replaced stateless steps
   (class-conformance-rulings.md Part 2.4, batch protocol).
2. **Fixed cost per step, not per clause.** Step time did not correlate with clauses proven (r = -0.07 over 54 steps). 9
   steps proved nothing and took 20% of step time.
3. **New check kinds.** Each costs a full step: code, seeded test, ADR, docs, two runs and a source stage. The batches
   that needed new kinds cost more per clause: the gap batch 10.1 min and the mech batch 16.13 min, against chunk 2's
   6.26.
4. **Poll loops and background waits** in the early rounds: 16.0 h over rounds 1-4.
5. **Shared bench limits.** In round 10 the in-RAM MySQL disk filled and blocked three steps for 63 agent-minutes.

## 11. Lessons that cost time

Each lesson gives the incident, what it cost where recorded, and the rule now in force. Unless an ADR is named, the
source is the Templar's working records, which are not in the repository.

1. **Code readings overturned by measurement.**
   - A tool-gap pass concluded by reading `Unit::SpellDamageBonusDone` that Divine Charge's trample had "no second
     term". The measurement read 171.6 / 172.1 per hit against 127.2 for the stated formula: the attack power and spell
     power terms were added twice, in the CoA hook layer (fixed by ADR 0209).
   - The same double count, found by hits, affected Armor of Faith (ADR 0162) and Lightkeeper (ADR 0164).
   - Rule: a conclusion that rests on code reading alone is listed as such in the report. If a measurement contradicts
     the plan's expectation, stop and return with the numbers.
2. **"Not in game" assumed without evidence.**
   - An author reported "3 of 5 Librams in game" with no evidence. The premise was relayed up and repeated in a ruling
     and a brief, and a claim part was marked "not measured in game".
   - A reach audit found no table, code path or reference behind it. Both Librams (Tenacity, Consecration) are
     obtainable, and the claim ended behaviour proven with all five.
   - Similar errors: the "no path" for the Templar's off hand (Dual Wield is granted at login), and Blessed Padding
     "unreachable" (a level-60 item satisfies it).
   - Rule: G-12. Never relay an unsourced "not in game" as a premise.
3. **Harness-set auras as the subject.**
   - Claims 139 and 140 (Righteous Custodian) and later 218 (Eternal Blessing) and 193 (Duty Calls) were "proven" with
     the claim's own aura placed by `set_aura`, while a real cast was available.
   - An audit of 52 stat-read claims found 9 that failed the amended rule 4 (ADR 0263 records 139 and 140).
   - The status-5 review rebuilt 218 and 193 on a real cast and a learned talent (ADR 0286, ADR 0287).
   - Rule: G-21, point 6.
4. **Radius proofs with the outside target too far.**
   - Round 10 proved Absolution's "within 8 yds" with an outside dummy moved to 20 yd, "comfortably past any plausible
     padding". That arm proves only "not at 20 yd".
   - The real edge is 11.85-12.10 yd. Finding it took a review, a radius batch of 58.7 min wall and an owner question.
   - Rule: bracket the edge just inside and just outside, read the geometry before the cast, give the arithmetic per
     mechanism, and run a stock-spell control.
5. **Ledger labels the tool did not count.**
   - In R2 the authors counted 51 resolved claims and coverage 42. In R3 side b, 24 against 8.
   - Causes:
     - a label resolving to a `not_measured` or `unmodelled` verdict;
     - a label renamed after a fix, so the new label never ran in a counted set;
     - a scenario name or a stray status word used as a label;
     - a stat gain without its contrast stamp.
   - It cost two label passes (59.1 and 25.1 min wall).
   - Rule: the integrator recomputes coverage from the verdicts and the ledger, and never copies an author's tally.
6. **Two authors on locked files.**
   - One side committed under the other side's lock.
   - A helper with the same name shadowed an older one and broke eight tests.
   - Conflict markers were committed into `test_behaviours.py`.
   - ADR numbers collided.
   - The integrator redid its cherry-picks twice because of count lines.

   Rule: ADR blocks reserved per author before launch; a lock file for shared tool files; each fix branch owns its own
   C++ file; the entry-count line is checked at every commit.
7. **Coin-flip tests.**
   - A High General damage test failed on a correct server: with 8 casts per arm and the dummy's partial resists
     uncontrolled, a correct server misses the band about 31% of the time (ADR 0154, Context).
   - Two status-5 regressions were strengthened so that the old code would pass a run with probability 0.3% and 5.4%
     (ADR 0294).
   - Rule: state the probability that a correct server fails and that the old code passes. Remove the random source, or
     size the trials.
8. **Alerts that were not defects.** Several alerts were wrong tests:
   - a fixture cast a spell the scenario never learned;
   - Energy was set to exactly a channel's cost;
   - a `$m1` was read without its per-level part.

   Each cost a triage step, up to 17.6 min. Rule: G-3 and section 7, steps 1-2.
9. **Verdicts lost with a worktree.** The gap batch's stored verdicts lived only in its worktree. 19 scenarios were
   re-run twice, and three are unrecoverable. Rule: copy the counted verdicts out before any merge or cleanup (section
   9.8, step 1).
10. **Shared bench limits.**
    - A fourth gameplay agent was launched while three sets ran. It was stopped before any run.
    - The tmpfs filled in round 10.
    - The test MySQL allows 16,382 prepared statements, against the 65,528 its documentation states; a third server
      at 16 workers fails.
    - Rule: at most three sets, `--gameplay-db-workers 4`, a disk check before each run, and a slots list (kept by
      whoever runs the parallel sets; no tool in the repository) checked before every launch.
11. **Source stage against an unfetched base.** `origin/main` was not fetched during the final goal, so "source PASSED"
    meant passed against a stale ref; the branch lacked 44 of its commits. Rule: fetch and record the base when
    qualification starts (`.agents/rules/verification.md`).
12. **A server change made to satisfy our own check.** A Scourgebane strike chain was added so a check would pass. Live
    logs show about one chained strike where a chain would give about 64, and it was reverted (ADR 0128). Rule: G-2.

## 12. The mentor's brief

The owner's decision of 2026-11-12: "il faut que le développeur dédie un autre agent à cela et il faut le prévenir si
cela manque. il doit pouvoir faire sans cela dit, ce n'est pas obligatoire, juste moins efficace." ("The developer
should dedicate another agent to it, and must be warned if it is missing. They must be able to work without it, though:
it is not mandatory, just less efficient.")

The work uses two agent sessions per developer:
- **the working agent** does the hands-on work: packets, class-file entries, scenarios, runs, triage, fix notes, fixes
  and reports;
- **the mentor** is a second, separate session. It answers method, tool and proof questions, and reviews the plans, fix
  notes and results.

**Without a mentor**, the work still goes ahead, but less efficiently:
- the working agent tells the developer at the start (section 9.0);
- it applies the four fix criteria strictly (section 7);
- it settles only what an existing rule or ruling decides outright;
- it sends every doubtful case to the owner as a question in the section 8 format.

The brief below can open a mentor session. Replace `<class>`.

> You are the mentor for the class conformance work on `<class>`. Another agent session does the hands-on work; you
> do not. Read `docs/coa/class-conformance.md` and `docs/coa/class-conformance-rulings.md` first.
>
> **You decide:**
> - questions of method, tools and proof standards: whether a verdict meets sections 3 and 5 of the guide;
> - derivations from an existing ruling;
> - incorrect tests;
> - older-reference cases (G-9);
> - whether a tool extension's design is sound. Extensions need no prior approval, but a harness C++ change beyond
>   reading and recording needs a note to you first (G-39);
> - whether a fix note meets all four criteria of G-37: an unambiguous expectation, a contradicting measurement, a
>   cause in CoA code, and a change in the class's own code. If it does, approve it; if not, turn it into an owner
>   question.
>
> You also review the working agent's batch plans, fix notes and results.
>
> **You never decide; these are the owner's:**
> - expected game behaviour that no tooltip, ruling or reference decides (G-38);
> - a server fix when any of the four criteria is in doubt;
> - a server change whose only evidence is our own check (G-2);
> - the budget: time caps, parallel agents, test bench limits;
> - publication: a push, a PR, a write to the Knowledge MCP.
>
> Send these to the owner as questions in the guide's section 8 format, with a recommendation.
>
> **Record** each decision you make with its date, so it can be added to the rulings page. The owner can overturn any
> of your decisions.

Sources:
- G-37 to G-39, and G-2.
- The budget and publication limits follow the Templar goal: the owner set the time cap, kept pushes and PRs for
  themself, and decided the number of parallel authors. The three-set limit was a mentor rule; the database and disk
  limits await the owner (section 13).
- The Knowledge MCP write rule is in `.agents/skills/coa-development/references/knowledge-mcp.md`.

## 13. Known limits and open points

- **The tool has only run on the Templar.** The generation from data (spell set, tooltip reading, value, passive and hit
  scenarios) is written to be class-agnostic. The behaviour, trigger and proc entries are hand-written per spell.
  - Of the 64 behaviour kinds in `classes/templar.json`, 35 have a single entry.
  - The Python names one Templar spell id, `DEFAULT_CHAIN_AURA` (Oath Chain), which an entry can override.
  - The tests are Templar fixtures.
  - Expect to add check kinds; they cost the most per claim (section 10.4).
- **Not included, future work:**
  - a generator for a class's first ledger (9.4): the Templar ledger came from an agent audit, converted by an
    uncommitted step;
  - the bucket builder (9.6);
  - a command for the aura 354 check (9.2). The query given there is not a repository command.
- **The final statuses 2, 4 and 5** have no field in the ledger or in `coverage.py`. The Templar recorded them outside
  the repository.
- **`prove` calls the `coa-verify` wrapper** from the optional guide tooling by default (`prove.py:57`), with no option
  for another runner. Without that tooling it cannot run as documented; run the scenarios twice through
  `tools/verify_all.py` and judge each run with `compare` (`G&C`, prove runner).
- **Open tool defects:**
  - `effectiveness_of` is not cross-checked against the buff's name (ADR 0268, "Not checked");
  - coverage accepts a `learned` stat_gain verdict without its attribution reads;
  - `load_clauses` does not refuse duplicate `(spell, clause)` rows;
  - one Templar trigger scenario (804930) is flaky, with 1 failure in 4 runs;
  - about 115 Templar status-1 parts rest on verdicts with no pair stamp.
- **Levels.** Production is capped at 60, but the dev servers and the harness still run at 80, and fixtures default to
  level 80 (section 6). The migration is parked.
- **Rulings of open scope.** Several rulings were given on Templar cases but are worded generally. Until the owner says
  otherwise, treat them as Templar precedent and ask before relying on them:
  - G-7 (coefficients);
  - G-30 (truncated counts);
  - "N in all";
  - "all enemies";
  - "High Threat" x2.
- **The test bench limits** await an owner decision: `max_prepared_stmt_count` is 16,382 against the documented 65,528,
  and the tmpfs is 12 GB.
- **Costs may not transfer.** The Templar figures (section 10) include the tool kinds built for the Templar.
- **The harness in production builds.** The gameplay-test harness is compiled into every worldserver:
  - `src/server/coa/CMakeLists.txt` collects all of `src/server/coa` into the `coa` library that worldserver links.
  - At runtime it is inert unless `CoAGameplayTest.Enable` is set; the default is false (`CoAGameplayTest::OnStartup`).
  - With the gate off, its script hooks stay registered and return early.
  - No chat command script is registered; opcode constants are used only to observe packets (no handler was traced).
