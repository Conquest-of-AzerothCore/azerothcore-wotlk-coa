/*
 * Molten Core "Damage Info" spell damage.
 *
 * CoA bosses in Molten Core cast a dummy followed by an effect spell whose DBC
 * base points are a placeholder (school damage or periodic damage, base points
 * 1, so the effect deals ~2 damage today). The original server read the real
 * number from a companion aura named "<Boss> - <Spell> Damage Info", one per
 * difficulty (D0..D3), whose own base points (+1) are the intended damage.
 * That script is gone; coa_spell_damage_info restores the mapping from
 * effect spell to its four info spells, and this file reads it back in at
 * cast time.
 *
 * The difficulty picked is the caster's map difficulty (Normal/Heroic/Mythic/
 * Ascended); a non-raid map uses the Normal row.
 */

#include "DatabaseEnv.h"
#include "DBCEnums.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <optional>
#include <unordered_map>

namespace
{
    struct DamageInfoRow
    {
        uint32 infoSpellId[MAX_RAID_DIFFICULTY];
    };

    std::unordered_map<uint32, DamageInfoRow> g_damageInfo;

    void LoadDamageInfo()
    {
        g_damageInfo.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT spell_id, info_d0, info_d1, info_d2, info_d3 FROM coa_spell_damage_info"))
        {
            do
            {
                Field* f = result->Fetch();
                DamageInfoRow& row = g_damageInfo[f[0].Get<uint32>()];
                for (uint8 i = 0; i < MAX_RAID_DIFFICULTY; ++i)
                    row.infoSpellId[i] = f[1 + i].Get<uint32>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} Molten Core damage info spells", uint32(g_damageInfo.size()));
    }

    std::optional<int32> ResolveDamage(uint32 effectSpellId, Unit* caster)
    {
        auto const it = g_damageInfo.find(effectSpellId);
        if (it == g_damageInfo.end())
            return std::nullopt;

        uint8 mode = 0;
        if (caster && caster->GetMap() && caster->GetMap()->IsRaid())
            mode = std::min<uint8>(caster->GetMap()->GetSpawnMode(), MAX_RAID_DIFFICULTY - 1);

        SpellInfo const* info = sSpellMgr->GetSpellInfo(it->second.infoSpellId[mode]);
        if (!info)
            return std::nullopt;

        return info->Effects[EFFECT_0].CalcValue(caster);
    }

    class spell_coa_damage_info_hit : public SpellScript
    {
        PrepareSpellScript(spell_coa_damage_info_hit);

        void SetDamage(SpellEffIndex /*effIndex*/)
        {
            std::optional<int32> const amount = ResolveDamage(GetSpellInfo()->Id, GetCaster());
            if (amount)
                SetHitDamage(*amount);
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_coa_damage_info_hit::SetDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        }
    };

    class spell_coa_damage_info_periodic : public AuraScript
    {
        PrepareAuraScript(spell_coa_damage_info_periodic);

        void CalculateAmount(AuraEffect const* /*aurEff*/, int32& amount, bool& canBeRecalculated)
        {
            canBeRecalculated = false;
            std::optional<int32> const value = ResolveDamage(GetSpellInfo()->Id, GetCaster());
            if (value)
                amount = *value;
        }

        void Register() override
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_damage_info_periodic::CalculateAmount, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
        }
    };

    class coa_damage_info_loader : public WorldScript
    {
    public:
        coa_damage_info_loader() : WorldScript("coa_damage_info_loader") { }

        void OnStartup() override
        {
            LoadDamageInfo();
        }
    };
}

void AddCoaDamageInfoScripts()
{
    RegisterSpellScript(spell_coa_damage_info_hit);
    RegisterSpellScript(spell_coa_damage_info_periodic);
    new coa_damage_info_loader();
}
