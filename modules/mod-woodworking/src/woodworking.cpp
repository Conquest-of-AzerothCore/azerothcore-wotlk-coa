/* mod-woodworking - Woodcutting (skill 732) and Woodworking (skill 757).
 *
 * Three things in this profession cannot be expressed as data:
 *
 *   * the Lumber Axe (item 6954) handed to a character the moment they take
 *     either profession,
 *   * where a sawmill *is*, and
 *   * how a recipe is obtained at all, because neither trade has a trainer to
 *     obtain it from.
 *
 * The five Refine spells carry SpellFocusObject 1653 ("Sawmill" in
 * SpellFocusObject.dbc), and this core answers that field by searching the
 * caster's grid for a gameobject of that focus. The realm never had one at its
 * sawmill places: the client's own map addon publishes twenty spots
 * (Interface/FrameXML/Ascension_POI/StaticPOIs/GameObjectPOIs.lua, the
 * "Sawmill-*" pins, each with an exact position) and refining worked there with
 * nothing drawn. Two of those pins stand 2 and 11 yards from a lumber NPC - the
 * Westfall Woodworker and a Venture Co. Lumberjack - which is what the pins
 * mark: the realm's lumber camps.
 *
 * The core now asks scripts before it searches (Spell::CheckSpellFocus ->
 * ScriptMgr::OnSpellFocusAnswered), so this module answers the requirement for
 * the spells that carry focus 1653 - exactly the five Refine spells - and
 * leaves the field itself alone. That matters beyond bookkeeping: the server
 * sends that field with a refused cast, and it is what turns "Requires %s" into
 * "Requires Sawmill" on the player's screen.
 *
 * The answer is a place: within SAWMILL_SPOT_RANGE of any of the twenty
 * coordinates. Anywhere else the core's own search still runs, so a sawmill a
 * player has actually placed - the shop item's Portable Sawmill or the Tinker's
 * build, both owned by mod-portable-sawmill - answers the cast wherever it
 * stands. The marked places are the profession's home, not its only location.
 */

#include "GameObject.h"
#include "DBCStores.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "StringFormat.h"
#include "WorldPacket.h"

#include <algorithm>
#include <string>
#include <tuple>
#include <vector>

namespace
{
enum Woodworking : uint32
{
    // Each trade's entry pair: the Apprentice row the book sells, and the spell
    // that row teaches. Which of the two a character ends up holding depends on
    // whether the trainer casts the row or learns it, so both are watched. As
    // the client stands, the rows carry a learn spell and are cast:
    // 13977880 "Apprentice Woodcutter" -> 13977859 "Woodcutting", and
    // 1005014 "Apprentice Woodworker" -> 1005008.
    SPELL_APPRENTICE_WOODCUTTER_ROW = 13977880,
    SPELL_WOODCUTTING_GATHER = 13977859,
    SPELL_APPRENTICE_WOODWORKER_ROW = 1005014,
    SPELL_APPRENTICE_WOODWORKING = 1005008,
    ITEM_LUMBER_AXE = 6954,
    SPELL_FOCUS_SAWMILL = 1653
};

// How far from a marked spot the sawmill actions reach. The pins mark places a
// player works at - a lumber camp, a mill yard, a town corner - not a pinpoint,
// so this is a yardage rather than a radius around an object.
constexpr float SAWMILL_SPOT_RANGE = 40.0f;

struct SawmillSpot
{
    uint32 map;
    float x;
    float y;
    float z;
    char const* name;
};

// The twenty spots, in the client's own order, with the height taken from the
// server's extracted terrain (the pins carry no z) and Orgrimmar's from its
// neighbours because that pin stands on a WMO floor above the raw canyon.
// Elwynn Forest's is the Eastvale Logging Camp itself, where Terry Palin and
// the Eastvale Lumberjack stand and Terry Palin sells the lumber; the client
// pin for that zone sits 145 yards short of it, in empty ground southeast of
// the camp.
SawmillSpot const SawmillSpots[] =
{
    { 0,  -9404.85f,  -1343.52f,    50.11f, "Elwynn Forest" },
    { 0,  -8298.11f,   1119.30f,    19.05f, "Stormwind" },
    { 0,  -5765.70f,  -1276.35f,   379.62f, "Dun Morogh" },
    { 0, -11989.70f,   -549.96f,    11.41f, "Stranglethorn Vale, north" },
    { 0, -11638.40f,   -633.76f,    31.28f, "Stranglethorn Vale, south" },
    { 0,   2887.01f,  -1564.34f,   145.57f, "Western Plaguelands" },
    { 0, -10644.60f,   1114.70f,    32.81f, "Westfall" },
    { 0,  -9212.01f,  -2713.99f,    88.80f, "Redridge Mountains" },
    { 0,   2188.10f,    266.04f,    40.19f, "Tirisfal Glades" },
    { 0,   -143.55f,   -855.77f,    57.99f, "Tarren Mill" },
    { 1,   1674.09f,  -4069.13f,    37.58f, "Orgrimmar" },
    { 1,    745.16f,  -4278.22f,    17.92f, "Durotar" },
    { 1,  -2216.88f,   -311.12f,    -9.18f, "Mulgore" },
    { 1,   9859.40f,    987.62f,  1309.45f, "Teldrassil" },
    { 1,  -3676.79f,  -4373.96f,    11.27f, "Theramore Isle" },
    { 1,   1238.15f,      6.12f,    -5.97f, "Stonetalon Mountains" },
    { 530,   9572.59f,  -6834.43f,    17.32f, "Eversong Woods" },
    { 530,  -4193.31f, -12441.40f,    44.81f, "Azuremyst Isle" },
    { 571,   4180.87f,  -2977.64f,   283.17f, "Grizzly Hills, mill" },
    { 571,   4287.41f,  -3167.68f,   308.51f, "Grizzly Hills, south" },
};

bool InsideSawmillSpot(Player const* player)
{
    for (SawmillSpot const& spot : SawmillSpots)
    {
        if (player->GetMapId() != spot.map)
            continue;

        float const dx = player->GetPositionX() - spot.x;
        float const dy = player->GetPositionY() - spot.y;
        float const dz = player->GetPositionZ() - spot.z;
        if (dx * dx + dy * dy + dz * dz <= SAWMILL_SPOT_RANGE * SAWMILL_SPOT_RANGE)
            return true;
    }

    return false;
}

// ---------------------------------------------------------------------------
// The pins
// ---------------------------------------------------------------------------
// The twenty coordinates above are the client's own map pins - and the client's
// are not the truth. Its Elwynn Forest pin stands 145 yards short of the
// Eastvale Logging Camp, in empty ground, while the spot above is the camp.
//
// That is fixable from here, because the pins are not client data after all:
// the client's pin database is rebuilt from what the server sends. `DB_MapPOI`
// (Interface/FrameXML/Data/MapPOI.lua) is the store behind the world map, and
// the server feeds it over the JSON channel Extensions.dll opens on
// `SMSG_COA_AREA_POI_PAYLOAD` (0x77C, category `AREA_POI_PAYLOAD`). The handler
// that consumes one calls `CreatePOI`, which removes the pin already holding
// the incoming ID before it inserts - so a POI sent under one of the client's
// own keys, `Sawmill-Elwynn-Forest`, *replaces* that static pin, position and
// all. The client also keeps the payloads in a cache it replays on every
// `PLAYER_ENTERING_WORLD`, so one send per login covers the session.
//
// The name and description have to travel in the payload - it carries literals,
// not the client's globals - so they are the two strings the client itself
// would have used, `GlobalStrings.dbc` rows 15977 and 15978
// (`MINIMAP_TRACKING_SAWMILL` and `_DESC`).
//
// Only Elwynn Forest's pin is corrected. The pins the client ships for the
// other nineteen stand on their lumber camps (two of them within yards of a
// lumber NPC), and a pin that is already in the right place is not worth
// moving.

struct SawmillPin
{
    uint32 zone;      // the zone the pin belongs to
    char const* id;   // the client's own pin key, from GameObjectPOIs.lua
    float x;
    float y;
    float z;
};

SawmillPin const SawmillPins[] =
{
    // Eastvale Logging Camp, the module's own Elwynn Forest spot above, where
    // the client's pin for the zone sits 145 yards away at -9545.33, -1401.10.
    { 12, "Sawmill-Elwynn-Forest", -9404.85f, -1343.52f, 50.11f },
};

char const* const SAWMILL_PIN_NAME = "Sawmill";
char const* const SAWMILL_PIN_DESCRIPTION = "Used to mill logs into planks to be used with Woodworking.";
char const* const SAWMILL_PIN_TEXTURE = "lumber_tracking";   // the atlas the client's own pin uses

// HideOnContinent | HasTooltip: the client's static pin carries both, so the pin
// stays off the continent map and keeps its tooltip.
constexpr uint32 SAWMILL_PIN_FLAGS = 0x4 | 0x10;
constexpr float SAWMILL_PIN_SCALE = 0.6f;

// The cache key, not the pin's name - the name is the JSON's own ID field. The
// client asks `HasJsonCacheData(event, id)` before each replay, so the key has
// to be ours and stable: Woodcutting's skill id and an index, out of the way of
// anything else the realm might put in this category.
constexpr uint32 SAWMILL_PIN_CACHE_ID = 732000;

// One POI, in the shape `DB_MapPOI:AREA_POI_PAYLOAD` reads. Written out by hand
// because it is four numbers and four strings of this module's own, none of
// which can hold a character that JSON needs escaped.
std::string SawmillPinPayload(SawmillPin const& pin)
{
    return Acore::StringFormat(
        "{{\"Apply\":true,\"ZoneId\":{},\"ID\":\"{}\",\"Name\":\"{}\",\"Description\":\"{}\","
        "\"X\":{:.4f},\"Y\":{:.4f},\"Z\":{:.4f},\"TextureId\":\"{}\",\"Scale\":{:.2f},"
        "\"POIFlags\":{}}}",
        pin.zone, pin.id, SAWMILL_PIN_NAME, SAWMILL_PIN_DESCRIPTION,
        pin.x, pin.y, pin.z, SAWMILL_PIN_TEXTURE, SAWMILL_PIN_SCALE, SAWMILL_PIN_FLAGS);
}

// ---------------------------------------------------------------------------
// The recipes
// ---------------------------------------------------------------------------
// Neither trade has a trainer. Woodcutting and Woodworking are CoA's own, no
// creature in the realm carries a row for either, and the Book of Artisans is
// the only thing that teaches them at all - so a recipe that exists only as a
// row that book sells is a recipe these two trades cannot really have.
//
// `Refine Forestwood Plank` is the exception the client makes itself: its
// `SkillLineAbility` row says learned on skill value, so it arrives with the
// trade. Every other recipe of both trades is marked trainer-taught, and there
// is no trainer to teach it - which is what a gathering character notices as
// "there is only the first kind of wood".
//
// This script is that trainer, without the shopping: a recipe is learned as the
// skill reaches it. The list is not written out here either - it is read from
// the client's `SkillLineAbility` at startup, so the client stays the only place
// a recipe is declared, and a client whose spells change moves this list and
// nothing else.
//
// The gate is the one the client declares for the recipe: its
// `MinSkillLineRank` where that is above 1, which is how the four Refine spells
// above Forestwood are gated (65, 125, 165 and 230), and its
// `TrivialSkillLineRankLow` otherwise, which is where the wood tiers sit -
// Forestwood from 10, Wildwood from 60, Everwood from 115, Grovewood from 165,
// Heartwood from 220.
//
// Only the trades' own recipes are taken. A row whose effect is one of the
// profession rows (44 SPELL_EFFECT_SKILL_STEP, 47 SPELL_EFFECT_TRADE_SKILL,
// 118 SPELL_EFFECT_SKILL) is the rank that learns the trade or raises its
// ceiling, not something the trade makes, and those stay where they are: on the
// book, bought by the character who wants the next step of the ladder.
constexpr uint32 ACQUIRE_METHOD_TRAINER = 0;

struct WoodworkingRecipe
{
    uint32 skill;
    uint32 gate;
    uint32 spell;
};

bool IsProfessionRow(SpellInfo const* spellInfo)
{
    return spellInfo->HasEffect(SPELL_EFFECT_SKILL_STEP)
        || spellInfo->HasEffect(SPELL_EFFECT_TRADE_SKILL)
        || spellInfo->HasEffect(SPELL_EFFECT_SKILL);
}

std::vector<WoodworkingRecipe> const& WoodworkingRecipes()
{
    static std::vector<WoodworkingRecipe> const recipes = []()
    {
        std::vector<WoodworkingRecipe> rows;

        for (uint32 skill : { SKILL_WOODCUTTING, SKILL_WOODWORKING })
            for (SkillLineAbilityEntry const* ability : GetSkillLineAbilitiesBySkillLine(skill))
            {
                if (!ability || ability->AcquireMethod != ACQUIRE_METHOD_TRAINER)
                    continue;

                SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(ability->Spell);
                if (!spellInfo || IsProfessionRow(spellInfo))
                    continue;

                uint32 const gate = ability->MinSkillLineRank > 1
                    ? ability->MinSkillLineRank
                    : ability->TrivialSkillLineRankLow;
                if (!gate)
                    continue;

                rows.push_back({ skill, gate, ability->Spell });
            }

        std::sort(rows.begin(), rows.end(), [](WoodworkingRecipe const& left, WoodworkingRecipe const& right)
        {
            return std::tie(left.skill, left.gate, left.spell) < std::tie(right.skill, right.gate, right.spell);
        });

        return rows;
    }();

    return recipes;
}

struct RecipeLadder
{
    std::size_t count = 0;
    uint32 lowest = 0;
    uint32 highest = 0;
};

// The list is sorted by skill and then by gate, so the first entry of a skill is
// the lowest gate and the last is the highest.
RecipeLadder SummariseLadder(uint32 skill)
{
    RecipeLadder ladder;

    for (WoodworkingRecipe const& recipe : WoodworkingRecipes())
    {
        if (recipe.skill != skill)
            continue;

        if (!ladder.count)
            ladder.lowest = recipe.gate;

        ++ladder.count;
        ladder.highest = recipe.gate;
    }

    return ladder;
}

void LearnRecipesUpTo(Player* player, uint32 skill, uint32 value)
{
    if (!value || !player->HasSkill(skill))
        return;

    for (WoodworkingRecipe const& recipe : WoodworkingRecipes())
    {
        if (recipe.skill != skill || recipe.gate > value)
            continue;

        if (player->HasSpell(recipe.spell))
            continue;

        player->learnSpell(recipe.spell, false);
    }
}
}

class woodworking_sawmill_places : public SpellSC
{
public:
    woodworking_sawmill_places() : SpellSC("woodworking_sawmill_places",
        { ALLSPELLHOOK_ON_SPELL_FOCUS_ANSWERED }) { }

    bool OnSpellFocusAnswered(Spell* spell) override
    {
        SpellInfo const* spellInfo = spell ? spell->GetSpellInfo() : nullptr;
        if (!spellInfo || spellInfo->RequiresSpellFocus != SPELL_FOCUS_SAWMILL)
            return false;

        Player* caster = spell->GetCaster() ? spell->GetCaster()->ToPlayer() : nullptr;
        return caster && InsideSawmillSpot(caster);
    }
};

// The axe is handed over when either trade is taken - the moment the trade's
// own apprentice row is bought from the book. Which event that is, is decided by
// the row itself, and there are two of them: `Trainer::TeachSpell` casts a
// trainer spell that carries a learn spell (effect 36) and learns one that does
// not, and the apprentice rows cast. So the pair of events is listened for, not
// one of them:
//
//   * the skill moves, because the cast carries a skill step (effect 44) and
//     `Spell::EffectLearnSkill` grants the trade through `SetSkill`; this is the
//     event that always happens, and it is also what pays the axe back to a
//     character who buys a later rank without ever having had one; and
//   * the career's own entry spell is learned, which is what the same cast
//     teaches and what a character learns directly if a client ever ships these
//     rows the other way round.
//
// Watching only for the apprentice row being *learned* was the first attempt and
// it never fired, because no character ever learns that row: it is cast.
class WoodworkingLumberAxePlayerScript : public PlayerScript
{
public:
    WoodworkingLumberAxePlayerScript() : PlayerScript("WoodworkingLumberAxePlayerScript",
        { PLAYERHOOK_ON_SET_SKILL, PLAYERHOOK_ON_LEARN_SPELL }) { }

    void OnPlayerSetSkill(Player* player, uint32 skillId, uint32 /*value*/, uint32 /*max*/,
        uint32 /*step*/, uint32 newValue) override
    {
        if (newValue && (skillId == SKILL_WOODCUTTING || skillId == SKILL_WOODWORKING))
            GiveLumberAxe(player);
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellID) override
    {
        for (uint32 entry : { SPELL_APPRENTICE_WOODCUTTER_ROW, SPELL_WOODCUTTING_GATHER,
                              SPELL_APPRENTICE_WOODWORKER_ROW, SPELL_APPRENTICE_WOODWORKING })
        {
            if (spellID != entry)
                continue;

            GiveLumberAxe(player);
            return;
        }
    }

private:
    static void GiveLumberAxe(Player* player)
    {
        if (!player->IsInWorld() || player->HasItemCount(ITEM_LUMBER_AXE, 1, true))
            return;

        player->AddItem(ITEM_LUMBER_AXE, 1);
    }
};

// A ladder that came back empty is the failure this module can least afford:
// nothing would break, no cast would fail, and a gathering character would
// simply keep finding only the first kind of wood. The client's own tables are
// the source, so this says out loud what they produced.
class woodworking_recipe_readiness : public WorldScript
{
public:
    woodworking_recipe_readiness() : WorldScript("woodworking_recipe_readiness",
        { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        for (uint32 skill : { SKILL_WOODCUTTING, SKILL_WOODWORKING })
        {
            RecipeLadder const ladder = SummariseLadder(skill);

            if (!ladder.count)
            {
                LOG_ERROR("module.woodworking", "skill {} has no recipe to learn: the client's SkillLineAbility "
                    "offers none, so the trade keeps only the rows a trainer sells.", skill);
                continue;
            }

            LOG_INFO("module.woodworking", "skill {} ready: {} recipes come with the skill, from gate {} to {}.",
                skill, ladder.count, ladder.lowest, ladder.highest);
        }
    }
};

// The trade is taken from the book, a tree or the sawmill pays points, and a
// character who already had the trade before this script existed catches up on
// the next login instead of having to reach the next gate to see the rest.
class WoodworkingRecipePlayerScript : public PlayerScript
{
public:
    WoodworkingRecipePlayerScript() : PlayerScript("WoodworkingRecipePlayerScript",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_SET_SKILL, PLAYERHOOK_ON_UPDATE_SKILL }) { }

    void OnPlayerLogin(Player* player) override
    {
        for (uint32 skill : { SKILL_WOODCUTTING, SKILL_WOODWORKING })
            if (player->HasSkill(skill))
                LearnRecipesUpTo(player, skill, player->GetBaseSkillValue(skill));
    }

    void OnPlayerSetSkill(Player* player, uint32 skillId, uint32 /*value*/, uint32 /*max*/,
        uint32 /*step*/, uint32 newValue) override
    {
        LearnRecipesUpTo(player, skillId, newValue);
    }

    void OnPlayerUpdateSkill(Player* player, uint32 skillId, uint32 /*value*/, uint32 /*max*/,
        uint32 /*step*/, uint32 newValue) override
    {
        LearnRecipesUpTo(player, skillId, newValue);
    }
};

// The client's pins are corrected for the client, once per login - which is when
// the client has emptied its cache of these payloads (the character list clears
// them), so the session that follows starts from the corrected pin.
class WoodworkingSawmillPinPlayerScript : public PlayerScript
{
public:
    WoodworkingSawmillPinPlayerScript() : PlayerScript("WoodworkingSawmillPinPlayerScript",
        { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player)
            return;

        uint32 cache = SAWMILL_PIN_CACHE_ID;
        for (SawmillPin const& pin : SawmillPins)
        {
            std::string const payload = SawmillPinPayload(pin);

            WorldPacket packet(SMSG_COA_AREA_POI_PAYLOAD, 4 + payload.size() + 1);
            packet << uint32(cache++);
            packet << payload;   // the reader wants the string's terminator, and this appends it
            player->SendDirectMessage(&packet);

            LOG_DEBUG("module.woodworking", "sent sawmill pin {} to {} at {},{}.", pin.id,
                player->GetName(), pin.x, pin.y);
        }
    }
};

void AddWoodworkingScripts()
{
    new woodworking_sawmill_places();
    new WoodworkingLumberAxePlayerScript();
    new WoodworkingRecipePlayerScript();
    new WoodworkingSawmillPinPlayerScript();
    new woodworking_recipe_readiness();
}
