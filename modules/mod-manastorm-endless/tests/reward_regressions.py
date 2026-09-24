#!/usr/bin/env python3
"""Static regressions for the shared Manastorm reward backend."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
WORLD_SQL = ROOT / "data" / "sql" / "db-world" / "base" / "14_manastorm_rewards.sql"
CACHE_SQL = ROOT / "data" / "sql" / "db-world" / "base" / "15_manastorm_cache_brackets.sql"
CHAR_SQL = ROOT / "data" / "sql" / "db-characters" / "base" / "02_manastorm_rewards.sql"


def bedlam(depth: int) -> int:
    return 1 + ((depth - 1) // 100)


def bonzo(depth: int) -> int:
    return 5 + 2 * ((depth - 1) // 10)


def next_pity(current: int, won: bool) -> int:
    return 0 if won else min(100, current + 13)


def cache_brackets(sql: str) -> list[tuple[int, int, int, int, int]]:
    pattern = re.compile(
        r"\(\s*\d+\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*"
        r"(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*1\s*,"
    )
    return [tuple(map(int, match.groups())) for match in pattern.finditer(sql)]


def resolve_cache(
    rows: list[tuple[int, int, int, int, int]],
    *,
    endgame: bool,
    depth: int,
    level: int,
) -> int:
    track = 2 if endgame else 1
    selector = 2 if endgame else 1
    value = depth if endgame else level
    matches = [
        item
        for row_track, row_selector, minimum, maximum, item in rows
        if row_track == track
        and row_selector == selector
        and minimum <= value <= maximum
    ]
    assert len(matches) <= 1
    return matches[0] if matches else 0


def main() -> None:
    rewards_cpp = (SRC / "ManastormRewards.cpp").read_text(encoding="utf-8")
    bridge_cpp = (SRC / "ManastormClientBridge.cpp").read_text(encoding="utf-8")
    progression_cpp = (SRC / "ManastormProgression.cpp").read_text(encoding="utf-8")
    mgr_cpp = (SRC / "ManastormMgr.cpp").read_text(encoding="utf-8")
    run_h = (SRC / "ManastormRun.h").read_text(encoding="utf-8")
    world_sql = WORLD_SQL.read_text(encoding="utf-8")
    cache_sql = CACHE_SQL.read_text(encoding="utf-8")
    char_sql = CHAR_SQL.read_text(encoding="utf-8")

    assert bedlam(1) == 1
    assert bedlam(100) == 1
    assert bedlam(101) == 2
    assert bedlam(1000) == 10

    assert bonzo(1) == 5
    assert bonzo(10) == 5
    assert bonzo(11) == 7
    assert bonzo(100) == 23
    assert bonzo(1000) == 203

    pity = 0
    expected = [13, 26, 39, 52, 65, 78, 91, 100]
    observed = []
    for _ in expected:
        pity = next_pity(pity, False)
        observed.append(pity)
    assert observed == expected
    assert next_pity(100, True) == 0

    rows = cache_brackets(cache_sql)
    assert resolve_cache(rows, endgame=False, depth=1, level=10) == 0
    assert resolve_cache(rows, endgame=False, depth=999, level=11) == 97877
    assert resolve_cache(rows, endgame=False, depth=999, level=24) == 97877
    assert resolve_cache(rows, endgame=False, depth=999, level=25) == 97878
    assert resolve_cache(rows, endgame=False, depth=999, level=59) == 97882
    assert resolve_cache(rows, endgame=False, depth=999, level=60) == 97883
    assert resolve_cache(rows, endgame=False, depth=999, level=61) == 0

    assert resolve_cache(rows, endgame=True, depth=1, level=60) == 1288050
    assert resolve_cache(rows, endgame=True, depth=50, level=1) == 1288050
    assert resolve_cache(rows, endgame=True, depth=51, level=1) == 1288051
    assert resolve_cache(rows, endgame=True, depth=105, level=1) == 1288051
    assert resolve_cache(rows, endgame=True, depth=106, level=1) == 1288052
    assert resolve_cache(rows, endgame=True, depth=676, level=1) == 1288068
    assert resolve_cache(rows, endgame=True, depth=705, level=1) == 1288068
    assert resolve_cache(rows, endgame=True, depth=736, level=1) == 1288071
    assert resolve_cache(rows, endgame=True, depth=765, level=1) == 1288071
    assert resolve_cache(rows, endgame=True, depth=826, level=1) == 1289074
    assert resolve_cache(rows, endgame=True, depth=855, level=1) == 1289074
    assert resolve_cache(rows, endgame=True, depth=856, level=1) == 0

    for item in ("97884", "1297307", "1297308", "1278049", "1278048", "97886", "97885"):
        assert item in world_sql

    assert "10111377" in world_sql
    assert "48611" in world_sql
    assert "character_manastorm_reward_state" in char_sql

    assert "CACHE_PITY_STEP_PCT = 13" in rewards_cpp
    assert "manastorm_cache_bracket" in rewards_cpp
    assert "LoadCacheBrackets()" in rewards_cpp
    assert "ResolveCacheItemEntry(" in rewards_cpp
    assert "ResolveCacheItemEntry(" in bridge_cpp
    assert "ResolveCacheItemEntry(" in mgr_cpp
    assert "ITEM_MANASTORM_CACHE" not in rewards_cpp
    assert "GetCacheItemEntry" not in bridge_cpp
    assert "GetCacheItemEntry" not in mgr_cpp
    assert "SELECT level " in rewards_cpp
    assert "PrepareStageCompletion" in progression_cpp
    assert "PublishCommitted" in progression_cpp

    # Stage rewards prefer direct inventory delivery after the durable reward
    # transaction commits. Only attachments that cannot fit remain in mail.
    assert "CanStoreItem(" in rewards_cpp
    assert "MoveItemToInventory" in rewards_cpp
    assert "CHAR_DEL_MAIL_ITEM" in rewards_cpp
    assert "SaveInventoryAndGoldToDB" in rewards_cpp
    assert "mailedOverflowStacks" in rewards_cpp

    assert "RewardVisibility" in bridge_cpp
    assert "BuildVisibilityRecords" in bridge_cpp
    assert "TrySpawnTreasureKeeper" in mgr_cpp
    assert "GetBonusCacheCount" in run_h

    # PREPARING protection cannot coexist with killable stage creatures.
    # The first real player/player-controlled hit explicitly starts the stage;
    # if the party cannot activate yet, outgoing damage is suppressed.
    assert "GetCharmerOrOwnerPlayerOrPlayerItself" in mgr_cpp
    assert "run->RequestStart();" in mgr_cpp
    assert "damage = 0;" in mgr_cpp
    assert "SAFETY_BUBBLE_CLEANUP_SPELLS" in mgr_cpp
    assert "ManastormRunState::StageComplete" in mgr_cpp
    assert "PreparationProtectionMs = 120000" in run_h
    assert "UpdatePreparationProtection" in mgr_cpp

    # The recovered Treasure Keeper client row is only an identity fallback.
    # Runtime stats must be normalized to the current Manastorm creature level.
    keeper_pos = mgr_cpp.index("IsTreasureKeeperEntry")
    keeper_end = mgr_cpp.index("Recovered Mana Bomb helper", keeper_pos)
    keeper_block = mgr_cpp[keeper_pos:keeper_end]
    assert "creature->SelectLevel();" in keeper_block
    assert "UpdateAttackPowerAndDamage" in keeper_block

    # Native Mode 2 payout follows the same untouched Manastorm.dbc multiplier
    # shown by the original client, not a divergent SQL mirror.
    assert "IsNativeClientMode()" in rewards_cpp
    assert "NativeRewardEndMultiplier" in rewards_cpp
    assert "NativeRewardEncounterMultiplier" in rewards_cpp
    assert "nativeMultiplier" in rewards_cpp

    print("Manastorm reward regressions: PASS")


if __name__ == "__main__":
    main()
