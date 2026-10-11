/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFreepick.h"
#include "AscensionWarcraftRebornRules.h"
#include "DBCStores.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Trainer.h"
#include "World.h"
#include <algorithm>
#include <map>

namespace AscensionWarcraftReborn
{
namespace
{
Data Loaded;
AscensionFreepick::Realm CurrentRealm;
bool RebornRealm = false;
std::unordered_map<uint32, Trainer::Trainer> Trainers;

bool StockClass(uint32 classId)
{
    return classId >= CLASS_WARRIOR && classId <= CLASS_DRUID && classId != CLASS_HERO;
}

bool IsRebornPlayer(Player const* player)
{
    return RebornRealm && StockClass(player->getClass());
}

bool Exists(uint32 spellId)
{
    return sSpellMgr->GetSpellInfo(spellId) != nullptr;
}

std::optional<SpellLayout> LayoutOf(std::uint32_t spellId)
{
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo)
        return std::nullopt;
    SpellLayout layout;
    layout.Name = spellInfo->SpellName[0];
    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
    {
        layout.Effects[i] = spellInfo->Effects[i].Effect;
        layout.Auras[i] = spellInfo->Effects[i].ApplyAuraName;
    }
    return layout;
}

std::vector<std::pair<uint32, uint32>> BaseTwins;

std::vector<std::pair<uint32, uint32>> LoadNamesakes()
{
    if (!AscensionFreepick::ReadRealm().WarcraftReborn)
        return {};
    return SpellNamesakes(sSpellMgr->GetSpellInfoStoreSize(), &LayoutOf);
}

std::vector<std::pair<uint32, uint32>> LoadTwins(bool ranked)
{
    if (!ranked)
    {
        BaseTwins.clear();
        if (AscensionFreepick::ReadRealm().WarcraftReborn)
            BaseTwins = SpellTwins(sSpellMgr->GetSpellInfoStoreSize(), &LayoutOf);
        return BaseTwins;
    }
    if (!RebornRealm)
        return {};
    return RankTwins(BaseTwins,
        [](std::uint32_t spellId)
        {
            std::vector<std::uint32_t> ranks;
            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
            for (spellInfo = spellInfo ? spellInfo->GetNextRankSpell() : nullptr; spellInfo; spellInfo = spellInfo->GetNextRankSpell())
                ranks.push_back(spellInfo->Id);
            return ranks;
        },
        [](std::uint32_t spellId) { return sSpellMgr->GetFirstSpellInChain(spellId); }, &LayoutOf);
}

std::vector<std::vector<uint32>> LoadRankChains()
{
    CurrentRealm = AscensionFreepick::ReadRealm();
    RebornRealm = CurrentRealm.WarcraftReborn;
    if (!RebornRealm)
        return {};
    if (!LoadData(Loaded))
    {
        LOG_ERROR("coa", "Warcraft Reborn class spells are unavailable: their client DBCs did not load");
        RebornRealm = false;
        return {};
    }
    return RankChains(Loaded);
}

TrainerSpell FromTrainer(Trainer::Spell const& spell)
{
    TrainerSpell row;
    row.SpellId = spell.SpellId;
    row.MoneyCost = spell.MoneyCost;
    row.ReqSkillLine = spell.ReqSkillLine;
    row.ReqSkillRank = spell.ReqSkillRank;
    std::copy(spell.ReqAbility.begin(), spell.ReqAbility.end(), row.ReqAbility.begin());
    row.ReqLevel = spell.ReqLevel;
    return row;
}

Trainer::Spell ToTrainer(TrainerSpell const& row)
{
    Trainer::Spell spell;
    spell.SpellId = row.SpellId;
    spell.MoneyCost = row.MoneyCost;
    spell.ReqSkillLine = row.ReqSkillLine;
    spell.ReqSkillRank = row.ReqSkillRank;
    std::copy(row.ReqAbility.begin(), row.ReqAbility.end(), spell.ReqAbility.begin());
    spell.ReqLevel = uint8(row.ReqLevel);
    return spell;
}

void BuildTrainers()
{
    for (auto const& [trainerId, trainer] : sObjectMgr->GetTrainers())
    {
        uint32 const classId = trainer.GetTrainerRequirement();
        if (trainer.GetTrainerType() != Trainer::Type::Class || !StockClass(classId))
            continue;

        std::vector<TrainerSpell> stock;
        std::map<uint32, uint32> prices;
        for (Trainer::Spell const& spell : trainer.GetSpells())
        {
            stock.push_back(FromTrainer(spell));
            prices[spell.ReqLevel] = std::max(prices[spell.ReqLevel], spell.MoneyCost);
        }
        auto const reborn = [&prices](uint32 spellId)
        {
            SpellInfo const* info = sSpellMgr->AssertSpellInfo(spellId);
            TrainerSpell row;
            row.SpellId = spellId;
            row.ReqLevel = std::clamp<uint32>(info->SpellLevel, 1, 255);
            auto const price = prices.upper_bound(row.ReqLevel);
            row.MoneyCost = price == prices.begin() ? 0 : std::prev(price)->second;
            return row;
        };

        std::vector<Trainer::Spell> spells;
        for (TrainerSpell const& row : TrainerSpells(Loaded, CurrentRealm, classId, stock, Exists, reborn))
            spells.push_back(ToTrainer(row));
        Trainers.emplace(trainerId, trainer.WithSpells(std::move(spells)));
    }
    LOG_INFO("coa", "Warcraft Reborn: {} class trainers teach Reborn spells", Trainers.size());
}

Trainer::Trainer* TrainerFor(Trainer::Trainer const& trainer, Player const* player)
{
    if (!IsRebornPlayer(player))
        return nullptr;
    auto const reborn = Trainers.find(trainer.GetTrainerId());
    return reborn == Trainers.end() ? nullptr : &reborn->second;
}

bool KnowsAnyRank(Player const* player, uint32 spellId)
{
    if (std::vector<uint32> const* ladder = Loaded.LadderOf(spellId))
        return std::any_of(ladder->begin(), ladder->end(), [player](uint32 rank) { return player->HasSpell(rank); });
    return player->HasSpell(spellId);
}

void LearnMissing(Player* player, std::vector<uint32> const& spells)
{
    for (uint32 spellId : spells)
        if (Exists(spellId) && !KnowsAnyRank(player, spellId))
            player->learnSpell(spellId);
}

void LearnClassSkills(Player* player)
{
    for (uint32 skillId : ClassSkillLines(Loaded, CurrentRealm, player->getClass()))
    {
        SkillLineEntry const* skill = sSkillLineStore.LookupEntry(skillId);
        if (skill && skill->categoryId == SKILL_CATEGORY_CLASS && !player->HasSkill(skillId))
            player->LearnDefaultSkill(skillId, 0);
    }
}

uint32 StartLevel(Player const* player)
{
    return player->getClass() == CLASS_DEATH_KNIGHT ? sWorld->getIntConfig(CONFIG_START_HEROIC_PLAYER_LEVEL) :
        sWorld->getIntConfig(CONFIG_START_PLAYER_LEVEL);
}

void UseRebornSpellsOnActionBars(Player* player)
{
    bool changed = false;
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        if (!action || action->GetType() != ACTION_BUTTON_SPELL)
            continue;
        uint32 const reborn = RebornSpell(action->GetAction(), Exists);
        if (reborn == action->GetAction() || !player->HasSpell(reborn))
            continue;
        player->addActionButton(button, reborn, ACTION_BUTTON_SPELL);
        changed = true;
    }
    if (changed)
        player->SendActionButtons(1);
}

uint32 RankAtLevel(uint32 firstRank, uint8 level)
{
    uint32 rank = 0;
    for (SpellInfo const* info = sSpellMgr->GetSpellInfo(firstRank); info && info->SpellLevel <= level;
        info = info->GetNextRankSpell())
        rank = info->Id;
    return rank;
}

void RemoveGrantedSpells(Player* player, Grant const& grant)
{
    for (uint32 firstRank : grant.Spells)
        for (SpellInfo const* info = sSpellMgr->GetSpellInfo(firstRank); info; info = info->GetNextRankSpell())
            if (player->HasSpell(info->Id))
                player->removeSpell(info->Id, SPEC_MASK_ALL, false);
}

void LearnGrantedSpells(Player* player)
{
    for (Grant const& grant : Grants())
        if (player->HasSpell(grant.Source))
            for (uint32 firstRank : grant.Spells)
                if (uint32 const rank = RankAtLevel(firstRank, player->GetLevel()); rank && !player->HasSpell(rank))
                    player->learnSpell(rank);
}

Grant const* GrantOf(uint32 spellId)
{
    auto const grant = std::find_if(Grants().begin(), Grants().end(),
        [spellId](Grant const& candidate) { return candidate.Source == spellId; });
    return grant == Grants().end() ? nullptr : &*grant;
}

class spell_ascension_reborn_dark_apotheosis_only : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_dark_apotheosis_only);

    SpellCastResult CheckForm()
    {
        return GetCaster()->HasAura(DARK_APOTHEOSIS) ? SPELL_CAST_OK : SPELL_FAILED_ONLY_SHAPESHIFT;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_reborn_dark_apotheosis_only::CheckForm);
    }
};

class aura_ascension_reborn_dark_apotheosis : public AuraScript
{
    PrepareAuraScript(aura_ascension_reborn_dark_apotheosis);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ DARK_APOTHEOSIS_PASSIVES[0], DARK_APOTHEOSIS_PASSIVES[1] });
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        for (uint32 passive : DARK_APOTHEOSIS_PASSIVES)
            GetTarget()->CastSpell(GetTarget(), passive, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        for (uint32 passive : DARK_APOTHEOSIS_PASSIVES)
            GetTarget()->RemoveAurasDueToSpell(passive, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reborn_dark_apotheosis::Apply, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reborn_dark_apotheosis::Remove, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};

class AscensionWarcraftRebornPlayer final : public PlayerScript
{
public:
    AscensionWarcraftRebornPlayer() : PlayerScript("AscensionWarcraftRebornPlayer",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!IsRebornPlayer(player))
            return;
        LearnClassSkills(player);
        LearnMissing(player, StartingSpells(Loaded, CurrentRealm, player->getClass(), StartLevel(player)));
        LearnMissing(player, AutomaticSpells(Loaded, CurrentRealm, player->getClass(), player->GetLevel()));
        LearnGrantedSpells(player);
        if (player->HasAtLoginFlag(AT_LOGIN_FIRST))
            UseRebornSpellsOnActionBars(player);
    }

    void OnPlayerLevelChanged(Player* player, uint8) override
    {
        if (!IsRebornPlayer(player))
            return;
        LearnMissing(player, AutomaticSpells(Loaded, CurrentRealm, player->getClass(), player->GetLevel()));
        LearnGrantedSpells(player);
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (GrantOf(spellId) && IsRebornPlayer(player))
            LearnGrantedSpells(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        if (Grant const* grant = GrantOf(spellId); grant && IsRebornPlayer(player))
            RemoveGrantedSpells(player, *grant);
    }
};

class AscensionWarcraftRebornWorld final : public WorldScript
{
public:
    AscensionWarcraftRebornWorld() : WorldScript("AscensionWarcraftRebornWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        if (RebornRealm)
            BuildTrainers();
    }
};
}
}

class spell_ascension_reborn_proc_trigger_spell : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_proc_trigger_spell);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        uint32 const triggered = aurEff->GetSpellInfo()->Effects[aurEff->GetEffIndex()].TriggerSpell;
        Unit* target = eventInfo.GetProcTarget();
        if (triggered && target)
            GetTarget()->CastSpell(target, triggered, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_proc_trigger_spell::HandleProc, EFFECT_ALL, SPELL_AURA_DUMMY);
    }
};

void AddAscensionWarcraftRebornScripts()
{
    RegisterSpellScript(spell_ascension_reborn_proc_trigger_spell);
    new AscensionWarcraftReborn::AscensionWarcraftRebornPlayer();
    new AscensionWarcraftReborn::AscensionWarcraftRebornWorld();
    RegisterSpellScriptWithArgs(AscensionWarcraftReborn::spell_ascension_reborn_dark_apotheosis_only,
        "spell_ascension_reborn_dark_apotheosis_only");
    RegisterSpellScriptWithArgs(AscensionWarcraftReborn::aura_ascension_reborn_dark_apotheosis,
        "aura_ascension_reborn_dark_apotheosis");
    sSpellMgr->SetAddedSpellRanks(&AscensionWarcraftReborn::LoadRankChains);
    sSpellMgr->SetSpellTwins(&AscensionWarcraftReborn::LoadTwins);
    sSpellMgr->SetSpellNamesakes(&AscensionWarcraftReborn::LoadNamesakes);
    Trainer::SetClassTrainerFor(&AscensionWarcraftReborn::TrainerFor);
}
