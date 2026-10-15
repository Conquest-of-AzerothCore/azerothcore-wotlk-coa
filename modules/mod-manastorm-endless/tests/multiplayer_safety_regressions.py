#!/usr/bin/env python3
"""Static regressions for Manastorm multiplayer safety/containment fixes."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
COMPAT = ROOT.parents[1] / "src/server/coa"


def main() -> None:
    mgr = (SRC / "ManastormMgr.cpp").read_text(encoding="utf-8")
    mgr_h = (SRC / "ManastormMgr.h").read_text(encoding="utf-8")
    run_h = (SRC / "ManastormRun.h").read_text(encoding="utf-8")
    bridge = (SRC / "ManastormClientBridge.cpp").read_text(encoding="utf-8")
    rewards = (SRC / "ManastormRewards.cpp").read_text(encoding="utf-8")
    module = (SRC / "Manastorm.cpp").read_text(encoding="utf-8")

    # Native UI/backend supports 1..15. Do not reintroduce the old party/raid cap.
    assert "group->GetMembersCount() > ManastormLimits::MaxMembers" in bridge
    assert "group->GetMembersCount() > 5" not in bridge
    assert "group->isRaidGroup()" not in bridge

    # Every member must validate the same run-wide Normal/Endgame track that
    # StartRun() will actually use.
    assert "bool runEndgame" in bridge
    assert "runEndgame," in bridge

    # Stage completion/rewards are character-owned and may be prepared while a
    # participant is temporarily offline.
    assert "member disconnected before the stage reward could be prepared" not in rewards
    assert "Player const* itemOwner" in rewards
    assert "item->SetOwnerGUID" in rewards

    # Preparation timeout/fallback must be able to activate with a missing
    # member rather than leaving permanent invulnerability.
    assert "CanStartWithMissingMembers" in run_h
    assert "AllowStartWithMissingMembers" in run_h
    assert "run->AllowStartWithMissingMembers();" in mgr
    assert "run->CanStartWithMissingMembers()" in mgr

    # Portal crossing is per-player. The first member prepares the next stage,
    # while the completed-stage portal remains valid for pending members until
    # their click or the unchanged five-second fallback.
    assert "BeginPreviousStageTransition" in run_h
    assert "GetPreviousPortalGuid" in run_h
    assert "IsPendingStageTransfer" in run_h
    assert "TransferMemberToCurrentStage" in mgr_h
    assert "bool const firstCrossing" in mgr
    assert "Other members remain in the completed stage" in mgr
    assert "five-second fallback" in mgr
    assert "run.HasPreviousStage()" in mgr
    assert """TransitionToNextStage(
                run,
                error,
                0,
                true)""" in mgr
    assert "FinishPreviousStageTransition" in mgr
    assert "previousStageInstanceId" in mgr
    assert """run->CanStartWithMissingMembers() &&
            run->HasPreviousStage() &&
            run->HasPendingStageTransfers()""" in mgr
    assert "Could not auto-transfer connected member" in mgr

    # Boss Heart thresholds use only the exact registered objective GUID.
    damage_start = mgr.index("void ManastormMgr::OnDamage(")
    damage_end = mgr.index("bool ManastormMgr::ForceStageAffix(", damage_start)
    damage = mgr[damage_start:damage_end]
    assert "IsObjectiveBoss(" in damage
    assert "creature->GetEntry() ==\n        segment.ObjectiveCreatureEntry" not in damage

    # Normal stage creatures are contained: no ordinary loot/reputation and no
    # kill quest/achievement credit escapes from the private run.
    assert "creature->SetLootRewardDisabled(" in mgr
    assert "creature->SetReputationRewardDisabled(" in mgr
    assert "PLAYERHOOK_PASSED_QUEST_KILLED_MONSTER_CREDIT" in module
    assert "PLAYERHOOK_ON_BEFORE_CRITERIA_PROGRESS" in module

    # Active gadgets must come from the member's frozen run-start loadout.
    assert "SetMemberGadgetLoadout" in mgr
    assert "IsGadgetEquipped" in run_h
    assert "class manastorm_gadget_spells" in module
    assert "SPELL_FAILED_NOT_READY" in module

    # Cleanup removes only copies this process actually granted; it must never
    # delete an unrelated legitimate item merely because the entry matches.
    assert "_grantedBaselineItems" in mgr_h
    remove_start = mgr.index("void ManastormMgr::RemoveBaselineRunItems(")
    remove_end = mgr.index("void ManastormMgr::UpdateManastormPotionCharges(", remove_start)
    remove = mgr[remove_start:remove_end]
    assert "_grantedBaselineItems.find" in remove
    assert "DestroyItemCount" in remove

    # Generic creature normalization now has the same null guards as the
    # special Treasure Keeper normalization path.
    assert "if (creatureTemplate)" in mgr
    assert "if (stats)" in mgr

    print("Manastorm multiplayer/safety regressions: PASS")


if __name__ == "__main__":
    main()
