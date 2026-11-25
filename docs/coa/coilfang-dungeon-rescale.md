# Coilfang dungeon rescale

The Slave Pens (547), The Underbog (546), and The Steamvault (545) use a level-60, five-player tuning benchmark of mostly Normal Blackwing Lair gear. Blackwing Lair sets the reward and combat benchmark. Dungeon access has no raidphase requirement.

| Mode | Equipment item level | Health vs. recalculated native Normal | Damage vs. converted Normal |
|---|---:|---:|---:|
| Normal | 71 | 4.00× | 1.00× |
| Heroic | 73 | 5.76× | 1.50× |
| Mythic | 76 | 7.52× | 2.00× |

## Combat and access

The 186 combat budgets cover 62 map/template pairs. Bosses are level 63, and trash and ordinary encounter adds are level 60. Health comes from the original Normal template and class/expansion stats at the converted level. The fixed health replaces general dungeon HP scaling. The mode damage budget retains the existing dungeon damage rate and offsets native difficulty template modifiers. Mythic uses the Heroic spawn layout. Normal-only spawns and the Heroic-only raid attunement NPC Skar'this keep their existing masks.

Hydromancer Thespia has a dedicated 400,000 / 576,000 / 752,000 HP budget so the Water Elementals remain relevant. The elementals have 53,328 / 76,792 / 100,257 HP each. These are initial tuning values. Verify tank pressure from Quagmirran's swings and poison effects, Rokmar's bleed, Kalithresh's Rage, and simultaneous casts from Thespia and the elementals. Verify heroic-only spell substitutions and periodic effects in combat logs before changing mode damage further.

Dungeon Finder retains the level-58 Normal gate and admits level-60 players to Heroic and Mythic. Direct Normal entry keeps its level-55 minimum. Heroic entry retains the Reservoir Key and lowers the character minimum to 60. Mythic has explicit level-60 access rows and retains its existing lack of a key requirement. The installed DBC defines all three map modes. Ahune's seasonal queue and Serpentshrine Cavern remain outside this pass.

## Loot and quests

The migrations cover 940 equipment sources and provide 2,820 fixed equipment budgets. The source IDs for 183 dungeon-specific items retain their original Normal or Heroic difficulty association so older copies receive the right budget. Shared original templates retain their stats. Coilfang's creature and chest loot hook routes rolled equipment to the appropriate fixed item without editing chances, quantities, conditions or groups. The Underspore chest retains its original quest loot.

Item budgets cover Classic PvE Power by slot, weapon damage, primary and secondary stats, armor, block, sockets, random affixes, and numeric item effects. Existing cross-dungeon set memberships and shared set bonuses stay in place. Client validation should cover an existing item, a newly routed item, a random affix on relog, an item effect, and the equipped PvE Power total.

Fifteen dungeon quests and three ordinary prerequisites admit level-60 characters as appropriate. Ordinary dungeon quest gear uses the Normal budget, and Heroic quest gear uses the Heroic budget. Quest XP brackets, rewards other than gear, keys, progress, and raid attunement conditions retain their original rules.
