/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterEchoes.h"
#include "DataMap.h"
#include "GameTime.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Timer.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
constexpr uint32 ZENITH = 712325;
constexpr uint32 ECHOES_ZENITH = 712389;
constexpr uint32 ECHOES = 521211;
constexpr uint32 RUNIC = 61;
constexpr uint8 ECHOES_DEBT_EVENT = 20;
constexpr uint8 ECHOES_ORDINARY_EVENT = 21;
constexpr char LEDGER_KEY[] = "core.runemaster.echoes";
constexpr char POOL_KEY[] = "core.spell_charge.712389";
constexpr char RUNTIME_KEY[] = "ascension.runemaster.echoes";

struct Ledger
{
    uint64 BaseUntil = 0;
    uint32 LastRecovery = 0;
    uint64 ProvisionalUntil = 0;
    bool Untracked = false;
    uint64 OrdinaryUntil = 0;
    uint64 VariantOrdinaryUntil = 0;
};

struct Runtime : DataMap::Base
{
    uint32 Specialization = 0;
    uint8 NativeSpec = 255;
    uint32 Elapsed = 0;
    bool Busy = false;
    bool Pending = false;
    bool WasVariant = false;
};

bool IsRunemaster(Player const* player)
{
    return player && player->getClass() == CLASS_SPIRIT_MAGE;
}

uint64 Now()
{
    return std::chrono::duration_cast<Milliseconds>(GameTime::GetSystemTime().time_since_epoch()).count();
}

PlayerSpell* CurrentSpell(Player* player, uint32 id)
{
    auto found = player->GetSpellMap().find(id);
    if (found == player->GetSpellMap().end() || found->second->State == PLAYERSPELL_REMOVED ||
        !found->second->IsInSpec(player->GetActiveSpec()))
        return nullptr;
    return found->second;
}

bool Owns(Player* player, uint32 id)
{
    PlayerSpell* entry = CurrentSpell(player, id);
    return entry && entry->State != PLAYERSPELL_TEMPORARY;
}

bool HasContract()
{
    SpellInfo const* base = sSpellMgr->GetSpellInfo(ZENITH);
    SpellInfo const* variant = sSpellMgr->GetSpellInfo(ECHOES_ZENITH);
    SpellInfo const* talent = sSpellMgr->GetSpellInfo(ECHOES);
    if (!base || !variant || !talent || base->MaxCharges || base->RecoveryTime != 45000 ||
        variant->RecoveryTime || variant->MaxCharges != 2 || variant->ChargeRecoveryKey != ECHOES_ZENITH ||
        variant->ChargeRecoveryTime != 45000 || variant->ChargeCategoryId != 542 ||
        talent->SpellFamilyName != 38 || talent->Attributes != 192 || talent->ProcFlags ||
        talent->Effects[EFFECT_0].Effect != SPELL_EFFECT_APPLY_AURA ||
        talent->Effects[EFFECT_0].ApplyAuraName != SPELL_AURA_DUMMY ||
        talent->Effects[EFFECT_0].TriggerSpell || talent->Effects[EFFECT_1].Effect || talent->Effects[EFFECT_2].Effect)
        return false;

    for (SpellInfo const* info : {base, variant})
    {
        SpellEffectInfo const& effect = info->Effects[EFFECT_0];
        if (info->SpellFamilyName != 38 || info->SpellFamilyFlags != flag96(268435456, 0, 0) ||
            info->Attributes || info->AttributesEx || info->AttributesEx2 || info->AttributesEx3 ||
            info->AttributesEx4 || info->AttributesEx5 || info->AttributesEx6 || info->AttributesEx7 ||
            info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC || info->SchoolMask != 8 ||
            info->CategoryRecoveryTime || info->GetCategory() || info->Speed || info->ProcFlags ||
            info->GetDuration() != 6000 || info->SpellLevel != 10 || info->BaseLevel != 10 || info->MaxLevel ||
            effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.ApplyAuraName != SPELL_AURA_ADD_FLAT_MODIFIER ||
            effect.MiscValue != SPELLMOD_CHANCE_OF_SUCCESS || effect.BasePoints != 99 || effect.DieSides != 1 ||
            effect.SpellClassMask != flag96(1073741824, 0, 0) || effect.TriggerSpell ||
            effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
            return false;
    }
    return true;
}

uint64 OrdinarySpellEnd(Player* player, uint32 id, uint64 now)
{
    auto const& cooldowns = player->GetSpellCooldownMap();
    uint32 const monotonic = getMSTime();
    auto found = cooldowns.find(id);
    return found != cooldowns.end() && found->second.end > monotonic ?
        now + (found->second.end - monotonic) : 0;
}

uint64 OrdinaryEnd(Player* player, uint64 now)
{
    return std::max(OrdinarySpellEnd(player, ZENITH, now), OrdinarySpellEnd(player, ECHOES_ZENITH, now));
}

void Store(Player* player, Ledger const& ledger)
{
    std::array<uint32, 11> const values = {2, uint32(ledger.BaseUntil / 1000), uint32(ledger.BaseUntil % 1000),
        ledger.LastRecovery, uint32(ledger.ProvisionalUntil / 1000), uint32(ledger.ProvisionalUntil % 1000),
        ledger.Untracked ? 1u : 0u, uint32(ledger.OrdinaryUntil / 1000), uint32(ledger.OrdinaryUntil % 1000),
        uint32(ledger.VariantOrdinaryUntil / 1000), uint32(ledger.VariantOrdinaryUntil % 1000)};
    for (uint32 i = 0; i < values.size(); ++i)
        player->UpdatePlayerSetting(LEDGER_KEY, i, values[i]);
}

bool Read(Player* player, Ledger& ledger, uint64 now, bool synchronize = true)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(ECHOES_ZENITH);
    PlayerSettingVector const* pool = player->FindPlayerSettings(POOL_KEY);
    bool const storedPool = player->HasStoredSpellCharges(info);
    if (pool && !storedPool)
        return false;

    if (PlayerSettingVector const* values = player->FindPlayerSettings(LEDGER_KEY))
    {
        if (values->size() != 11 || (*values)[0].value != 2 || !storedPool ||
            (*values)[2].value > 999 || (*values)[5].value > 999 || (*values)[8].value > 999 ||
            (*values)[10].value > 999 ||
            (*values)[6].value > 1 || (*values)[3].value > uint32(std::numeric_limits<int32>::max()))
            return false;
        ledger.BaseUntil = uint64((*values)[1].value) * 1000 + (*values)[2].value;
        ledger.LastRecovery = (*values)[3].value;
        ledger.ProvisionalUntil = uint64((*values)[4].value) * 1000 + (*values)[5].value;
        ledger.Untracked = (*values)[6].value != 0;
        ledger.OrdinaryUntil = uint64((*values)[7].value) * 1000 + (*values)[8].value;
        ledger.VariantOrdinaryUntil = uint64((*values)[9].value) * 1000 + (*values)[10].value;
        if ((ledger.ProvisionalUntil && ledger.Untracked) || ledger.VariantOrdinaryUntil > ledger.OrdinaryUntil)
            return false;
        SpellChargeState const state = player->GetSpellCharges(info);
        if (state.Available == 2 && (ledger.Untracked || ledger.ProvisionalUntil))
        {
            ledger.Untracked = false;
            ledger.ProvisionalUntil = 0;
            if (synchronize)
                Store(player, ledger);
        }
        return true;
    }

    if (!synchronize)
        return false;
    SpellChargeState state = player->GetSpellCharges(info);
    ledger.OrdinaryUntil = OrdinaryEnd(player, now);
    ledger.VariantOrdinaryUntil = OrdinarySpellEnd(player, ECHOES_ZENITH, now);
    if (state.Available < 2)
        ledger.Untracked = true;
    else if (!storedPool && ledger.OrdinaryUntil > now)
    {
        ledger.BaseUntil = ledger.OrdinaryUntil;
        ledger.ProvisionalUntil = ledger.OrdinaryUntil;
        state = {1, ledger.OrdinaryUntil, uint32(std::min<uint64>(ledger.OrdinaryUntil - now, DAY * IN_MILLISECONDS))};
        if (!player->SetSpellCharges(info, state))
            return false;
    }
    else if (!storedPool && !player->SetSpellCharges(info, state))
        return false;

    Store(player, ledger);
    return true;
}

void SendCooldownProjection(Player* player, bool variant)
{
    if (!player->IsInWorld() || !Owns(player, ZENITH) || !HasContract())
        return;
    uint32 const id = variant ? ECHOES_ZENITH : ZENITH;
    if (!player->HasActiveSpell(id))
        return;
    uint64 const now = Now();
    Ledger ledger;
    if (!Read(player, ledger, now, false))
        return;
    uint64 until = variant ? std::max(ledger.VariantOrdinaryUntil, OrdinarySpellEnd(player, id, now)) :
        std::max({ledger.BaseUntil, ledger.OrdinaryUntil, OrdinaryEnd(player, now)});
    if (!variant)
    {
        SpellChargeState const state = player->GetSpellCharges(sSpellMgr->GetSpellInfo(ECHOES_ZENITH));
        if (!state.Available)
            until = std::max(until, state.NextRecovery);
        if (ledger.Untracked && state.Available < 2)
            until = std::max(until, state.NextRecovery + uint64(1 - state.Available) * state.RecoveryTime);
    }
    if (until <= now)
    {
        player->SendClearCooldown(id, player);
        return;
    }
    WorldPacket packet;
    player->BuildCooldownPacket(packet, SPELL_COOLDOWN_FLAG_NONE, id,
        uint32(std::min<uint64>(until - now, std::numeric_limits<uint32>::max())));
    player->SendDirectMessage(&packet);
}

bool WantsVariant(Player* player, Runtime const& runtime)
{
    return runtime.Specialization == RUNIC && Owns(player, ZENITH) && Owns(player, ECHOES);
}

void SetActive(Player* player, uint32 id, bool active)
{
    PlayerSpell* entry = CurrentSpell(player, id);
    if (!entry || entry->Active == active)
        return;
    entry->Active = active;
    if (player->IsInWorld())
        player->SendLearnPacket(id, active);
}

void MapButtons(Player* player, uint32 from, uint32 to)
{
    bool changed = false;
    for (uint8 slot = 0; slot < MAX_ACTION_BUTTONS; ++slot)
    {
        ActionButton const* button = player->GetActionButton(slot);
        if (button && button->GetType() == ACTION_BUTTON_SPELL && button->GetAction() == from)
            changed = player->addActionButton(slot, to, ACTION_BUTTON_SPELL) != nullptr || changed;
    }
    if (changed && player->IsInWorld())
        player->SendActionButtons(1);
}

void Synchronize(Player* player, Runtime& runtime)
{
    if (runtime.Busy || !HasContract())
        return;
    runtime.Busy = true;
    runtime.Pending = false;
    runtime.NativeSpec = player->GetActiveSpec();
    bool const owned = Owns(player, ZENITH);
    if (owned)
    {
        Ledger ledger;
        Read(player, ledger, Now());
    }

    bool variant = WantsVariant(player, runtime);
    if (variant)
    {
        auto found = player->GetSpellMap().find(ECHOES_ZENITH);
        if (found == player->GetSpellMap().end())
        {
            if (runtime.WasVariant)
                runtime.Pending = true;
            else
                player->addSpell(ECHOES_ZENITH, player->GetActiveSpecMask(), true, true);
        }
        else if (found->second->State == PLAYERSPELL_REMOVED)
            runtime.Pending = true;
        else if (found->second->State == PLAYERSPELL_TEMPORARY)
            found->second->specMask |= player->GetActiveSpecMask();

        variant = CurrentSpell(player, ECHOES_ZENITH) != nullptr;
    }

    if (variant)
    {
        SetActive(player, ECHOES_ZENITH, true);
        SetActive(player, ZENITH, false);
        MapButtons(player, ZENITH, ECHOES_ZENITH);
    }
    else
    {
        if (owned)
        {
            SetActive(player, ZENITH, true);
            MapButtons(player, ECHOES_ZENITH, ZENITH);
        }
        SetActive(player, ECHOES_ZENITH, false);
        player->removeSpell(ECHOES_ZENITH, player->GetActiveSpecMask(), true);
    }
    runtime.WasVariant = variant;
    SendAscensionRunemasterEchoesCooldown(player);
    runtime.Busy = false;
}

bool OrdinaryObservation(Player* player, Spell* spell)
{
    return IsRunemaster(player) && spell && !spell->m_CastItem &&
        !spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD) &&
        !spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_EFFECTS) &&
        !player->GetCommandStatus(CHEAT_COOLDOWN) && HasContract();
}

class spell_ascension_runemaster_echoes : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_echoes);

    bool Validate(SpellInfo const* info) override
    {
        return (info->Id == ZENITH || info->Id == ECHOES_ZENITH) && HasContract();
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster()->ToPlayer());
    }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!OrdinaryObservation(player, GetSpell()))
            return SPELL_CAST_OK;
        Runtime& runtime = *player->CustomData.GetDefault<Runtime>(RUNTIME_KEY);
        Synchronize(player, runtime);
        bool const variant = CurrentSpell(player, ECHOES_ZENITH) && player->HasActiveSpell(ECHOES_ZENITH);
        if (!Owns(player, ZENITH) || (GetSpellInfo()->Id == ECHOES_ZENITH) != variant)
            return SPELL_FAILED_NOT_KNOWN;
        Ledger ledger;
        uint64 const now = Now();
        if (!Read(player, ledger, now))
            return SPELL_FAILED_NOT_READY;
        SpellChargeState const state = player->GetSpellCharges(sSpellMgr->GetSpellInfo(ECHOES_ZENITH));
        if (!state.Available || (variant && ledger.VariantOrdinaryUntil > now) ||
            (!variant && (ledger.Untracked || ledger.BaseUntil > now ||
            ledger.OrdinaryUntil > now || OrdinaryEnd(player, now) > now)))
            return SPELL_FAILED_NOT_READY;
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_runemaster_echoes::CheckCast);
    }
};

class player_ascension_runemaster_echoes : public PlayerScript
{
public:
    player_ascension_runemaster_echoes() : PlayerScript("player_ascension_runemaster_echoes",
        {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_AFTER_SPEC_SLOT_CHANGED, PLAYERHOOK_ON_NORMALIZE_ACTION_BUTTON_SPELL,
         PLAYERHOOK_ON_SPELL_CHARGE_CONSUMED, PLAYERHOOK_ON_SPELL_COOLDOWN_CALCULATED}) { }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!IsRunemaster(player))
            return;
        Runtime* state = player->CustomData.Get<Runtime>(RUNTIME_KEY);
        if (!state)
            return;
        Runtime& runtime = *state;
        runtime.Elapsed = std::min(runtime.Elapsed, 1000u) + std::min(diff, 1000u);
        if (runtime.Elapsed < 1000)
            return;
        runtime.Elapsed = 0;
        if (runtime.Pending || runtime.NativeSpec != player->GetActiveSpec())
            Synchronize(player, runtime);
    }

    void OnPlayerAfterSpecSlotChanged(Player* player, uint8) override
    {
        if (!IsRunemaster(player))
            return;
        if (Runtime* runtime = player->CustomData.Get<Runtime>(RUNTIME_KEY))
            Synchronize(player, *runtime);
    }

    void OnPlayerLogout(Player* player) override
    {
        player->CustomData.Erase(RUNTIME_KEY);
    }

    void OnPlayerNormalizeActionButtonSpell(Player* player, uint32& action, bool loading) override
    {
        if (!IsRunemaster(player) || (action != ZENITH && action != ECHOES_ZENITH) ||
            !HasContract() || !Owns(player, ZENITH))
            return;
        Runtime const* runtime = player->CustomData.Get<Runtime>(RUNTIME_KEY);
        bool const variant = loading && runtime && WantsVariant(player, *runtime) &&
            player->HasActiveSpell(ECHOES_ZENITH);
        action = variant ? ECHOES_ZENITH : ZENITH;
    }

    void OnPlayerSpellChargeConsumed(Player* player, SpellInfo const* info, Spell* spell,
        uint32 recovery, uint64 now) override
    {
        if (info->Id != ECHOES_ZENITH || !OrdinaryObservation(player, spell) ||
            !spell->TryMarkScriptEventHandled(ECHOES_DEBT_EVENT))
            return;
        Ledger ledger;
        if (!Read(player, ledger, now))
            return;
        if (ledger.ProvisionalUntil)
        {
            SpellChargeState state = player->GetSpellCharges(info);
            if (state.NextRecovery == ledger.ProvisionalUntil)
            {
                state.RecoveryTime = recovery;
                if (!player->SetSpellCharges(info, state))
                    return;
            }
            ledger.ProvisionalUntil = 0;
        }
        ledger.BaseUntil = now + recovery;
        ledger.LastRecovery = recovery;
        Store(player, ledger);
    }

    void OnPlayerSpellCooldownCalculated(Player* player, SpellInfo const* info, Spell* spell,
        uint32 recovery) override
    {
        if (info->Id == ECHOES_ZENITH && recovery && OrdinaryObservation(player, spell) &&
            spell->TryMarkScriptEventHandled(ECHOES_ORDINARY_EVENT))
        {
            uint64 const now = Now();
            Ledger ledger;
            if (Read(player, ledger, now))
            {
                ledger.OrdinaryUntil = std::max(ledger.OrdinaryUntil, now + recovery);
                ledger.VariantOrdinaryUntil = std::max(ledger.VariantOrdinaryUntil, now + recovery);
                Store(player, ledger);
            }
            return;
        }
        if (info->Id != ZENITH || !OrdinaryObservation(player, spell) ||
            !spell->TryMarkScriptEventHandled(ECHOES_DEBT_EVENT))
            return;
        uint64 const now = Now();
        Ledger ledger;
        if (!Read(player, ledger, now))
            return;
        if (recovery)
        {
            SpellInfo const* canonical = sSpellMgr->GetSpellInfo(ECHOES_ZENITH);
            SpellChargeState state = player->GetSpellCharges(canonical);
            if (!state.Consume(2, std::min(recovery, uint32(DAY * IN_MILLISECONDS)), now) ||
                !player->SetSpellCharges(canonical, state))
                return;
        }
        ledger.BaseUntil = now + recovery;
        ledger.OrdinaryUntil = now + recovery;
        ledger.LastRecovery = recovery;
        ledger.ProvisionalUntil = 0;
        Store(player, ledger);
    }
};
}

void SynchronizeAscensionRunemasterEchoes(Player* player, uint32 specializationId)
{
    if (!IsRunemaster(player))
        return;
    Runtime& runtime = *player->CustomData.GetDefault<Runtime>(RUNTIME_KEY);
    runtime.Specialization = specializationId;
    Synchronize(player, runtime);
}

void SendAscensionRunemasterEchoesCooldown(Player* player)
{
    if (!IsRunemaster(player) || !player->GetSession())
        return;
    Runtime const* runtime = player->CustomData.Get<Runtime>(RUNTIME_KEY);
    uint32 const specialization = runtime ? runtime->Specialization : 0;
    bool const active = Owns(player, ZENITH) && specialization == RUNIC && Owns(player, ECHOES) &&
        player->HasActiveSpell(ECHOES_ZENITH);
    SendCooldownProjection(player, active);
}

void AddAscensionRunemasterEchoesScripts()
{
    RegisterSpellScript(spell_ascension_runemaster_echoes);
    new player_ascension_runemaster_echoes();
}
