# Spell and quest mechanic maps

An agent-facing map links data, interpreted behavior, execution and verification without keeping a second
copy of the spell/quest database. This phase covers spells and quests only.

## Retrieve a map

Requires Python 3.11+, with no new packages or build. Commands work from the repository root:

```sh
python apps/coa-dbc/coa-dbc-viewer map --data env/dist/data/dbc --id 1257670
python apps/coa-dbc/coa-dbc-viewer record --data env/dist/data/dbc --id 1257670 --with-map --field 'Effect*'
python apps/coa-mechanics/mechanic_map.py list
python apps/coa-mechanics/mechanic_map.py show feature:quests
python apps/coa-mechanics/mechanic_map.py show quest:4004 --sql out/world-metadata.json
python apps/coa-gameplay-test/catalog.py --quest 4004
python apps/coa-gameplay-test/workflow.py --quest 4004
```

`ability:ID` and `quest:ID` work without an authored entry. Unreviewed paths and missing evidence remain explicit.
The two aggregate maps, `feature:quests` and `feature:spell-acquisition`, describe shared paths in this scope.
The DBC command also exposes `/api/map?id=1257670` through its optional local HTTP service.
Successful commands return JSON; errors return nonzero with JSON on stderr (argument syntax uses argparse).

Add current database evidence with the existing read-only capture tool:

```sh
python apps/coa-dbc/capture_sql.py --config path/to/worldserver.conf --mysql path/to/mysql \
  --spell 116 --spell 1257670 --quest 7 --quest 4004 --output out/world-metadata.json
python apps/coa-mechanics/mechanic_map.py show ability:116 --data env/dist/data/dbc \
  --sql out/world-metadata.json --details
python apps/coa-dbc/coa-dbc-viewer map --data env/dist/data/dbc --id 1257670 \
  --observations .cache/coa-gameplay-tests/RUN
```

Create the output parent directory first. Captures use sequential SELECTs against the configured local world DB,
not the character DB. No source database or installed game data is modified. Quest captures contain the requested
templates/addons, dialogue, and creature/gameobject starter/ender relations. Follow-up quest IDs are links, not
automatically captured rows. Conditions, SmartAI, item starters and character quest state need further inspection.

## Reading the result

| Area | Derived facts | Interpretation still required |
| --- | --- | --- |
| Spell ranks | SQL chain, DBC groups, row presence | Character eligibility and loader filtering |
| Acquisition | Entry, class/tab, costs, prerequisites | Automatic grants, choices, scripts and character state |
| Expected behavior | Client description and scenario contract | Independent expectation and conflicting evidence |
| Execution | Raw native dispatch and SQL bindings | Hooks, corrections and final result path |
| Quest | Prerequisites, objectives, rewards, givers | Custom paths, conditions, scaling and reward delivery |
| Verification | Scenario IDs, metrics, assertions, checks | Relevance, execution and coverage |

Compact output previews up to three contracts and marks truncated text and additional contracts explicitly.
`--details` returns all contracts, metrics/check bindings and descriptions for every discovered rank.
Different rank groups are preserved separately; they are never silently merged into one authoritative active chain.
Scenario discovery follows related rank IDs and preserves namespaces: quest 7 does not match spell 7.
Use the scenario's actions/metrics to distinguish testing the requested behavior from using the spell as a control.

The seeded examples trace Replenishment's load-time aura correction and periodic power calculation, plus
quest 4004's Wisdomball acquisition exception. Generic quests also link the ordinary acceptance/reward path.
Attached observations are historical and keep their executable identity; map generation does not run or reverify them.

## Maintain only interpretation

Add a short entry to `entries.json` when an investigation needs an explanation that data cannot establish:

- Use a stable `ability:ID` or `quest:ID`, a scoped summary, ordered execution stages, and unresolved gaps.
- Link sources by repository path and a unique literal anchor. Store the reviewed file's SHA-256 only after
  inspecting that path; use `hashlib.sha256(Path(path).read_bytes()).hexdigest()` to calculate it.
- Prefer derived DBC/SQL IDs and scenario contracts. Add explicit scenario links only for relationships that
  cannot be discovered from typed scenario entities. Do not copy ranks, quest rows or scenario expectations here.
- A changed source hash marks interpretation `needs-review`; a moved anchor gets its new line automatically.
  Missing/ambiguous anchors fail the reference check. Refresh a hash after review, not merely to clear a warning.
- `source-present` describes code presence. It does not mean the mechanic, client UI or current deployment passed.

```sh
python apps/coa-mechanics/mechanic_map.py check
python -B apps/coa-mechanics/test_mechanic_map.py
```

CI checks reference integrity and tests the joins. Source changes produce review flags rather than blocking
unrelated edits to large shared files. No build, runtime run or deployment is part of map generation.
