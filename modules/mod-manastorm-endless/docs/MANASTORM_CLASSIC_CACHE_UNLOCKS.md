# Classic cache progression

SQL 47 selects twenty endgame cache tiers from Classic dungeons through Mythic Naxxramas, using the supplied item descriptions and Ascension's Chapter-2 table:
https://ascension.gg/de/news/chapter-2-pre-patch-updates/461

Apply `47_manastorm_classic_cache_unlocks.sql` to the world database with the accompanying source and restart. No character migration is required. Normal level-based rewards and Bonus Caches are unchanged. Existing TBC depth brackets are preserved but disabled.

`manastorm_cache_bracket` controls tier ranges and awarded items. `manastorm_cache_unlock_requirement` controls each item's required highest completed depth per track. A missing or disabled requirement makes that item unrestricted. The seed requires completion of the floor immediately before each tier begins; this is our reconstruction policy, not recovered proprietary server logic. Re-running SQL 47 restores the seed policy.

Progress uses existing character completion records, separately for Solo, Duo, Trio and Group, and normal/endgame tracks. Highest completed depth unlocks earlier milestones too; it does not require every preceding floor to have been individually completed. During objective completion the current completed floor is considered within the existing transaction. Native reward previews use committed history. Locked tiers fall back to the highest unlocked lower tier. Failed history reads never unlock a protected tier.

Older DBC equipment-toast depths differ from some Chapter-2 cache ranges. This change does not rewrite those native messages. Item existence also does not prove a working loot profile: SQL 47 does not populate cache contents. Already-owned caches remain usable regardless of progression.

Validation: in-memory SQLite migration reapplication and a policy model covering every tier boundary, fallback, prospective completion, failed history reads and preserved normal/TBC rows. No server build or in-game test was run.
