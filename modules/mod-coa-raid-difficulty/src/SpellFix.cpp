/*
 * Corrections to Ascension spell values that are plainly wrong in its DBC.
 *
 * Some tier variants break their own row: Razorgore's War Stomp does 467, 588
 * and 692 on Normal, Heroic and Mythic, then 3500 on Ascended. Fireball Storm
 * does less on Ascended than on Mythic. Every other spell steps up by a steady
 * factor, so these read as typos, and coa_spell_fix sets them to what the step
 * of their own row predicts.
 *
 * The server's Spell.dbc stays untouched; the values are patched into the
 * loaded spell data once at startup. The client still shows the old number in
 * its tooltip. The damage is right.
 *
 * `value` is the number as the DBC shows it (base points + 1, the same way
 * spell catalogues print it).
 */

#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

namespace
{
    class coa_spell_fix_loader : public WorldScript
    {
    public:
        coa_spell_fix_loader() : WorldScript("coa_spell_fix_loader") { }

        void OnStartup() override
        {
            uint32 applied = 0;
            if (QueryResult result = WorldDatabase.Query("SELECT spell_id, effect_index, value FROM coa_spell_fix"))
            {
                do
                {
                    Field* f = result->Fetch();
                    uint32 const spellId = f[0].Get<uint32>();
                    uint8 const effect = f[1].Get<uint8>();
                    int32 const value = f[2].Get<int32>();

                    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
                    if (!info || effect >= MAX_SPELL_EFFECTS)
                    {
                        LOG_ERROR("sql.sql", "coa_spell_fix: spell {} effect {} does not exist", spellId, effect);
                        continue;
                    }

                    // The loaded spell data is shared and immutable by design;
                    // this runs once, before anyone can cast.
                    const_cast<SpellInfo*>(info)->Effects[effect].BasePoints = value - 1;
                    ++applied;
                } while (result->NextRow());
            }
            LOG_INFO("server.loading", ">> Applied {} spell value corrections", applied);
        }
    };

    class coa_dragon_sleep_mechanic : public GlobalScript
    {
    public:
        coa_dragon_sleep_mechanic() : GlobalScript("coa_dragon_sleep_mechanic",
            {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

        void OnLoadSpellCustomAttr(SpellInfo* info) override
        {
            if (info->Id != 2119419 && info->Id != 2119519 && info->Id != 2119619 && info->Id != 2119719)
                return;

            info->Mechanic = MECHANIC_SLEEP;
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsEffect())
                    effect.Mechanic = MECHANIC_SLEEP;
        }
    };

    class coa_spectral_bomb_interrupt : public GlobalScript
    {
    public:
        coa_spectral_bomb_interrupt() : GlobalScript("coa_spectral_bomb_interrupt",
            {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

        void OnLoadSpellCustomAttr(SpellInfo* info) override
        {
            if (info->Id == 2119819)
                info->InterruptFlags |= SPELL_INTERRUPT_FLAG_INTERRUPT;
            else if (info->Id == 2119845 || info->Id == 2146711)
            {
                info->AttributesEx2 |= SPELL_ATTR2_IGNORE_LINE_OF_SIGHT;
                info->DurationEntry = sSpellDurationStore.LookupEntry(21);
            }
            else if (info->Id == 2119810)
                info->Effects[1].Effect = SpellEffects(0);
        }
    };

    // Live, Mandokir's Decapitate landed 12 of 12 and his Mortal Strike hit
    // about 123 of 123 with no dodge, parry or miss, while the same tanks
    // dodged about 45% of his swings; the DBC flags neither as unavoidable.
    class coa_mandokir_unavoidable_strikes : public GlobalScript
    {
    public:
        coa_mandokir_unavoidable_strikes() : GlobalScript("coa_mandokir_unavoidable_strikes",
            {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

        void OnLoadSpellCustomAttr(SpellInfo* info) override
        {
            if (info->Id == 2118402 || info->Id == 2118410)
                info->AttributesEx3 |= SPELL_ATTR3_ALWAYS_HIT;
        }
    };
}

void AddCoaSpellFixScripts()
{
    new coa_spell_fix_loader();
    new coa_dragon_sleep_mechanic();
    new coa_spectral_bomb_interrupt();
    new coa_mandokir_unavoidable_strikes();
}
