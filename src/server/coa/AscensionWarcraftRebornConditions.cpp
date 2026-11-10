#include "AscensionWarcraftReborn.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "Unit.h"
#include <array>

namespace
{
    constexpr std::array<uint32, 2> MOLTEN_FURY = { 1131679, 1131680 };
    constexpr std::array<uint32, 3> HUNTING_FOR_SPORT = { 1119183, 1119186, 1119187 };
    constexpr std::array<uint32, 3> REND_AND_TEAR = { 1148432, 1148433, 1148434 };
    constexpr std::array<uint32, 3> NOXIOUS_STINGS = { 1153295, 1153296, 1153297 };
    constexpr std::array<uint32, 3> IMPROVED_INSECT_SWARM = { 1157849, 1157850, 1157851 };

    flag96 const WYVERN_STING_FLAGS(0, 0x00001000, 0);
    flag96 const INSECT_SWARM_FLAGS(0x00200000, 0, 0);
    flag96 const WRATH_FLAGS(0x00000001, 0, 0);
    flag96 const MAUL_SHRED_FLAGS(0x00008800, 0, 0);
    flag96 const TRAP_EFFECT_FLAGS(0x00000018, 0, 0);
    flag96 const BLIZZARD_FLAGS(0x00000080, 0, 0);
    constexpr std::array<uint32, 2> POINT_OF_NO_ESCAPE = { 1153298, 1153299 };
    constexpr std::array<uint32, 3> IMPROVED_BLIZZARD = { 1111185, 1112487, 1112488 };
    constexpr std::array<uint32, 3> CHILLED = { 12484, 12485, 12486 };

    template <std::size_t N>
    int32 RankAmount(Unit const* unit, std::array<uint32, N> const& ranks, SpellEffIndex effect)
    {
        for (uint32 spellId : ranks)
            if (AuraEffect const* aurEff = unit->GetAuraEffect(spellId, effect))
                return aurEff->GetAmount();
        return 0;
    }

    bool HasOwnAura(Unit const* target, Unit const* caster, SpellFamilyNames family, flag96 const& flags)
    {
        for (auto const& [id, application] : target->GetAppliedAuras())
        {
            SpellInfo const* info = application->GetBase()->GetSpellInfo();
            if (application->GetBase()->GetCasterGUID() == caster->GetGUID() && info->SpellFamilyName == family &&
                (info->SpellFamilyFlags & flags))
                return true;
        }
        return false;
    }

    bool Matches(SpellInfo const* spellInfo, SpellFamilyNames family, flag96 const& flags)
    {
        return spellInfo && spellInfo->SpellFamilyName == family && (spellInfo->SpellFamilyFlags & flags);
    }
}

class AscensionWarcraftRebornDamageConditions : public UnitScript
{
public:
    AscensionWarcraftRebornDamageConditions() : UnitScript("AscensionWarcraftRebornDamageConditions", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (!target || !attacker || !spellInfo || damage <= 0 || !attacker->IsPlayer() || target == attacker)
            return;

        int32 pct = 0;
        bool const below35 = target->HealthBelowPct(35);
        if (below35)
            pct += RankAmount(attacker, MOLTEN_FURY, EFFECT_0);
        if (below35 && spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE)
            pct += RankAmount(attacker, HUNTING_FOR_SPORT, EFFECT_0);
        if (Matches(spellInfo, SPELLFAMILY_DRUID, MAUL_SHRED_FLAGS) && target->HasAuraState(AURA_STATE_BLEEDING))
            pct += RankAmount(attacker, REND_AND_TEAR, EFFECT_0);
        if (HasOwnAura(target, attacker, SPELLFAMILY_HUNTER, WYVERN_STING_FLAGS))
            pct += RankAmount(attacker, NOXIOUS_STINGS, EFFECT_0);
        if (Matches(spellInfo, SPELLFAMILY_DRUID, WRATH_FLAGS) &&
            HasOwnAura(target, attacker, SPELLFAMILY_DRUID, INSECT_SWARM_FLAGS))
            pct += RankAmount(attacker, IMPROVED_INSECT_SWARM, EFFECT_0);

        if (pct)
            AddPct(damage, pct);
    }
};

class AscensionWarcraftRebornSpellConditions : public AllSpellScript
{
public:
    AscensionWarcraftRebornSpellConditions() : AllSpellScript("AscensionWarcraftRebornSpellConditions",
        { ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_HIT_RESULT }) { }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Unit* caster = spell->GetCaster();
        if (caster && target && caster->IsPlayer() && HasOwnAura(target, caster, SPELLFAMILY_HUNTER, TRAP_EFFECT_FLAGS))
            chance += float(RankAmount(caster, POINT_OF_NO_ESCAPE, EFFECT_0));
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 missInfo, uint32 damage, uint32, bool) override
    {
        Unit* caster = spell->GetCaster();
        if (!caster || !target || missInfo != SPELL_MISS_NONE || !damage || !caster->IsPlayer() ||
            !Matches(spell->GetSpellInfo(), SPELLFAMILY_MAGE, BLIZZARD_FLAGS))
            return;
        for (std::size_t rank = 0; rank < IMPROVED_BLIZZARD.size(); ++rank)
            if (caster->HasAura(IMPROVED_BLIZZARD[rank]))
            {
                caster->CastSpell(target, sSpellMgr->GetSpellTwinFor(CHILLED[rank], IMPROVED_BLIZZARD[rank]), true);
                return;
            }
    }
};

void AddAscensionWarcraftRebornConditionScripts()
{
    new AscensionWarcraftRebornDamageConditions();
    new AscensionWarcraftRebornSpellConditions();
}
