# Zangarmarsh outdoor rescale

Zangarmarsh is map 530, parent area 3521, and outdoor zone order 1. It follows Hellfire Peninsula in the outdoor progression. The level-60 reference is a BWL-geared damage dealer sustaining about 15,000 DPS. The reward level is 71, with a range of 67–74.

## Combat

The existing outdoor scaler applies a single 1.20 health and damage factor to Zangarmarsh budgets. A typical hostile creature uses its original expansion/class HP and template modifier at level 60, the realm's world HP rate of 1.95, and a calibrated 14.30 multiplier before the zone factor. The spawn-weighted median for the ordinary hostile group is 149,962 effective HP, or 10 seconds at the reference DPS. Neutral sporebats use a ceiling of about 150,000 effective HP.

| Target | Level | Effective HP, approximately |
|---|---:|---:|
| Feralfen Hunter | 60 | 133,298 |
| Marshfang Ripper | 60 | 147,198 |
| Fen Strider | 60 | 208,254 |
| Withered Giant | 60 | 249,918 |
| Marticar | 63 | 444,578 |
| Lord Klaq | 63 | 450,000 |
| Rajah Haghazed | 63 | 739,768 |

The migration defines 91 combat budgets. Named group encounters use individual budgets and a five-player quest recommendation. Rare health starts with the original rare template budget recalculated at 63. Fhwoor gets an escort survival budget with damage neutral to the zone step. The hostile serpent spirit and the Hunter's tamed sporebat summon have their own entries. Town NPCs, guards and instance copies receive no zone budget through this migration.

## Quests and items

The migration covers 97 outdoor quest records under Zangarmarsh, preserving lower minimum levels, quest requirements, XP reward indices, gold and reputation. Positive quest levels are set to 60 so normal quest XP uses the level-60 table. Coilfang instance quests, profession chains and seasonal quests remain outside the conversion.

The 91 converted item IDs comprise 70 quest items, nine named rare drops, and twelve Cenarion Expedition or Sporeggar reputation items. Reputation and currency gates, vendor inventories, and original item IDs are retained. Entry greens are item level 67–68, stronger solo quest rewards are 71, group and faction rewards are 73, and the top faction pieces and rare drops are 74. Equipment receives the Classic PvE Power amount for its inventory slot. Stats, weapons, armor, block and socket bonuses are budgeted from the original item and existing Classic slot benchmarks. Fixed random-property families use item-specific pools and mappings for existing copies. Random suffixes keep their families and derive magnitude from the new item level.

The two quest trinkets' Focused Power effects, Muck-Covered Drape's Soothe, and Petrified Lichen Guard's Spore Cloud use item-specific spell IDs. The Walking Stick retains its minor run speed effect. Shared PvP armor sets, generic world drops, consumables, and profession rewards are outside the item manifest.

## Baseline and validation

The pending migrations pin the level, HP, item and effect outputs against the pre-conversion data on the `release/live-20261121-custom` checkout at `a4de371eb9`. They reuse the outdoor scaling tables from the Hellfire migration.

In a realm playtest, check kill time and incoming damage on a solo Ripper and a Hunter plus Mystic pull, a five-player Rajah or Lord Klaq fight, and Fhwoor's escort. Check a Coilfang creature shared with the outdoor zone, both factions' quest and vendor access, and the power from equipping a converted item. The client can cache pre-conversion item tooltips. Item-effect display and owned random-property gear need client validation.

## Hellfire parity retune

Follow-up migrations `rev_20261123_51` through `rev_20261123_54` supersede the combat and
equipment targets above. Zangarmarsh stays at outdoor order 1 and uses zero local health and damage
steps, with the same 10× ordinary-enemy health budget as Hellfire. The ordinary-hostile median is
87,390 HP. The Feralfen Hunter, Marshfang Ripper, Fen Strider and Withered Giant now have projected
HP of 77,680, 85,780, 121,360 and 145,640 respectively. Rare HP is capped at the 300,000 Hellfire
benchmark. Group enemies keep dedicated health floors, and Fhwoor retains the original effective
escort HP.

The new equipment target is 63, with a range of 59–66. The 91 existing items are rebudgeted from the
original gear data. PvE Power remains slot-based, and legacy random-property aliases route already
owned items to the new affixes. The scope is limited to outdoor Zangarmarsh.
