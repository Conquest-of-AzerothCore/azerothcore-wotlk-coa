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
}

void AddCoaSpellFixScripts()
{
    new coa_spell_fix_loader();
}
