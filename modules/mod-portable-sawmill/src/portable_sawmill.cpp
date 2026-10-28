/* mod-portable-sawmill - the sawmill a player carries.
 *
 * Woodworking's five Refine spells want a sawmill, and two things in the realm
 * supply one on demand:
 *
 *     item 1777064 "Portable Sawmill"  -> spell 9931368 "Summon Portable Sawmill"         -> 2201004, five minutes
 *     Tinker spell 804707              -> "Build: Portable Sawmill"                        -> 2201005, two minutes
 *     spell 9931369 "Summon Compact Portable Sawmill" (no item ships with it)              -> 2201005
 *
 * Both of those gameobjects are the realm's own, recovered from the live client
 * caches in every realm's `gameobjectcache.wdb`: type 8 spell focus, display
 * 1015620 (world\expansion05\doodads\human\doodads\6hu_lumbermill_workbench02_nocollision.m2),
 * focus 1653 and a 50 yard reach. The shop one is scale 1.0 and the Tinker's is
 * scale 0.5, which is exactly what their names say.
 *
 * That is all this module is: the two templates. The item, the Tinker's summon
 * and the spells are the realm's and are left alone.
 *
 * It carries a report anyway, because the whole chain can be wrong in silence.
 * Before these rows existed the shop item cast a summon for a gameobject the
 * server had never heard of: no error, no message, nothing - the item was simply
 * a no-op that cost money. Nothing in a worldserver log said so. So this module
 * states at startup whether each half of the chain still resolves: the spell
 * still points at the template, the template is still a sawmill focus, and the
 * display is still the workbench the client caches name.
 *
 * Where a sawmill *counts* is not this module's business. The five Refine
 * spells are answered by mod-woodworking, which accepts a sawmill a player has
 * placed through the same gameobject search this template feeds.
 */

#include "GameObject.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"

namespace
{
constexpr uint32 SPELL_FOCUS_SAWMILL = 1653;
constexpr uint32 SAWMILL_DISPLAY = 1015620;
constexpr uint32 PORTABLE_SAWMILL = 2201004;
constexpr uint32 COMPACT_SAWMILL = 2201005;
constexpr uint32 ITEM_PORTABLE_SAWMILL = 1777064;

struct SawmillSource
{
    uint32 summonSpell;
    char const* summonSpellName;
    uint32 gameObjectEntry;
    uint32 expectedMiscValue;
};

SawmillSource const SawmillSources[] =
{
    { 9931368, "Summon Portable Sawmill", PORTABLE_SAWMILL, PORTABLE_SAWMILL },
    { 804707, "Build: Portable Sawmill", COMPACT_SAWMILL, COMPACT_SAWMILL },
    { 9931369, "Summon Compact Portable Sawmill", COMPACT_SAWMILL, COMPACT_SAWMILL },
};
}

class portable_sawmill_readiness : public WorldScript
{
public:
    portable_sawmill_readiness()
        : WorldScript("portable_sawmill_readiness", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        for (SawmillSource const& source : SawmillSources)
            ReportSource(source);

        ReportItem();
    }

private:
    static void ReportSource(SawmillSource const& source)
    {
        GameObjectTemplate const* gameObject = sObjectMgr->GetGameObjectTemplate(source.gameObjectEntry);
        if (!gameObject)
        {
            LOG_ERROR("module.portablesawmill", "{} (spell {}) summons gameobject {} but `gameobject_template` "
                      "has no such row; the summon places nothing at all and the player pays for it.",
                      source.summonSpellName, source.summonSpell, source.gameObjectEntry);
        }
        else
        {
            if (gameObject->type != GAMEOBJECT_TYPE_SPELL_FOCUS)
                LOG_ERROR("module.portablesawmill", "gameobject {} is type {} where a sawmill needs "
                          "GAMEOBJECT_TYPE_SPELL_FOCUS (8); no spell can be refined at it.",
                          source.gameObjectEntry, uint32(gameObject->type));
            else if (gameObject->spellFocus.focusId != SPELL_FOCUS_SAWMILL)
                LOG_ERROR("module.portablesawmill", "gameobject {} focuses {} where woodworking asks for {} "
                          "(Sawmill); the placement would not answer the recipes.",
                          source.gameObjectEntry, gameObject->spellFocus.focusId, SPELL_FOCUS_SAWMILL);

            if (gameObject->displayId == 0)
                LOG_ERROR("module.portablesawmill", "gameobject {} has display 0; the sawmill would answer the "
                          "recipes while drawing nothing.", source.gameObjectEntry);

            LOG_INFO("module.portablesawmill", "{} (spell {}) places gameobject {}: display {}, focus {}, reach {} "
                     "yards, scale {}.", source.summonSpellName, source.summonSpell, source.gameObjectEntry,
                     gameObject->displayId, gameObject->spellFocus.focusId, gameObject->spellFocus.dist,
                     gameObject->size);
        }

        SpellInfo const* spell = sSpellMgr->GetSpellInfo(source.summonSpell);
        if (!spell)
        {
            LOG_ERROR("module.portablesawmill", "spell {} ({}) is missing from the spell data; the summon cannot "
                      "be cast.", source.summonSpell, source.summonSpellName);
            return;
        }

        if (!spell->HasEffect(SPELL_EFFECT_TRANS_DOOR))
            LOG_ERROR("module.portablesawmill", "spell {} ({}) has no SPELL_EFFECT_TRANS_DOOR effect, so it does "
                      "not place a gameobject.", source.summonSpell, source.summonSpellName);
        else if (spell->Effects[EFFECT_0].MiscValue != int32(source.expectedMiscValue))
            LOG_ERROR("module.portablesawmill", "spell {} ({}) points at gameobject {} where this module expects {}.",
                      source.summonSpell, source.summonSpellName, spell->Effects[EFFECT_0].MiscValue,
                      source.expectedMiscValue);
    }

    static void ReportItem()
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(ITEM_PORTABLE_SAWMILL);
        if (!item)
        {
            LOG_ERROR("module.portablesawmill", "item {} (Portable Sawmill) is missing from `item_template`; the "
                      "portable sawmill cannot be bought.", ITEM_PORTABLE_SAWMILL);
            return;
        }

        if (item->Spells[0].SpellId != int32(9931368))
            LOG_ERROR("module.portablesawmill", "item {} (Portable Sawmill) uses spell {} where this module expects "
                      "9931368 (Summon Portable Sawmill).", ITEM_PORTABLE_SAWMILL, item->Spells[0].SpellId);
        else
            LOG_INFO("module.portablesawmill", "item {} (Portable Sawmill) ready: summons gameobject {}.",
                     ITEM_PORTABLE_SAWMILL, PORTABLE_SAWMILL);
    }
};

void AddPortableSawmillScripts()
{
    new portable_sawmill_readiness();
}
