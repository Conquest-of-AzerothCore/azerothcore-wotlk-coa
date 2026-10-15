# Guardian reconstruction, 2026-09-08

Source implementation addresses all 93 findings in the first-pass Guardian audit.
It builds on the preceding armor/resource/coefficient implementation and uses
copied client records and later changelog corrections as its primary contracts.

Local policy for the undisclosed parts:

- Ram adds 100% of effective shield block value; Footman's Call adds its authored 15 plus
  30% block value to Pulverize. An absent or broken shield contributes zero.
- Defense rating adds 50% of the raw rating to Heavy Blow and 20% to Retaliation.
  These are flat additions before normal damage modifiers, independent of the established AP terms.
- Shield Combat grants AP equal to the raw block rating. Shieldlord's Strength adds 20% Stamina
  to Heavy Blow and Hammer of the Law, as named by the visible parent.
- Repeated damage-conversion bleeds carry their unpaid damage into a refreshed full duration.
  They never add a second AP/SP bonus or a second physical armor reduction. Absorbs and immunity
  still apply to the new damage. Shield Unit accumulates 5% of damage taken, refreshes its 60-second
  window, and caps at 20% maximum health in AP to bound growth.
- Advance ends in its damage stomp on recast or natural expiry; the unadvertised stun helper is
  not included. Cancellation, death and logout do not create a free stomp.
- Battle Drums grants each ally one five-proc buff per placement, rather than continually refilling
  charges while that ally remains in range. Its three objects share the placement's recipients.
  Living friendly players and their controlled units qualify. All three new objects must be created
  before the previous placement is removed. A partial failed placement is removed instead.
- Echoes of War snapshots and consumes its buff at the launch of the next direct damaging cast.
  All of that cast's targets, including delayed hits, receive their own 15% echo of final damage.
  Failed cast validation, healing-only casts and triggered helpers do not spend the buff; a valid
  damaging cast that misses does spend it. The snapshot belongs to the native Spell lifetime.
- Earthsplitter's authored three-stack cap is meaningful: consecutive Broad Sweeps maintain and
  refresh the increasing target/cost bonus until its duration ends. Treating it as a one-charge
  spell modifier would prevent the advertised stack growth.
- Peril consumes only the caster's stacks on a landed Pulverize/Conqueror hit. Each stack adds
  10% AP and reduces Arena's remaining cooldown by 10%; multiple targets aggregate up to the
  full remaining cooldown for that cast. It does not extend or reset unrelated cooldowns.
- Persistent raid AP, critical chance, haste and hit bonuses share explicit native groups
  2000180–2000183. The highest applicable raid effect wins, while a talent's separate personal
  effect and temporary Battle Drums bonuses still apply. Native racial hit and split melee/spell
  critical auras are included. Swiftness and Conquest remain independent categories.
- Paragon Smash shares Heavy Blow's cooldown and inherits its defense-rating addition. Its
  temporary grant and Ballad grants preserve the original learned abilities. Native recursive
  rank removal is respected when upgrading or removing temporary spells.
- Polearm Training allows a polearm plus shield; Shieldlord allows a two-handed mace plus shield.
  Shieldlord no longer invokes unrestricted Titan Grip. Other two-handed/off-hand combinations
  retain the ordinary equipment rules. Polearm range applies to native melee-range abilities.

These choices are local reconstruction, not recovered official values. Copied-data
percentages, masks, rank lists and durations were the starting contracts for the
audit. Dynamic nearby/stat effects refresh once per second.

The [Guardian migration](../../data/sql/updates/pending_db_world/rev_20260908_05_guardian_completion.sql)
contains 30 proc entries, 121 scoped script bindings, nine coefficient rows, four
raid groups and one guarded missing-template insertion. It also removes obsolete
proc ownership for Honorable Demeanor and Echoes of War. Applied migrations 01/02
are unchanged.

Validation of this source package did not include configuration, a linked server
build, SQL application, client installation or gameplay acceptance. See the
[release history](local-release-state.md) for later integration.
