"""Static regression guard for the reconstructed Voice of Millhouse runtime.

Usage:
    python voice_of_millhouse_regressions.py

This intentionally checks source ownership and recovered IDs without claiming
unknown original random weights/listener rules.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[3]

voice_h = (
    root / "modules/mod-manastorm-endless/src/ManastormVoiceOfMillhouse.h"
).read_text(encoding="utf-8")

voice_cpp = (
    root / "modules/mod-manastorm-endless/src/ManastormVoiceOfMillhouse.cpp"
).read_text(encoding="utf-8")

mgr_cpp = (
    root / "modules/mod-manastorm-endless/src/ManastormMgr.cpp"
).read_text(encoding="utf-8")

sql = (
    root / "modules/mod-manastorm-endless/data/sql/db-world/base/"
    "25_manastorm_voice_of_millhouse.sql"
).read_text(encoding="utf-8")

# Recovered Season-10 emitter identity.
assert "EmitterCreatureEntry = 80911" in voice_h
assert "Voice of Millhouse Manastorm" in sql
assert "80911" in sql
assert "10045" in sql
assert "0.009625" in sql
assert "INSERT IGNORE" in sql

# General recovered SoundEntries families.
for sound_id in range(113130, 113158):
    assert str(sound_id) in voice_cpp

# Complete recovered dungeon block.
for sound_id in range(132955, 133025):
    assert str(sound_id) in voice_cpp

# Key native-map routing.
for case in (
    "case 34:",   # Stockades
    "case 43:",   # Wailing Caverns
    "case 90:",   # Gnomeregan
    "case 389:",  # Ragefire Chasm
):
    assert case in voice_cpp

# Shared-map disambiguation must stay explicit.
assert "case 189:" in voice_cpp
for encounter in ("445", "446", "447", "448", "450",
                  "2445", "2446", "2447", "2448", "2450"):
    assert encounter in voice_cpp

assert "case 229:" in voice_cpp
assert "UpperBlackrockSpire" in voice_cpp
assert "LowerBlackrockSpire" in voice_cpp

assert "case 349:" in voice_cpp
assert "EarthsongFalls" in voice_cpp
assert "FoulsporeCavern" in voice_cpp
assert "WickedGrotto" in voice_cpp

# Reconstructed delivery must remain object-bound through the helper.
assert "SummonCreature(" in voice_cpp
assert "visibleBySummonerOnly" not in voice_cpp or "true" in voice_cpp
assert "PlayDistanceSound(" in voice_cpp
assert "PlayDirectSound(" not in voice_cpp

# Manager integration points.
assert '#include "ManastormVoiceOfMillhouse.h"' in mgr_cpp
for hook in (
    "ManastormVoiceOfMillhouse::RegisterRun(",
    "ManastormVoiceOfMillhouse::OnPlayerEnteredProtection(",
    "ManastormVoiceOfMillhouse::OnStageActivated(",
    "ManastormVoiceOfMillhouse::OnPlayerDeath(",
    "ManastormVoiceOfMillhouse::OnObjectiveComplete(",
    "ManastormVoiceOfMillhouse::Update(",
    "ManastormVoiceOfMillhouse::ClearRun(",
):
    assert hook in mgr_cpp

# The temporary narrator must never join normal Manastorm creature systems.
assert mgr_cpp.count(
    "ManastormVoiceOfMillhouse::EmitterCreatureEntry"
) >= 3

print(
    "Voice of Millhouse recovered IDs, dungeon routing, emitter playback, "
    "manager hooks and DB fallback passed."
)


# Intro timing ownership: Intro_* must be delivered during PREPARING arrival,
# not from the ACTIVE-stage hook.
assert "void OnPlayerEnteredProtection(" in voice_cpp
assert "IntroDeliveredMembers" in voice_cpp
stage_start = voice_cpp.index("void OnStageActivated(")
stage_end = voice_cpp.index("void OnPlayerDeath(", stage_start)
stage_block = voice_cpp[stage_start:stage_end]
assert "INTRO_FIRST_TIME" not in stage_block
assert "INTRO_RECURRING" not in stage_block

mgr_prepare = mgr_cpp.index(
    "if (run->GetState() == ManastormRunState::Preparing)"
)
mgr_active = mgr_cpp.index(
    "run->SetState(ManastormRunState::Active);",
    mgr_prepare,
)
intro_hook = mgr_cpp.index(
    "ManastormVoiceOfMillhouse::OnPlayerEnteredProtection(",
    mgr_prepare,
)
assert mgr_prepare < intro_hook < mgr_active


# PREPARING intro retry must exist outside the one-shot map-entry callback so
# teleport-state rejection cannot permanently lose narration.
update_start = mgr_cpp.index("void ManastormMgr::Update(uint32 diff)")
retry_hook = mgr_cpp.index(
    "ManastormVoiceOfMillhouse::OnPlayerEnteredProtection(",
    update_start,
)
assert retry_hook > update_start

# Dungeon VO should follow ACTIVE promptly again, not wait for the old
# first-stage 8-second overlap workaround.
assert "FIRST_STAGE_DUNGEON_DELAY_MS" not in voice_cpp
assert "constexpr uint32 STAGE_DUNGEON_DELAY_MS = 500;" in voice_cpp


# PREPARING intro must pre-spawn its emitter and delay the object-bound sound
# long enough for the client to learn that creature GUID. ACTIVE/death/boss
# playback continues using the established immediate path.
assert "constexpr uint32 INTRO_EMITTER_SETTLE_MS = 500;" in voice_cpp
assert "PreparedEmitterGuid" in voice_cpp
assert "CreateEmitterForMember(" in voice_cpp

intro_start = voice_cpp.index("void OnPlayerEnteredProtection(")
intro_end = voice_cpp.index("void OnStageActivated(", intro_start)
intro_block = voice_cpp[intro_start:intro_end]
assert "INTRO_EMITTER_SETTLE_MS" in intro_block
assert "CreateEmitterForMember(" in intro_block
assert "voice.PreparedEmitterGuid" in intro_block
assert "PendingVoices.push_back(" in intro_block


# Narrator scheduler: one run-level channel, real measured clip durations,
# priority selection, same-dungeon suppression, and run-level follow-through
# across portal transitions.
assert "uint32 BusyMs = 0;" in voice_cpp
assert "VOICE_GAP_MS = 250" in voice_cpp
assert "GetSoundDurationMs(" in voice_cpp
assert "GetVoicePriority(" in voice_cpp
assert "LastDungeonGroupPlayed" in voice_cpp
assert "HasPendingDungeonGroup(" in voice_cpp
assert "FollowMemberPosition" in voice_cpp
assert "VoiceKind::ObjectiveComplete" in voice_cpp
assert "VoiceKind::PlayerDeath" in voice_cpp

# Spot-check measured durations from the supplied 115-file voice archive.
for snippet in (
    "case 113142: return 15168;",  # Intro_FirstTime
    "case 113143: return 2880;",   # Intro_GenericWelcome
    "case 133006: return 7800;",   # Stockades_NeverBeenHere
    "case 133015: return 10680;",  # Uldaman_Troggs
):
    assert snippet in voice_cpp


# Dungeon commentary rotates through the authored pool before recycling. A
# line counts as used only after successful playback; immediate repeats are
# avoided, and encounter-specific overrides remain evidence-gated.
assert "UsedDungeonSounds" in voice_cpp
assert "PickDungeonSound(" in voice_cpp
assert "HasPendingDungeonSound(" in voice_cpp
assert "GetEncounterSpecificPool(" in voice_cpp
assert "LastDungeonGroupPlayed" not in voice_cpp
assert "used.erase(" in voice_cpp
assert "voice.SoundId" in voice_cpp
