# Templar reconstruction policy — 2026-09-09

This local compatibility implementation addresses 25 findings using 905 client
spell records and 647 archived changelog entries. It does not claim official
Ascension backend parity. See the [release history](local-release-state.md) for
later integration.

## Evidence and boundaries

The current client description and acquisition identity take precedence over obsolete helper text.
The recovered June 11, 2026 changelog (68908) makes Fervent Castigation prepare Retribution for the
next chain. The August 6 entry (70187) makes Argent Blade trigger Scourgebane without extending the
chain. Current identity 92111 is accepted alongside legacy 520007, with duplicate identity suppression.
Existing seven-rank Reckoning Energy and the five-root exclusive Libram group 1128 are retained.

The nine main Librams and Silverhand are MAGIC in the recovered DBC. Sanctify/Eonar need positive
magic FINISH events, not only melee events. The earlier SQL41 proposal was outside the updater and
its script lacked a loader call. Pending SQL04 now supplies complete entries and exact bindings.
Sanctify grants 20-second haste; Eonar grants its 15-second damage/healing buff. Silverhand requires
the Scourgebane identity for Eonar. These temporary bonuses do not join the main-Libram exclusion group.

## Oaths and selected casts

Completed player casts of Lunge, Cleave, Condemn and Vindication/Divine Fury grant the corresponding
Oath. The chain lasts 15 seconds without refresh from subsequent generators and stops at ten grants.
Every Oath kind is held alongside the others until the chain ends, and each kind's stacks can accumulate
to ten (#4152). The earlier one-kind limit, raised to two by legacy passive 707755, is gone: no player can
acquire 707755, so everyone was capped at one kind and Condemn removed Lunge's Oath. The current texts treat
Oaths as a set — Breakers consume "your Oaths" and Flaming Blade gains the Oaths of each Follow Up in the
chain — and only Graceful Fighter's stale aura tooltip still reads "up to 2 Oaths".

Breakers consume the chain unless Keeping the Oath is active. Chain expiry clears the Oaths and the
Zealotry contribution to Upheaval. Aggramar refreshes owned Blade of Faith at ten chain stacks.
Tempest snapshots the four damage-bearing Oath types before consumption, including 30% per stack;
Cleave's utility Oath retains its additional-target effect. Fervent Castigation and Scarlet Secrets
produce Retribution according to their separate next-chain/every-second-Argent rules.

The existing three-icon client artwork is retained as distinct Oath icons. Each icon displays its
current stack count, with a separate chain count out of ten. Replaced/removed Oaths are cleared on
each aura update, and the full-chain glow uses ten stacks. This is a tested Lua controller, not a
rendered in-game acceptance result. Its candidate also includes the pending Necromancer Life Force UI.

Tome resets Barrier/Circle cooldowns, supplies a maximum-health shield and grants one finite bonus for
each next cast. Circle receives an immediate first tick while retaining its normal lifetime and interval.
Selected buffs carry generations so completing an older cast cannot consume a newer refresh.
Warrior of Dawn retains its recovered 50% Energy reduction. Scarlet Training and Divine Fury supply
finite temporary replacements that revert on use or expiry. High General is granted at five Scarlet
Champion stacks; its selected Chastise consumes only the stacks captured for that cast.

## Damage, healing and protection

Keeping the Oath absorbs 40% of remaining direct damage into an eight-second debt pool. Periodic damage,
self damage and a duplicate legacy identity are excluded. Adding debt preserves the next scheduled tick.
Ticks use rounded-up remaining debt divided by remaining ticks, conserve the full amount and do not
apply a second armor/resistance pass. Holy Books removes 70%; Sacred Oath removes one tick's share;
the selected Tome Barrier removes the full debt. The debt amount is stored in the aura for persistence.

Actual damage/healing events drive Deliverance, Retribution, Uther, Sacred Defense, Zealotry, Scourgebane,
Chakras, Libram helpers, Scarlet Champion, Parry Dance and the other explicitly routed talents. Misses,
zero effective healing and foreign ownership are filtered as appropriate. Helper recursion is bounded.
Downfall/Redemption explicitly leech actual helper damage as well as primary damage, preserving any outer
proc guard; self damage cannot leech. Redemption begins only when Downfall expires naturally.

One With the Light triggers Zealotry and reduces the named Libram/Force/Testament cooldowns on a Breaker.
Eternal Blessing's damage reduces Libram cooldowns once per cast when its talent is selected. Condemn
spread preserves the owner's rank, stack count, remaining duration, amount and next periodic tick.
Crusader's Brand reacts to direct damage by the marked unit, keeps native tracking, prevents fleeing,
caps running speed at normal and rejects mounting. Its retaliation uses the Templar as damage owner.

Tenacity reduces physical damage by 30% in PvE and 15% against players or their controlled units.
Battlepriest reduces magic damage by 20% only above 80% or below 20% health. Hope counts live owned
copies within the recovered 15-yard radius: 10% damage reduction per copy, plus 5% with Spiritual Abdicator.
Light Ward uses 10% dodge rating. Fortified Body uses the described 6% health. Untainted keeps its base
flat reduction and adds the described Stamina term.

Explicit local choices where the recovered description omits a coefficient:

- Staffguard: 125 + 30% Stamina + 25% combined raw dodge/parry rating.
- Mending Ward: its native base + 25% Stamina + 25% raw parry rating per consumed stack.
- Improved Benediction: Agility + Stamina armor for 15 seconds, gated to the talent at LAUNCH_TARGET.
- Interdict's additional target: one valid nearby enemy within eight yards and line of sight.
- Hope copies: owner level, half maximum health and half weapon damage, owner armor and attack speed.

Choices behind the 2026-09-17 audit fixes, where the shutdown tooltip names more than the client data delivers:

- Templar's Might adds Blade of Faith to Condemn's damage-from-caster mask; One-Punch Man adds Righteous Tempest's
  damage helpers and a matching 20% periodic modifier for Blade of Faith. Oath: Retribution stays outside Combat
  Training, as its client mask excludes it.
- Norgannon's Wrath's blast takes Chastise's family bit ("scales with modifiers to Chastise"), debuffs every enemy
  it hits and ignores absorbs and resistances (tooltip, and the client SpellCustomAttr bit shared with Dragon's
  Wrath). A missed primary hit roll still cancels the blast.
- Devotion of Khaz'goroth refunds 0.5 sec on every Libram rank (tooltip and 2025-08-04 changelog) instead of its
  helper's per-spell values. Aggramar's Rage's crit applies only to its masked Holy abilities; the 2026-01-07
  changelog's extra Chastise damage has no shutdown data and is not implemented.
- Fury of Aggramar also doubles Libram of Consecration's extra jump targets through the client data; no tooltip or
  changelog confirms that, and it is left unchanged.

The 113 coefficient slots preserve normal weapon contributions while adding separately authored terms
once. The recovered parent values override stale Scourgebane/Tempest/Chakra helpers. Copied-result helpers
do not gain a second caster coefficient, crit, target modifier or armor pass. Exact SQL bonus suppression
rows accompany these source paths. Additional-target bases are corrected, and Consecration ranks gain
one through four jumps beyond the primary target. Changed target selectors rebuild their explicit masks.

Sacred Resistance applies its native 15% armor buff once per completed, non-triggered Reckoning cast,
including every rank. Armor of Faith triggers only when the caster's Staffguard shield is exhausted
by damage; expiry, cancellation and dispelling a shield with capacity remaining do not trigger it.
Its native area damage and threat retain the authored 20% AP and 50% Holy spell-power coefficients
through pending `rev_20260913_02_templar_passives.sql`. The regression at
`apps/coa-tests/templar_passives/run.py` reuses the workspace completion fixture in a temporary directory.

## Summons, movement and installation

Testament of Hope retains the native two-creature summon effect and 20-second lifetime. GUID-owned AI
uses the native clone-caster appearance/equipment aura, follows the owner and fights valid targets.
Display 775 is the verified classic fallback before the clone aura. Divine Charge uses existing display
14584, a finite aura-owned mount, and scoped cast permission while that exact mount is active. Allies
provide the trample center; the Templar remains its damage owner. Aura removal cleans up the mount even
if its original caster is gone. The copied appearance and movement still need gameplay acceptance.

Install only after an explicit build request. Use matching source, pending world SQL04 and the combined
client candidate, preserving the pending Necromancer SQL03 and its source. SQL04 has 86 exact bindings,
30 combat proc entries, two FINISH proc entries and one guarded Hope creature/model definition. Existing
SQL and installed DBCs are immutable. Reject a conflicting entry 50250/model row before installation;
guarded inserts deliberately do not overwrite it. No Templar DBC addition is required.

The shared core changes are limited to Brand's run-speed/mount restriction and Divine Charge's cast
permission. The source includes all earlier installed class packages. No server configuration, link,
SQL application, live archive replacement, restart, cache reset, player-data change or Git publication
was performed for this package. Linked build, runtime registration and gameplay remain separate checks.
