# Fixed item rescaling

Read when a raid, outdoor zone, dungeon or profession conversion changes equipment or item requirements.
Use the invoking skill's scope, effect policies and ownership rules; this reference does not authorize new
content changes or replace per-conversion budgets.

## Effective budgets and ownership

Trace `CoAZoneScaling`, `CoADungeonRescale`, `CoAProfessionRescale`, `AscensionItemScaling`,
`AscensionNativeItemScaling` and `AscensionItemPower` where applicable. `ZoneScaling::OwnsItem` and
`ItemPower` currently compose the fixed zone, dungeon and profession ownership paths. Check overlap before
assigning another budget to an existing ID. A template's ItemLevel alone does not disable captured native
stat ladders or fix its Power value. Verify the approved Power policy independently: a slot-based realm
budget need not follow the same item-level ratio as primary stats. Keep template Power spells, persisted
budget rows and compiled/runtime overrides consistent; updating only one can leave previews and combat
disagreeing. Do not infer an approved policy from an untracked or unapplied proposal.

Match original quality, slot and role when using RandPropPoints or benchmark items. Spell-based permanent
stats, including weapon damage and Power, belong to the equipment budget even when the owner preserves
procs and on-use effects. Preserve quality and approved sockets; account for the socket budget and flag
utility-heavy items rather than silently changing their quality or socket count.

Verify both client stat replies and actual equipped values. `AscensionNativeItemScaling::WornArmor` can
substitute authored ItemAddon armor independently of a correct template or tooltip. The current profession
path bypasses that substitution for fixed profession items; do not assume other fixed owners have the same
coverage. Verify the relevant armor classes and preserve outside behavior when extending a bypass.

## PvE Power by slot

For level-60 conversions, use the Classic CoA PvE Power value for each equipment slot that carries
PvE Power. Keep that value across item levels, qualities and difficulty variants. These values come
from level-60 Classic equipment and the TBC normalization migration.

| Slot | PvE Power |
| --- | ---: |
| Neck, wrist, ring, trinket, cloak | 20 |
| Shoulders, waist, feet, hands | 25 |
| Head, chest (including robes), legs | 38 |
| Bow, gun, crossbow, thrown, wand | 45 |
| One-handed weapon, shield, held off-hand | 48 |
| Two-handed weapon | 96 |

Preserve zero PvE Power and the existing PvP Power policy. For slots outside this table, check
effective Classic peers before assigning a value. Match the on-equip spell and the effective
`AscensionItemPower::OfItem` value for each covered variant. Verify the winning runtime owner if
multiple tables or native overrides can supply Power for the same item.

In an equipped check, use a level-60 character with an empty test slot and enough room below the
495 PvE Power cap for the full increase. Use a usable, unbroken item. Confirm the equipped total
rises by the slot value and drops when the item is removed. Check the tooltip separately after
refreshing cached item data. Record which equipment paths or client checks remain unverified.

## Affixes and existing copies

Distinguish an item_enchantment_template pool ID from a direct ItemRandomProperties DBC ID. Reuse
client-known affixes with the same name/stat family when possible. Compare effective DBC plus SQL values,
level/skill restrictions and actual existence, not just native profile labels. Preserve each original affix
family's aggregate chance and keep unrelated shared pools unchanged when isolating converted choices.

Map original and previously issued affixes to stable canonical values; normalizing an already canonical
value must do nothing. Apply normalization before equipped stats are calculated. Inventory loading can
reset item state to unchanged after a hook runs: a changed property in memory is not proof it was saved.
Ensure a deferred persistence marker survives that reset and queues the item once after login, or use an
equally verified persistence mechanism. Check ownerless objects and missing owners without requiring a map.

Cover existing equipment, bags and bank, plus mail and auction previews before inventory arrival. Retrieval
hooks alone can make the delivered item correct while its listing still advertises the old affix. Keep
preview normalization separate from when an ownerless item can safely be saved. Preserve the invoking
skill's provenance policy for shared copies; do not convert unrelated items merely to exercise these paths.

## Client compatibility and requirements

Audit character-level gates separately on item templates, recipe books/learning spells, trainers and
socket/enchantment application. Preserve valid lower requirements and non-level skill/reputation restrictions.
A level-70 requirement does not establish expansion ownership; verify the recipe and original content data.

Refresh cached templates for every changed identity needed by the conversion, including recipe books and
gems as well as equipment. Reuse the established item-query delivery and native stat protocol where they
cover the data. For fixed stat replies, preserve the requested cache key while returning actual converted
item level and stats, including low preview keys and stale stored instance keys. Test acquisition and relog.

The current protocol can deliver supported item/spell changes; it does not stream arbitrary GemProperties or
SpellItemEnchantment table changes. Reusing existing IDs avoids introducing unknown records but does not
prove that changed client-local values are correct. Inventory any required new records or local edits early.
Tell the owner before introducing a downloadable client patch, and obtain their agreement for that approach.
Report stale descriptions or unverified socketing constraints rather than claiming rendered-client acceptance
from a SQL or harness pass. Record actual acceptance separately.

## Repeatability and deployment

Regenerate from pinned original data and explicit scope/inputs, excluding test/debug outputs. Keep the
baseline's expansion identity even if previous work lowered its requirements. Retunes need new migrations;
do not rewrite applied SQL or multiply converted live values again.

Keep generated runtime profiles and migrations in agreement. Verify inactive/partially matching data does
not accidentally enable a compiled profile. Reuse known-good ownership/query paths instead of adding global
scaling overrides. The current profession generator and pinned Jewelcrafting cohort are documented in
`apps/coa-world-content/professions/README.md`; they are not a general discovery tool for other professions.

Before an authorized installation, inventory all active unapplied SQL in the configured source checkout.
An updater restart can apply additional active migrations, not only the one being discussed. Keep superseded
`.sql.draft` alternatives inactive; validate the approved active sequence together and check replay. A source
activation does not install binaries or execute live SQL. Deployment still follows the user's authorization,
including any decision to make their own backup and installation.
