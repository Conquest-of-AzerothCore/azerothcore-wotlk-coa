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
    assert resolve_cache(rows, endgame=True, depth=826, level=1) == 1289070
    assert resolve_cache(rows, endgame=True, depth=875, level=1) == 1289070
    assert resolve_cache(rows, endgame=True, depth=876, level=1) == 1289071
    assert resolve_cache(rows, endgame=True, depth=925, level=1) == 1289071
    assert resolve_cache(rows, endgame=True, depth=926, level=1) == 1289074
    assert resolve_cache(rows, endgame=True, depth=4294967295, level=1) == 1289074

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

    # The first player/player-controlled hit requests stage activation.
    # Protection remains owned by the existing Safety Bubble spell.
    assert "GetCharmerOrOwnerPlayerOrPlayerItself" in mgr_cpp
    assert "run->RequestStart();" in mgr_cpp
    damage_block = mgr_cpp[mgr_cpp.index("void ManastormMgr::OnDamage("):]
    assert "damage = 0;" not in damage_block
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

    completion_sql = (ROOT / "data" / "sql" / "db-world" / "base" /
                      "36_manastorm_completion_rewards.sql").read_text(encoding="utf-8")
    completion_schema = (ROOT / "data" / "sql" / "db-characters" / "base" /
                         "03_manastorm_completion_rewards.sql").read_text(encoding="utf-8")
    assert "('MARKS', 111381, 200, 1, 0, 0, 0, 0, 1)" in completion_sql
    assert "('CASE', 1278049, 1, 1, 0, 0, 0, 0, 1)" in completion_sql
    assert "('BEDLAM'" not in completion_sql
    assert "('BONZO'" not in completion_sql
    assert "CHAR_SEL_MANASTORM_COMPLETION_REWARD" in rewards_cpp
    assert "transaction->Append(saveState)" in rewards_cpp
    assert "rule.EndgameOnly && track != TrackBit(true)" in rewards_cpp
    assert "urand(0, 1) == 0 ? rule.ItemEntry : 1278048" in rewards_cpp
    assert "PRIMARY KEY (`guid`, `mode`, `track`, `reward_key`)" in completion_schema
    assert "ManastormRunState::AwaitingExit" in mgr_cpp
    assert "HandleReleaseAfterWipe" in mgr_cpp
    assert "MarkStageCooldownsReset" in mgr_cpp
    assert "MarkStageCooldownsReset" in run_h
    assert "RemoveActivePetSpellCooldowns" in mgr_cpp
    death_block = mgr_cpp[mgr_cpp.index("void ManastormMgr::HandlePlayerDeath("):
                          mgr_cpp.index("void ManastormMgr::GrantBaselineRunItems(")]
    assert "ManastormRunState::AwaitingExit" in death_block
    assert "FailRun(" not in death_block
    death_dispatch = mgr_cpp[mgr_cpp.index("void ManastormMgr::OnUnitDeath("):]
    assert "ManastormRunState::Active" in death_dispatch
    assert "gadget.spell == 254440" in mgr_cpp
    assert "gadget.spell == 992090" in mgr_cpp
    assert "gadget.spell == 762608" in mgr_cpp

    policy_sql = (ROOT / "data" / "sql" / "db-world" / "base" /
                  "37_manastorm_reward_progression.sql").read_text(encoding="utf-8")
    assert "('MARKS', 111381, 200, 1, 0, 0, 0, 0, 1)" in policy_sql
    assert "('MARKS_FIRST', 111381, 100, 1, 0, 1, 0, 0, 1)" in policy_sql
    assert "('CASE', 1278049, 1, 50, 1, 0, 0, 0, 1)" in policy_sql
    assert 'key == "MARKS_FIRST"' in rewards_cpp
    assert 'rule.Key == "CASE" ? uint64(depth) : uint64(depth - 1)' in rewards_cpp
    for depth, expected in ((1, 1), (49, 1), (50, 2), (99, 2),
                            (100, 3), (149, 3), (150, 4)):
        assert 1 + depth // 50 == expected
    assert "xpMultiplier *= mapFactor" in mgr_cpp
    assert "segment.NativeExperienceFactor1" in mgr_cpp
    cache_cpp = (SRC / "ManastormCacheLoot.cpp").read_text(encoding="utf-8")
    preference = cache_cpp[cache_cpp.index("ResolvePreferredPrimaryStat("):
                           cache_cpp.index("uint32 GetItemPrimaryStatAmount")]
    assert "GetStat(" not in preference
    assert "HasSpell(" in preference
    for spell in ("84864", "84865", "84866", "84867", "129243"):
        assert spell in preference

    # Currency and first-clear loot have separate delivery lifecycles.
    stage_block = rewards_cpp[rewards_cpp.index("bool ManastormRewards::PrepareStageCompletion("):
                              rewards_cpp.index("bool ManastormRewards::PrepareItemDelivery(")]
    assert "deferCurrency(_bonzo.ItemEntry, bonzo)" in stage_block
    assert "deferCurrency(_bedlam.ItemEntry, bedlam)" in stage_block
    assert 'rule.Key == "MARKS" || rule.Key == "MARKS_FIRST"' in stage_block
    assert 'key == "BONUS_CACHE"' in rewards_cpp
    assert "appendQuantity(itemEntry, quantity)" in stage_block
    settlement = rewards_cpp[rewards_cpp.index("bool ManastormRewards::SettlePendingCurrency("):
                             rewards_cpp.index("void ManastormRewards::PublishCommitted(")]
    assert settlement.index("DELETE FROM character_manastorm_pending_currency") < settlement.index("AsyncCommitTransaction")
    assert settlement.index("AsyncCommitTransaction") < settlement.index("PublishCommitted(publications)")
    for start, end in (("void ManastormMgr::FailRun(", "void ManastormMgr::HandlePlayerDeath("),
                       ("bool ManastormMgr::StopRun(", None)):
        block = mgr_cpp[mgr_cpp.index(start):mgr_cpp.index(end) if end else len(mgr_cpp)]
        assert "SettlePendingCurrency(memberGuid)" in block
    login = mgr_cpp[mgr_cpp.index("void ManastormMgr::OnPlayerLogin("):
                    mgr_cpp.index("void ManastormMgr::OnPlayerEnterMap(")]
    assert "SettlePendingCurrency(player->GetGUID().GetCounter())" in login

    fortune_sql = (ROOT / "data/sql/db-world/base/39_manastorm_fortune_case_loot.sql").read_text(encoding="utf-8")
    rows = re.findall(r"\((127804[89]), (\d+), 0, 100, 0, 1, 0, 1, 1,", fortune_sql)
    for entry, minimum in (("1278049", 97913), ("1278048", 97933)):
        actual = [int(item) for case, item in rows if case == entry]
        assert len(actual) == 20
        assert set(actual) == set(range(minimum, minimum + 20))
    bonus_sql = (ROOT / "data/sql/db-world/base/40_manastorm_bonus_cache_rewards.sql").read_text(encoding="utf-8")
    bonus_items = re.findall(r"\(1478052, (\d+), 0, 100, 0, 1, 0, 1, 1,", bonus_sql)
    assert set(map(int, bonus_items)) == {97885, 97886, 1278049, 1278048}
    assert len(bonus_items) == 4
    assert "('BONUS_CACHE', 1478052, 1, 1, 0, 1, 0, 0, 1)" in bonus_sql
    assert "`minMoneyLoot` = 10000, `maxMoneyLoot` = 10000" in bonus_sql
    schema = (ROOT / "data/sql/db-characters/base/04_manastorm_pending_currency.sql").read_text(encoding="utf-8")
    assert "PRIMARY KEY (`guid`, `item_entry`)" in schema
    assert "`quantity` BIGINT UNSIGNED" in schema

    # Every member is classified independently; hidden UI does not grant items.
    assert "GAME_MODE_WILDCARD = 0x0040" in rewards_cpp
    assert "session->GetNativeGameModeGuid() == characterGuid" in rewards_cpp
    assert "session->GetNativeGameModeMask()" in rewards_cpp
    assert "SELECT gameMode FROM coa_character_gamemode WHERE guid = {}" in rewards_cpp
    assert 'rule.WildcardOnly = key == "CASE" || key == "BONUS_CACHE"' in rewards_cpp
    assert 'rule.NonWildcardOnly = key == "BONUS_CACHE_OTHER"' in rewards_cpp
    assert "(rule.WildcardOnly && !wildcard)" in stage_block
    assert "(rule.NonWildcardOnly && wildcard)" in stage_block
    assert "wildcard ? run.GetBonusAbilityCaseCount() : 0u" in stage_block
    assert "wildcard ? run.GetBonusTalentCaseCount() : 0u" in stage_block
    assert ".BuildVisibilityRecords(player->GetGUID().GetCounter())" in bridge_cpp
    mode_sql = (ROOT / "data/sql/db-world/base/41_manastorm_game_mode_rewards.sql").read_text(encoding="utf-8")
    assert "('BONUS_CACHE_OTHER', 1478051, 1, 1, 0, 1, 0, 0, 1)" in mode_sql
    assert "item_loot_template" not in mode_sql
    assert "UPDATE `item_template`" not in mode_sql

    print("Manastorm reward regressions: PASS")


if __name__ == "__main__":
    main()
