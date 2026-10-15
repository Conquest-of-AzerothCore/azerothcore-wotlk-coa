# Compatibility release history — 2026-09-09

This page summarizes the recorded September 9 integrations. Validation results
refer to those releases; gameplay, movement and rendered UI acceptance remain
separate from source checks, a linked build and server readiness.

## Class follow-up release

The class follow-up integrated the [Necromancer Life Force/model/UI correction](necromancer-followup.md),
[Templar](templar-completion.md), [Felsworn](felsworn-completion.md),
[Starcaller](starcaller-completion.md) and [Knight of Xoroth](knight-of-xoroth-completion.md)
with the earlier class packages.

Core checkpoint `46bf8121e52c42796e72a400a8ec80dfe14e3c7c` was followed by
startup corrections `057e9fcbe1a248074f04ec60b8d68174af51fd5b` and
`12d2cda4d7c8ad59e4da5a1fc0850fecff91f665`. The normal updater applied world
SQL03 through SQL10. Applied migrations, including earlier SQL00/01/02, are
immutable; later corrections require new migrations.

Initial startup exposed invalid periodic AuraScript registrations, three inert
aura bindings, two proc disable masks and a mismatched raid group. Native tests
and new SQL09/10 corrected these without rewriting applied SQL03–08. SQL10 groups
Shrouded Stars' damage-taken reduction with Sanctuary/Vigilance in 2000185 while
preserving its independent stagger. The successful results below apply to the
corrected source after the initial startup and fixture failures.

The integration required the matching two-member Necromancer/Templar client
overlay. The other 1,400 archive members, server Spell.dbc, three existing model
DBCs, the T archive, client EXE/DLL, cache, WTF and original client were preserved.

Recorded validation:

- A VS2022 x64 RelWithDebInfo linked build and final server readiness passed.
- Final startup reported zero new unique errors.
- All planned SQL rows and protected personal data matched the checked baseline.
  Native uptime, outdoor respawn, Wintergrasp and daily reset state advanced;
  those operational changes were reviewed separately from personal data.
- All 22 selected creature model chains and 13 gameobject dependencies resolved.
- Client gameplay, summon appearance and rendered Life Force/Oath UI remained
  untested in this integration.

## Source validation before the class follow-up release

These results describe the earlier source checks, before the integration above:

- Starcaller: 164 finding dispositions, 124 coefficient slots, 99 bindings and
  35 proc rows in SQL06. The combined follow-up recorded 27 focused tests,
  73 unchanged regressions, 80 native cost cases and 12 native syntax units.
  New SQL/C++ lint passed.
- SQL08 corrected 64 Felsworn/Knight proc hit masks to include native block,
  absorb and full block. A 24,948-case native test superseded the earlier
  six-low-bit admission test, which had missed those outcomes.
- Knight of Xoroth: 122 implemented/extended and two retained dispositions,
  65 coefficient slots, 113 bindings and 26 proc entries in SQL07. Its 96
  guarded template/model/pet-level/forge inserts required conflict checks.
  Validation recorded 21 focused tests, 52 regressions, 2,808 native proc
  cases, 80 Sever forwarding cases and 12 native syntax units.
- Necromancer: duplicate native summons were suppressed, Life Force admission
  was enforced per paid minion, and capacity growth matched the resource UI.
  SQL03 scaled 11 summon templates.
- Templar: all 25 findings had dispositions, including Oaths, stagger, finite
  charges/replacements, 113 coefficient slots, proc routing and owned summons.
  SQL04 supplied 86 bindings, 32 proc entries and guarded Hope definitions.

Felsworn SQL05 and Knight SQL07 use native models without a client/DBC addition.
The Necromancer/Templar changes require matching source and client UI. Future
integrations must reject conflicting Hope definitions and preserve that dependency.

## Earlier Necromancer completion release

This earlier September 9 integration installed
[Witch Doctor](witch-doctor-completion.md), [Necromancer](necromancer-completion.md),
the [Witch Hunter/Ranger follow-up](witch-hunter-ranger-followup.md) and
[Manastorm solo-scaling/cache delivery](manastorm.md). Earlier Guardian, Barbarian,
Witch Hunter and client fixes remained included.

The normal updater applied Witch Doctor SQL00, Necromancer SQL01, Necromancer
runtime SQL02 and character cache-delivery SQL02. These migrations are immutable.
Compile/data corrections included local appearances for three champions whose
recovered display references were absent; those are reconstruction choices.

Three model DBCs and the one-member Manastorm client overlay were installed.
The T archive and server Spell.dbc were preserved. A VS2022 RelWithDebInfo linked
build, final readiness, intended SQL and personal-data checks passed, with zero
new unique startup errors. Client startup checks covered stock authentication,
addons, lighting and the catalog. The data review separated native daily/respawn
state changes from protected personal data. These results did not establish
manual gameplay acceptance.
