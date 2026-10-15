# Cultist reconstruction policy — 2026-09-09

This pending source package builds on the Pyromancer source. The original audit
contains 160 findings: 158 receive implemented/extended dispositions, one retains
an existing Shieldtoss fix, and one acquisition question remains unresolved.
No claim of official-backend parity is made.

## Evidence and conflicting versions

Use the pinned active client spell descriptions, effect rows, rank chains and native
server data. They take precedence over stale helper prose. The local archived changelog
is corroborating evidence; a later redesign is not silently substituted for a different
active client contract.

- Covenant copies 20 percent from the referenced 300295 effect, not the stale 30-percent
  helper prose. Blade of Yogg-Saron halves the entire flat/stat component on both ranks.
- Black Blood has an initial heal in the active Malevolence tooltip and the original
  audit. That behavior is implemented. The 2025-07-31 archived removal of the initial heal
  conflicts with this client version. Newer Horrorbolt Volley redesigns also do not
  override the active three-cast replacement. These choices are not official parity.
- Both active Ward records have five mitigation stacks. Black Ward's extra charge is
  interpreted as a second cast charge, with 60-second recharge. Shroud adds three
  mitigation stacks; a consumed stack is not replenished by a routine aura refresh.
- Identity node 4041 still requires paid Corrupt Mind/29470. There is no recovered
  level-10-free-passive text establishing a safe acquisition change. Automatic
  acquisition remains excluded. Learning 92130 now activates its damage proc;
  whether the identity should be awarded free remains **unresolved**, not fixed.
  The user-supplied [Cultist documentation](https://ascension-wow-database.readthedocs.io/en/latest/classes/cultist/)
  was also checked at repository commit `91cd4dc976d3eebcd3f56a49e1ec26ee0d30f527`.
  It associates node 29470 with Eldritch Blast but shows Lunar Eclipse 800411, and gives
  identity 4041 a prerequisite. This inconsistent export does not establish an
  unconditional grant.

## Resources, ownership and finite effects

Insanity is 0..100. Availability markers use inclusive 20/40/60/80 boundaries; talents
whose text says “above” use strict thresholds. The C'Thun mana exemption is above 60;
Twilight Horror guaranteed criticals use at least 60 from the Shock parent's pre-spend
snapshot. Deep Secrets affects instant nonchanneled mana casts only. Decay is two per
native out-of-combat tick and pauses during Corrupting Whispers. Madness suppresses
ordinary spending; explicit resets, form expiry and Voidrider drain remain effective.
Void Rune retains its existing native compatibility mechanisms.

Hammer/Entropic Slam spend once before effects. A normal hit may miss without refund,
matching the other completed-cast generators. Triggered copies do not pay again. Blade
uses three shared six-second charges. Selected next-cast buffs reserve a generation so
an older cast cannot consume a newly reapplied bonus. Replacements use temporary spell
knowledge and native replacement notifications, preserving permanently learned spells.

Damage copies use the native post-mitigation event amount; effective-heal copies exclude
overheal. They do not gain a second coefficient or recursively trigger another copy.
These damage event amounts are not generally clamped to remaining victim health.
Twisted Sanity explicitly clamps overkill. Vision retains its allowed additional critical
roll and suppresses a repeated outgoing HoT multiplier. It prevents all healing while
the enemy's Vision remains active. Fresh Infusion/Blade/mark heals retain legitimate
native healing modifiers and critical eligibility.

Infusion expansion uses living party/raid recipients, excludes the previous recipient
and already-owned next-node auras, and sorts health percentage then GUID. Black Blood
prioritizes the owned Covenant link, fewer owned stacks, then lower health. Whispers
are exclusive **per recipient per Cultist**, not one target globally. Dark Prophet may
heal its original recipient, as the active description explicitly allows.

Yawning Decay preserves the owned pending budget, integer remainder and next tick on
refresh. Budget/tick count and Embrace's finite covered-damage budget use normal saved
aura effects. No new crash-recovery journal is introduced. In-flight casts, internal
proc timers, summoned-creature GUIDs and ritual participants are transient. Normal
logout, map changes, simultaneous casts and group play still require live acceptance.

## Coefficients and local choices

`AscensionCultistData.h` contains 121 explicit effect slots. New SQL12 suppresses native
coefficient duplication only for the listed spells. Preserve each rank's base and
per-level values. Dark Reservoir multiplies only the healing coefficient. Absorb-317
talents use the Cultist caster, and Embodiment increases only the shield base before
adding its separate coefficient. Hammer bypasses absorbs, retaining native resistance,
damage splitting and other mitigation. The new flag defaults false for other spells.

Where the recovered contract omits a formula, use these explicit local rules:

- Dreadful: dodge plus parry rating becomes critical rating, 1:1. Power of Yogg-Saron:
  2.5 times spell critical rating becomes attack power through the existing AP aura.
- Void Strikes: defense rating becomes the helper's flat selected-effect bonus, 1:1.
  Void Power: average current main-hand min/max damage becomes bonus healing, 1:1.
  These values do not claim an undocumented official conversion curve.
- Voidrider's recovered unlabelled private effect heals for 25 percent of critical
  damage. The visible speed, drain and replacement follow the active description.
- Owned combat summons use owner level, armor and one-third owner maximum health.
  Manifestations use 30 percent of current owner weapon damage and heal five percent
  base health on damage. Tentacle spell coefficients use owner stats; their native
  critical baseline is retained rather than promising full player crit inheritance.
- Target selection uses valid attack targets, native phase/map checks, 40-yard range
  and line of sight, with a 100-yard owner leash. Dreadfall uses actual traversed
  segments, two-yard hit width and four-yard height tolerance, once per enemy;
  stationary updates and teleport-sized jumps do not manufacture hits.
- Ritual channel drain is one percent maximum health per second and leaves at least
  one HP. Ten distinct, living, grouped players must actively channel the exact stone
  within ten yards. Only then does the hostile Destroyer appear; no one is sacrificed.
  Destroyer scaling is ten times the summoner's health plus owner armor and weapon.

## Summons, models and database installation

Ten summon templates and three transform templates use existing native displays/models.
Hallucination uses entry **840025**, not 840000: the latter already belongs to the
installed Witch Doctor clone. Its three appearance copies follow random run paths and
do not attack. One native Old God summon slot is preserved. Thoughtseize is removed by
its exact caster GUID on tentacle death and before world removal; another caster's
silence is left alone. Back/N'Zoth reapplication runs every six seconds so it does not
continuously postpone the two-second native ticks.

All selected native display/model-info chains resolve. No DBC, client archive, executable
or DLL change is needed. Model sizes, animations, clone appearances, ritual interaction,
pet owner proc forwarding and movement are **not** verified by the source checks.

SQL12 adds 215 exact script bindings, 72 native HIT proc rows, coefficient suppression,
two exact members of existing damage-reduction group 2000185, and 27 guarded inserts
(13 creature templates, 13 model rows and one summoning object). Existing haste group
2000182 remains. GO 194110 retains native type-18 group/channel/recipient-consent logic.

The current read-only preflight finds all new template definitions absent and confirms
native dependencies. Guarded INSERTs intentionally preserve conflicting rows; they do
**not** certify such rows as compatible. A future installation must reject any conflicting
definition, then include matching Cultist/Pyromancer source and SQL dependencies. Do not
rerun generators over any applied or preceding SQL. SQL12 is new and **unapplied**.

## Validation and acceptance boundary

MSVC `/Zs` checks actual translation units and project headers without producing
a server build or registering live scripts. Native fixtures run selected production
callback bodies and admission/cost branches with bounded dependency adapters.
The original Ranger Elude tests and all preceding captured SQL remain byte-identical.

The 165-test regression run precedes the final Hammer-placement, Vision-HoT, summon
lifecycle, exact tentacle-event and successful-dispel corrections. Its original inputs
and phase are retained. Final focused
counterexamples, native controls, lint and fresh /Zs cover those bounded corrections;
the later lint refresh is not represented as another 165-test run.

Integration must preserve the preceding class implementations and include
matching Cultist/Pyromancer source and SQL. Server/client testing requires a
separate authorized installation and manual acceptance of combat, group healing,
channels, movement, rendering and UI.
