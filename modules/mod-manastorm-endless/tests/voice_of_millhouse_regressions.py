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
