/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTankStances.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include <algorithm>
#include <array>
#include <iterator>
#include <unordered_map>

namespace
{
    constexpr uint32 SPELL_TANK_STANCE_CRIT_REDUCTION = Ascension::TANK_STANCE_CRIT_REDUCTION_AURA;
    constexpr uint32 SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA = 807726;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH = 92144;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH_HELPER = 805098;
    constexpr uint32 SPELL_PALADIN_RIGHTEOUS_FURY = 25780;
    constexpr uint32 SPELL_PALADIN_RIGHTEOUS_FURY_REBORN = 1125780;
    constexpr uint8 PALADIN_PROTECTION_TAB_PAGE = 1;
    constexpr uint8 TALENT_TAB_PAGES = 3;
    constexpr uint32 PALADIN_TALENT_CLASS_MASK = 1 << (CLASS_PALADIN - 1);
    constexpr uint32 HERO_TALENT_RESYNC_INTERVAL_MS = 1000;

    struct StockTankStance
    {
        uint8 classId;
        uint32 spellId;
    };

    constexpr std::array<StockTankStance, 6> STOCK_TANK_STANCES = {{
        {CLASS_WARRIOR, 71}, {CLASS_WARRIOR, 1100071},
        {CLASS_DRUID, 5487}, {CLASS_DRUID, 1105487}, {CLASS_DRUID, 9634}, {CLASS_DRUID, 1109634},
    }};

    bool IsStockTankStanceAura(uint32 spellId)
    {
        return std::ranges::any_of(STOCK_TANK_STANCES,
            [spellId](StockTankStance const& stance) { return stance.spellId == spellId; });
    }

    bool HoldsStockTankStance(Player const* player)
    {
        uint8 const classId = player->getClass();
        return std::ranges::any_of(STOCK_TANK_STANCES, [player, classId](StockTankStance const& stance)
            { return (stance.classId == classId || classId == CLASS_HERO) && player->HasAura(stance.spellId); });
    }

    bool IsRighteousFury(uint32 spellId)
    {
        return spellId == SPELL_PALADIN_RIGHTEOUS_FURY || spellId == SPELL_PALADIN_RIGHTEOUS_FURY_REBORN;
    }

    TalentTabEntry const* PaladinTalentTab(TalentSpellPos const& position)
    {
        TalentEntry const* talent = sTalentStore.LookupEntry(position.talent_id);
        TalentTabEntry const* tab = talent ? sTalentTabStore.LookupEntry(talent->TalentTab) : nullptr;
        if (!tab || !(tab->ClassMask & PALADIN_TALENT_CLASS_MASK) || tab->tabpage >= TALENT_TAB_PAGES)
            return nullptr;
        return tab;
    }

    uint8 HeroPaladinMostPointsTabPage(Player const* player)
    {
        struct TalentPoints
        {
            uint8 tabPage;
            uint8 points;
        };

        std::unordered_map<uint32, TalentPoints> talents;
        uint8 const activeSpec = player->GetActiveSpec();
        for (auto const& [spellId, spell] : player->GetSpellMap())
        {
            if (spell->State == PLAYERSPELL_REMOVED || !spell->IsInSpec(activeSpec))
                continue;
            TalentSpellPos const* position = GetTalentSpellPos(spellId);
            TalentTabEntry const* tab = position ? PaladinTalentTab(*position) : nullptr;
            if (!tab)
                continue;
            TalentPoints& talent = talents.try_emplace(position->talent_id, TalentPoints{uint8(tab->tabpage), 0})
                .first->second;
            talent.points = std::max(talent.points, uint8(position->rank + 1));
        }

        std::array<uint32, TALENT_TAB_PAGES> pagePoints{};
        for (auto const& [talentId, talent] : talents)
            pagePoints[talent.tabPage] += talent.points;
        return uint8(std::distance(pagePoints.begin(), std::ranges::max_element(pagePoints)));
    }

    uint8 PaladinMostPointsTabPage(Player const* player)
    {
        return player->getClass() == CLASS_HERO ? HeroPaladinMostPointsTabPage(player) :
            player->GetMostPointsTalentTree();
    }

    bool HoldsProtectionRighteousFury(Player const* player)
    {
        uint8 const classId = player->getClass();
        return (classId == CLASS_PALADIN || classId == CLASS_HERO) &&
            (player->HasAura(SPELL_PALADIN_RIGHTEOUS_FURY) || player->HasAura(SPELL_PALADIN_RIGHTEOUS_FURY_REBORN)) &&
            PaladinMostPointsTabPage(player) == PALADIN_PROTECTION_TAB_PAGE;
    }

    bool IsResyncTrigger(uint32 spellId)
    {
        return Ascension::IsTankStanceAura(spellId) || IsStockTankStanceAura(spellId) || IsRighteousFury(spellId) ||
            spellId == SPELL_VENOMANCER_EXPOSED_FLESH || spellId == SPELL_VENOMANCER_EXPOSED_FLESH_HELPER;
    }

    bool IsHeroRighteousFuryHolder(Player const* player)
    {
        return player->getClass() == CLASS_HERO &&
            (player->HasAura(SPELL_PALADIN_RIGHTEOUS_FURY) || player->HasAura(SPELL_PALADIN_RIGHTEOUS_FURY_REBORN));
    }

    bool CrossesHeroTalentResyncTick(uint32 diff)
    {
        uint64 const now = uint64(GameTime::GetGameTimeMS().count());
        return now / HERO_TALENT_RESYNC_INTERVAL_MS != (now - std::min<uint64>(now, diff)) / HERO_TALENT_RESYNC_INTERVAL_MS;
    }

    bool HasFortitudeBeetleForm(Player const* player)
    {
        return player->HasAura(SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA) &&
            (player->HasAura(SPELL_VENOMANCER_EXPOSED_FLESH) || player->HasSpell(SPELL_VENOMANCER_EXPOSED_FLESH));
    }

    bool HoldsCritReductionStance(Player const* player)
    {
        for (auto const& [spellId, application] : player->GetAppliedAuras())
            if (spellId != SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA && Ascension::IsTankStanceAura(spellId))
                return true;
        return HasFortitudeBeetleForm(player) || HoldsStockTankStance(player) || HoldsProtectionRighteousFury(player);
    }

    void SyncCritReduction(Player* player)
    {
        bool const wanted = HoldsCritReductionStance(player);
        bool const present = player->HasAura(SPELL_TANK_STANCE_CRIT_REDUCTION);
        if (wanted && !present)
            player->AddAura(SPELL_TANK_STANCE_CRIT_REDUCTION, player);
        else if (!wanted && present)
            player->RemoveAurasDueToSpell(SPELL_TANK_STANCE_CRIT_REDUCTION);
    }
}

class ascension_tank_stance_crit_reduction : public UnitScript
{
public:
    ascension_tank_stance_crit_reduction() : UnitScript("ascension_tank_stance_crit_reduction", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (Player* player = unit ? unit->ToPlayer() : nullptr; player && aura && IsResyncTrigger(aura->GetId()))
            SyncCritReduction(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (Player* player = unit ? unit->ToPlayer() : nullptr;
            player && application && IsResyncTrigger(application->GetBase()->GetId()))
            SyncCritReduction(player);
    }
};

class ascension_tank_stance_crit_reduction_talents : public PlayerScript
{
public:
    ascension_tank_stance_crit_reduction_talents() : PlayerScript("ascension_tank_stance_crit_reduction_talents",
        {PLAYERHOOK_ON_PLAYER_LEARN_TALENTS, PLAYERHOOK_ON_FREE_TALENT_POINTS_CHANGED,
            PLAYERHOOK_ON_AFTER_SPEC_SLOT_CHANGED, PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerLearnTalents(Player* player, uint32, uint32, uint32) override
    {
        SyncRighteousFuryHolder(player);
    }

    void OnPlayerFreeTalentPointsChanged(Player* player, uint32) override
    {
        SyncRighteousFuryHolder(player);
    }

    void OnPlayerAfterSpecSlotChanged(Player* player, uint8) override
    {
        SyncRighteousFuryHolder(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (player && IsHeroRighteousFuryHolder(player) && CrossesHeroTalentResyncTick(diff))
            SyncCritReduction(player);
    }

private:
    static void SyncRighteousFuryHolder(Player* player)
    {
        if (player && (player->getClass() == CLASS_PALADIN || player->getClass() == CLASS_HERO))
            SyncCritReduction(player);
    }
};

void AddSC_AscensionTankStanceCritReduction()
{
    new ascension_tank_stance_crit_reduction();
    new ascension_tank_stance_crit_reduction_talents();
}
