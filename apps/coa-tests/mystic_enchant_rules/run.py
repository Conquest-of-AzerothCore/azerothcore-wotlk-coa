CLI_DESCRIPTION = """Check the mystic enchant rules the server shares with the client, without a server.

Compiles the mystic enchant rule code against the client DBC set the server loads (--dbc-dir), then checks the
catalog, the realm, class and quality columns, slot validity, the per-quality caps, and the result each apply,
destroy, scroll purchase, inspect, preset, reforge, collection reforge, save-to-collection and extract
purchase request receives, with its price and the altar progress it earns, how a followed Hero Architect
build's enchants fill the slots, and which missing enchants a bot's build teaches first.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from coa_talent_catalog import STUBS  # noqa: E402
from client_data import dbc_dir  # noqa: E402

MAIN = r"""
#include "AscensionMysticEnchantRules.h"
#include "DBCStores.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <string>

using namespace AscensionMysticEnchant;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::uint32_t WARRIOR = 1;
constexpr std::uint32_t COA_CLASS = 12;
constexpr std::uint32_t RUNIC_CONTAGION = 288975;
constexpr std::uint32_t RUNIC_CONTAGION_SCROLL = 404438;
constexpr std::uint32_t CREMATION_SCROLL = 404764;
constexpr std::uint32_t HOLY_POWER_SCROLL = 1175658;
constexpr std::uint32_t RARE_SCROLLS[] = { 404438, 404440, 404441, 404442, 405207, 405213 };

Character Hero(ClientConfig const& config, std::uint32_t level)
{
    Character character;
    character.Class = HERO_CLASS;
    character.Level = level;
    character.Money = 100000;
    character.AltarNearby = true;
    character.UnlockTokens = 1;
    character.RealmGates = { false, true, false, false, false };
    character.Config = &config;
    character.StackLimit = [](std::uint32_t) { return 1u; };
    return character;
}

StagedApply Stage(std::uint32_t slot, std::uint32_t item, std::uint32_t key)
{
    return { slot, item, key, true };
}

std::vector<StagedApply> RareScrolls(std::size_t count)
{
    std::vector<StagedApply> staged;
    for (std::size_t index = 0; index < count; ++index)
        staged.push_back(Stage(std::uint32_t(index + 1), RARE_SCROLLS[index], std::uint32_t(index + 1)));
    return staged;
}
}

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    Catalog catalog;
    Check(LoadCatalog(catalog), "MysticEnchant.dbc loads");
    std::size_t seasonal = 0;
    for (Enchant const& enchant : catalog.Rows)
        seasonal += enchant.Realms[1];
    Check(catalog.Rows.size() > 7000 && seasonal == 1560, "the catalog holds the 1,560 seasonal enchants");

    Enchant const* contagion = catalog.FindSpell(RUNIC_CONTAGION);
    Check(contagion && catalog.FindItem(RUNIC_CONTAGION_SCROLL) == contagion, "an enchant is found by spell and item");
    if (!contagion)
        return 1;
    Check(!catalog.FindItem(UNTARNISHED_MYSTIC_SCROLL), "the untarnished scroll carries no enchant");
    Check(QualityOf(*contagion, HERO_CLASS) == QUALITY_RARE && QualityOf(*contagion, WARRIOR) == QUALITY_POOR,
        "a stock class reads the reborn quality column");
    Check(ClassAllowed(*contagion, HERO_CLASS) && !ClassAllowed(*contagion, WARRIOR) && !ClassAllowed(*contagion, 0),
        "the class mask admits the Hero only");
    Enchant const* holyPower = catalog.FindItem(HOLY_POWER_SCROLL);
    Check(holyPower && !RealmAllows(*holyPower, { false, true, false, false, false }) &&
        RealmAllows(*holyPower, { true, false, false, false, false }),
        "a live-only enchant is refused on a seasonal realm");

    Check(!SlotValid(0, true) && SlotValid(1, true) && SlotValid(15, true) && !SlotValid(16, true),
        "class fusion uses slots 2 to 16 only");
    Check(SlotValid(0, false) && SlotValid(16, false) && !SlotValid(17, false), "otherwise all 17 slots exist");

    ClientConfig plain;
    Character hero = Hero(plain, 80);
    Character warrior = hero;
    warrior.Class = WARRIOR;
    Check(QualityCap(hero, QUALITY_UNCOMMON) == 17 && QualityCap(hero, QUALITY_RARE) == 17 &&
        QualityCap(hero, QUALITY_EPIC) == 3 && QualityCap(hero, QUALITY_LEGENDARY) == 1 &&
        QualityCap(warrior, QUALITY_EPIC) == 5 && QualityCap(hero, QUALITY_POOR) == 0,
        "without configs the caps are the client's defaults");

    ClientConfig fusion;
    fusion.Booleans["CONFIG_CLASS_FUSION_ENABLED"] = true;
    for (int index = 1; index <= 5; ++index)
        fusion.Integers["CONFIG_RARE_RANDOM_ENCHANT_UNLOCK_LEVEL_" + std::to_string(index)] = index * 10;
    Check(Hero(fusion, 80).Fusion() && Hero(fusion, 35).Fusion(), "a Hero on a class fusion realm uses fusion");
    Check(QualityCap(Hero(fusion, 35), QUALITY_RARE) == 3 && QualityCap(Hero(fusion, 80), QUALITY_RARE) == 5 &&
        QualityCap(Hero(fusion, 80), QUALITY_EPIC) == 4, "fusion unlocks slots by level, up to 6/5/4");
    Character wildcard = Hero(fusion, 80);
    wildcard.GameModes = WILDCARD_MODE;
    Check(!wildcard.Fusion(), "the wildcard game mode is not fusion");

    Slots empty{};
    Character fused = Hero(fusion, 80);
    Check(CheckSaveApply(catalog, fused, empty, RareScrolls(5)) == APPLY_OK, "five rare scrolls fit a fusion Hero");
    Check(CheckSaveApply(catalog, fused, empty, RareScrolls(6)) == APPLY_RARE_LIMIT,
        "a sixth rare scroll is RARE_LIMIT");
    Check(CheckSaveApply(catalog, fused, empty, {}) == APPLY_UNKNOWN, "an empty apply is UNKNOWN");
    std::vector<StagedApply> const twice = { Stage(1, RUNIC_CONTAGION_SCROLL, 7),
        Stage(2, RUNIC_CONTAGION_SCROLL, 7) };
    Check(CheckSaveApply(catalog, fused, empty, twice) == APPLY_STACK_LIMIT &&
        CheckApplySlot(catalog, fused, empty, twice, twice[0]).back() == APPLY_DUPLICATE_BAG_SLOT_PAIR,
        "one scroll staged into two slots also reports DUPLICATE_BAG_SLOT_PAIR");
    Check(CheckSaveApply(catalog, fused, empty, { Stage(1, RUNIC_CONTAGION_SCROLL, 7),
        Stage(2, RUNIC_CONTAGION_SCROLL, 8) }) == APPLY_STACK_LIMIT, "an enchant twice past its stacks is STACK_LIMIT");
    Check(CheckSaveApply(catalog, fused, empty, { Stage(1, RARE_SCROLLS[0], 1), Stage(1, RARE_SCROLLS[1], 2) }) ==
        APPLY_DUPLICATE_SLOT, "fusion refuses one slot staged twice");
    Slots holding{};
    holding[1] = RUNIC_CONTAGION;
    Check(CheckSaveApply(catalog, fused, holding, { Stage(2, RUNIC_CONTAGION_SCROLL, 7) }) == APPLY_STACK_LIMIT,
        "an enchant already slotted counts toward its stacks");
    Check(CheckSaveApply(catalog, fused, empty, { Stage(0, RUNIC_CONTAGION_SCROLL, 7) }) == APPLY_BAD_SLOT,
        "fusion refuses slot 1");
    Check(CheckSaveApply(catalog, Hero(fusion, 30), empty, { Stage(1, CREMATION_SCROLL, 7) }) ==
        APPLY_TOO_LOW_LEVEL, "a level 35 enchant is refused at level 30");
    Check(CheckSaveApply(catalog, wildcard, empty, { Stage(1, RUNIC_CONTAGION_SCROLL, 7) }) ==
        APPLY_DISABLED_IN_WILDCARD, "the wildcard game mode refuses mystic enchanting");
    Check(CheckSaveApply(catalog, fused, empty, { Stage(1, UNTARNISHED_MYSTIC_SCROLL, 7) }) ==
        APPLY_NOT_MYSTIC_SCROLL, "an untarnished scroll cannot be applied");
    Check(CheckSaveApply(catalog, fused, empty, { { 1, 0, 7, false } }) == APPLY_BAD_ITEM,
        "a scroll the character does not hold is BAD_ITEM");
    Check(CheckSaveApply(catalog, fused, empty, { Stage(1, HOLY_POWER_SCROLL, 7) }) == APPLY_BAD_REALM,
        "a live-only enchant is BAD_REALM on a seasonal realm");
    Character coa = hero;
    coa.Class = COA_CLASS;
    Check(CheckSaveApply(catalog, coa, empty, { Stage(1, RUNIC_CONTAGION_SCROLL, 7) }) == APPLY_BAD_CLASS,
        "a class outside the mask is BAD_CLASS");
    Character casting = fused;
    casting.Casting = true;
    Check(CheckSaveApply(catalog, casting, empty, { Stage(1, RUNIC_CONTAGION_SCROLL, 7) }) ==
        APPLY_NOT_WHILE_CASTING, "nothing is applied mid-cast");

    Enchant gated;
    gated.ClassTypes = { 1, 3, 1 };
    gated.Tabs = { 1, 6, 1 };
    gated.RequiredAE = { 0, 9, 0 };
    Character investor = hero;
    Check(InvestmentMet(investor, *contagion, false), "an enchant with no requirement needs no investment");
    Check(!InvestmentMet(investor, gated, false), "an AE requirement refuses an empty build");
    investor.Invested = [](std::uint32_t classType, std::uint32_t tab, bool talent)
    {
        return classType == 3 && tab == 6 && !talent ? 9u : 0u;
    };
    Check(InvestmentMet(investor, gated, false) && InvestmentMet(investor, gated, true),
        "nine AE in the named tab meets it, and no TE is asked for");

    Check(CheckDestroy(fused, empty, 1) == DESTROY_NO_ENCHANT_APPLIED, "an empty slot has nothing to destroy");
    Check(CheckDestroy(fused, holding, 0) == DESTROY_BAD_SLOT, "fusion slot 1 does not exist to destroy");
    Check(CheckDestroy(casting, holding, 1) == DESTROY_NOT_WHILE_CASTING && CheckDestroy(fused, holding, 1) ==
        DESTROY_OK, "a held enchant is destroyed when not casting");
    Character coaHolder = fused;
    coaHolder.Class = COA_CLASS;
    Check(CheckDestroy(coaHolder, holding, 1) == DESTROY_BAD_CLASS, "a Conquest of Azeroth class may not destroy");

    Character shopper = hero;
    Check(CheckPurchaseScroll(shopper, true, 1000) == PURCHASE_OK, "a scroll is bought at an altar");
    Check(CheckPurchaseScroll(shopper, false, 1000) == PURCHASE_ITEM_NOT_FOUND, "a missing scroll item is reported");
    shopper.Money = 999;
    Check(CheckPurchaseScroll(shopper, true, 1000) == PURCHASE_NOT_ENOUGH_MONEY, "a short purse is NOT_ENOUGH_MONEY");
    shopper.Money = 1000;
    shopper.AltarNearby = false;
    Check(CheckPurchaseScroll(shopper, true, 1000) == PURCHASE_NO_MYSTIC_ALTAR, "scrolls are sold only at an altar");
    shopper.AltarNearby = true;
    shopper.BagSpace = false;
    Check(CheckPurchaseScroll(shopper, true, 1000) == PURCHASE_NOT_ENOUGH_SPACE, "full bags are NOT_ENOUGH_SPACE");

    Check(CheckInspect(false, false, HERO_CLASS) == INSPECT_PLAYER_NOT_FOUND &&
        CheckInspect(true, false, HERO_CLASS) == INSPECT_PLAYER_NOT_IN_MAP &&
        CheckInspect(true, true, COA_CLASS) == INSPECT_BAD_CLASS && CheckInspect(true, true, HERO_CLASS) == INSPECT_OK,
        "inspect needs a present non-CoA player on the same map");

    Check(CheckPresetUnlock(hero, 1) == PRESET_UNLOCK_OK && CheckPresetUnlock(hero, MAX_PRESETS) ==
        PRESET_UNLOCK_MAX_VALUE_REACHED, "presets unlock up to 100");
    Character tokenless = hero;
    tokenless.UnlockTokens = 0;
    Check(CheckPresetUnlock(tokenless, 1) == PRESET_UNLOCK_NO_MONEY, "an unlock needs its token");
    Check(CheckPresetActivate(hero, 1, 2) == PRESET_SET_ACTIVE_OK && CheckPresetActivate(hero, 2, 2) ==
        PRESET_SET_ACTIVE_UNKNOWN, "only an unlocked preset activates");
    Check(CheckPresetActivate(casting, 0, 1) == PRESET_SET_ACTIVE_NOT_WHILE_CASTING &&
        CheckPresetSave(coa) == PRESET_SAVE_BAD_CLASS, "casting and CoA classes are refused");

    ClientConfig extractOne;
    for (char const* tier : { "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "ARTIFACT" })
        extractOne.Integers[std::string("CONFIG_MYSTIC_ENCHANT_EXTRACT_") + tier + "_TOKEN_COST"] = 1;
    Character altar = Hero(extractOne, 60);
    std::vector<std::uint32_t> known;
    altar.Known = &known;

    Check(ReforgeCost(altar, false) == 250 && ReforgeCost(altar, true) == 25000,
        "a reforge costs 250 Runes of Ascension or 2.5 gold");
    altar.Money = 0;
    Check(!ReforgeCharge(altar).Affordable, "a reforge with neither runes nor 2.5 gold is refused");
    altar.Money = 25000;
    Check(ReforgeCharge(altar).Money == 25000 && !ReforgeCharge(altar).Runes, "without runes the reforge takes gold");
    altar.Runes = 250;
    Check(ReforgeCharge(altar).Runes == 250 && !ReforgeCharge(altar).Money, "runes are spent before gold");
    Check(CheckReforgeItem(catalog, altar, { true, UNTARNISHED_MYSTIC_SCROLL }) == REFORGE_OK &&
        CheckReforgeItem(catalog, altar, { true, RUNIC_CONTAGION_SCROLL }) == REFORGE_OK,
        "an untarnished or enchanted scroll is reforged at an altar");
    Check(CheckReforgeItem(catalog, altar, { true, 6948 }) == REFORGE_NOT_MYSTIC_SCROLL &&
        CheckReforgeItem(catalog, altar, { false, 0 }) == REFORGE_BAD_ITEM, "only a held mystic scroll is reforged");
    Character away = altar;
    away.AltarNearby = false;
    Check(CheckReforgeItem(catalog, away, { true, UNTARNISHED_MYSTIC_SCROLL }) == REFORGE_NO_MYSTIC_ALTAR,
        "reforging needs an altar");

    std::vector<Enchant const*> const pool = ReforgePool(catalog, altar, nullptr);
    bool poolClean = !pool.empty();
    for (Enchant const* enchant : pool)
        poolClean = poolClean && enchant->Realms[1] && !enchant->Worldforged && ClassAllowed(*enchant, HERO_CLASS);
    Check(poolClean && pool.size() > 1000, "the reforge pool is the realm's non-worldforged Hero enchants");
    Check(Roll(pool, 0.0) == pool.front() && Roll(pool, 1.0) == pool.back() && Roll({}, 0.5) == nullptr,
        "a roll walks the weights from the first enchant to the last");

    Check(LevelProgress(1) == 361 && LevelProgress(2) == 738, "an altar level needs 7.5 l^2 + 354 l progress");
    Progress progress;
    Check(AddProgress(progress, 359) == 0 && progress.Level == 1 && AddProgress(progress, 1) == 1 &&
        progress.Level == 2, "progress reaching 361 raises the altar to level 2");
    Check(ReforgeProgressGain(*contagion, 1.0) == 80, "a rare roll is worth 80 progress");

    Check(ExtractCost(altar, *contagion) == 1 && ExtractCost(hero, *contagion) == 5000,
        "saving costs the configured extract, the client's fallback 5000 otherwise");
    Check(CheckDisenchant(catalog, altar, RUNIC_CONTAGION) == DISENCHANT_NO_MONEY,
        "saving to the collection without an extract is refused");
    altar.Extracts = 1;
    Check(CheckDisenchantItem(catalog, altar, { true, RUNIC_CONTAGION_SCROLL }) == DISENCHANT_OK,
        "one extract saves a scroll's enchant to the collection");
    known.push_back(RUNIC_CONTAGION);
    Check(CheckDisenchant(catalog, altar, RUNIC_CONTAGION) == DISENCHANT_ALREADY_KNOWN_ENCHANTMENT,
        "a collected enchant is not saved again");
    Check(CheckDisenchantSlot(catalog, altar, holding, 1) == DISENCHANT_ALREADY_KNOWN_ENCHANTMENT &&
        CheckDisenchantSlot(catalog, altar, empty, 1) == DISENCHANT_BAD_ENCHANTMENT,
        "a slot saves the enchant it holds");

    Check(ExtractPurchaseCost(1) == 1200 && ExtractPurchaseCost(60) == 5000,
        "an extract costs 200 runes per altar level plus 1000, at most 5000");
    Check(CheckExtractPurchase(altar, 1) == EXTRACT_PURCHASE_ALREADY_OBTAINED,
        "no extract is sold while one is held");
    altar.Extracts = 0;
    altar.Runes = 1199;
    Check(CheckExtractPurchase(altar, 1) == EXTRACT_PURCHASE_NO_TOKENS, "an extract needs its runes");
    Check(ExtractsBoughtWithSave(altar, 1, true) == 0, "a save cannot buy an extract without its runes");
    altar.Runes = 1200;
    Check(CheckExtractPurchase(altar, 1) == EXTRACT_PURCHASE_OK, "1200 runes buy an extract at altar level 1");
    Character buyer = altar;
    known.clear();
    buyer.Extracts += ExtractsBoughtWithSave(buyer, 1, true);
    Check(ExtractsBoughtWithSave(altar, 1, false) == 0 && buyer.Extracts == 1 &&
        CheckDisenchantSlot(catalog, buyer, holding, 1) == DISENCHANT_OK,
        "a save that asks to buy its extract goes through with no extract held");
    known.push_back(RUNIC_CONTAGION);

    altar.Runes = 0;
    altar.Money = 0;
    Check(CheckCollectionReforgeItem(catalog, altar, { true, UNTARNISHED_MYSTIC_SCROLL }, RUNIC_CONTAGION) ==
        COLLECTION_REFORGE_NO_MONEY, "a collection reforge of a scroll is paid in gold");
    altar.Money = 600000;
    Check(CheckCollectionReforgeItem(catalog, altar, { true, UNTARNISHED_MYSTIC_SCROLL }, RUNIC_CONTAGION) ==
        COLLECTION_REFORGE_OK, "60 gold turns an untarnished scroll into a collected rare");
    Check(CheckCollectionReforgeItem(catalog, altar, { true, RUNIC_CONTAGION_SCROLL }, RUNIC_CONTAGION) ==
        COLLECTION_REFORGE_ALREADY_APPLIED, "a scroll is not reforged into itself");
    Check(CheckCollectionReforgeItem(catalog, altar, { true, UNTARNISHED_MYSTIC_SCROLL }, 276397) ==
        COLLECTION_REFORGE_NOT_KNOWN_ENCHANTMENT, "only a collected enchant is a reforge target");

    Character slotter = Hero(fusion, 80);
    slotter.Known = &known;
    slotter.AltarNearby = true;
    slotter.Runes = 2400;
    Check(CheckSaveCollectionReforge(catalog, slotter, empty, { { 1, RUNIC_CONTAGION } }) == COLLECTION_REFORGE_OK &&
        CollectionReforgeCharge(slotter, { contagion }, true).Runes == 2400,
        "a collected rare is set into a slot for 2400 runes");
    slotter.Runes = 0;
    Check(CheckSaveCollectionReforge(catalog, slotter, empty, { { 1, RUNIC_CONTAGION } }) ==
        COLLECTION_REFORGE_NO_MONEY, "without runes or 60 gold the slot is refused");
    slotter.Money = 600000;
    Check(CollectionReforgeCharge(slotter, { contagion }, true).Money == 600000, "gold pays when runes are short");
    Check(CheckSaveCollectionReforge(catalog, slotter, empty, { { 1, RUNIC_CONTAGION }, { 2, RUNIC_CONTAGION } }) ==
        COLLECTION_REFORGE_NO_MONEY, "two slots cost twice");
    slotter.Money = 1200000;
    Check(CheckSaveCollectionReforge(catalog, slotter, empty, { { 1, RUNIC_CONTAGION }, { 2, RUNIC_CONTAGION } }) ==
        COLLECTION_REFORGE_STACK_LIMIT, "the same enchant in two slots is past its stacks");

    Check(ValidSpecializationLink(0, true, 1, 1) && ValidSpecializationLink(19, true, 2, 2) &&
        ValidSpecializationLink(4, false, 0, 1), "a specialization links to an unlocked preset or to none");
    Check(!ValidSpecializationLink(20, true, 1, 1) && !ValidSpecializationLink(0, true, 0, 1) &&
        !ValidSpecializationLink(0, true, 3, 2),
        "a link outside the 20 specializations or the unlocked presets is refused");

    Character const freepick = Hero(plain, 80);
    std::vector<Enchant const*> const heroReveal = RevealPool(catalog, freepick, nullptr);
    Check(heroReveal == ReforgePool(catalog, freepick, nullptr) && !heroReveal.empty(),
        "a Hero reveals from the same pool a blank scroll reforges from");
    Character reborn = Hero(plain, 80);
    reborn.Class = WARRIOR;
    reborn.RealmGates = { true, false, false, false, false };
    std::vector<Enchant const*> const rebornReveal = RevealPool(catalog, reborn, nullptr);
    bool const otherClasses = std::any_of(rebornReveal.begin(), rebornReveal.end(),
        [](Enchant const* enchant) { return !ClassAllowed(*enchant, WARRIOR); });
    bool const ownClass = std::any_of(rebornReveal.begin(), rebornReveal.end(),
        [](Enchant const* enchant) { return ClassAllowed(*enchant, WARRIOR); });
    bool const rebornClean = std::all_of(rebornReveal.begin(), rebornReveal.end(), [&reborn](Enchant const* enchant)
        { return !enchant->Worldforged && (enchant->ClassMask & STOCK_CLASS_MASK) && RealmAllows(*enchant, reborn.RealmGates); });
    Check(otherClasses && ownClass && rebornClean,
        "a Warcraft Reborn reveal draws every stock class's scrolls of its realm, never a Worldforged one");
    Check(std::none_of(heroReveal.begin(), heroReveal.end(), [](Enchant const* enchant) { return enchant->Worldforged; }),
        "a Hero never reveals a Worldforged scroll");

    std::array<double, QUALITY_MAX> expected{};
    double expectedTotal = 0.0;
    for (Enchant const* enchant : ReforgePool(catalog, reborn, nullptr))
    {
        expected[QualityOf(*enchant, WARRIOR)] += enchant->Weight;
        expectedTotal += enchant->Weight;
    }
    std::array<double, QUALITY_MAX> revealed{};
    constexpr int SAMPLES = 4000;
    bool favoredRight = true;
    for (int sample = 0; sample < SAMPLES; ++sample)
    {
        double const unit = (sample + 0.5) / SAMPLES;
        Enchant const* chosen = RollReveal(catalog, reborn, nullptr,
            [](Enchant const& enchant) { return ClassAllowed(enchant, WARRIOR); }, unit, unit < 0.5 ? 0.1 : 0.9, 0.5);
        if (!chosen)
            continue;
        revealed[QualityOf(*chosen, WARRIOR)] += 1.0;
        favoredRight = favoredRight && ClassAllowed(*chosen, WARRIOR) == (unit < 0.5);
    }
    bool qualityMatches = expectedTotal > 0.0;
    for (std::uint32_t quality = 0; quality < QUALITY_MAX; ++quality)
        qualityMatches = qualityMatches && std::abs(revealed[quality] / SAMPLES - expected[quality] / expectedTotal) < 0.01;
    Check(qualityMatches, "a reveal's quality odds are a blank scroll reforge's");
    Check(favoredRight, "below 33% a Warcraft Reborn reveal is for the own class, above it for another class");
    Enchant const* fallback = RollReveal(catalog, freepick, nullptr, [](Enchant const&) { return false; }, 0.5, 0.1, 0.5);
    Check(fallback && !fallback->Worldforged, "with nothing favored, a reveal still gives a scroll from the rest");
    std::vector<std::uint32_t> rares;
    for (std::uint32_t item : RARE_SCROLLS)
        rares.push_back(catalog.FindItem(item)->Spell);
    std::vector<std::uint32_t> collected(rares.begin(), rares.begin() + 3);
    Character follower = Hero(fusion, 80);
    follower.Known = &collected;
    Slots guided = GuideSlots(catalog, follower, Slots{},
        { { rares[0], 1, 1 }, { rares[3], 1, 1 }, { rares[1], 1, 1 }, { rares[2], 1, 1 } });
    Check(guided[1] == rares[0] && guided[2] == rares[1] && guided[3] == rares[2] && !guided[4] && !guided[0],
        "a followed build applies only collected enchants, in its order, from the first fusion slot");
    Slots mine{};
    mine[1] = rares[4];
    mine[2] = rares[5];
    std::vector<std::uint32_t> withMine = { rares[0], rares[1], rares[4], rares[5] };
    follower.Known = &withMine;
    guided = GuideSlots(catalog, follower, mine, { { rares[0], 1, 1 }, { rares[1], 1, 1 } });
    Check(guided[1] == rares[0] && guided[2] == rares[1] && guided[3] == rares[4] && guided[4] == rares[5],
        "the build's enchants come first and the character's own fill the slots left");
    std::vector<std::uint32_t> allRares = rares;
    follower.Known = &allRares;
    guided = GuideSlots(catalog, follower, Slots{}, { { rares[0], 1, 1 }, { rares[1], 1, 1 }, { rares[2], 1, 1 },
        { rares[3], 1, 1 }, { rares[4], 1, 1 }, { rares[5], 1, 1 } });
    Check(std::count_if(guided.begin(), guided.end(), [](std::uint32_t spell) { return spell != 0; }) == 5,
        "the rare cap still holds: a sixth rare enchant is left out");
    Check(GuideSlots(catalog, follower, Slots{}, { { rares[0], 2, 1 } })[2] == 0,
        "the stack limit still holds");
    Character young = Hero(fusion, 80);
    young.Known = &allRares;
    young.Level = 20;
    guided = GuideSlots(catalog, young, Slots{}, { { rares[0], 1, 30 }, { rares[1], 1, 1 } });
    Check(guided[1] == rares[1] && !guided[2], "an enchant listed for a higher level waits");
    Character wildcardFollower = Hero(fusion, 80);
    wildcardFollower.GameModes = WILDCARD_MODE;
    wildcardFollower.Known = &allRares;
    Check(GuideSlots(catalog, wildcardFollower, Slots{}, { { rares[0], 1, 1 } }) == Slots{},
        "Wildcard applies no enchants");
    std::vector<std::uint32_t> firstOnly(rares.begin(), rares.begin() + 1);
    Character student = Hero(fusion, 20);
    student.Known = &firstOnly;
    Check(GuideLessons(catalog, student, { { rares[0], 1, 1 }, { rares[1], 2, 1 }, { rares[1], 1, 1 },
        { rares[2], 1, 30 }, { 1, 1, 1 } }) == std::vector<std::uint32_t>{ rares[1] },
        "a bot's build teaches each missing enchant of its level once");
    Check(holyPower && GuideLessons(catalog, student, { { holyPower->Spell, 1, 1 } }).empty(),
        "a bot's build never teaches an enchant its realm refuses");
    Character warriorStudent = student;
    warriorStudent.Class = WARRIOR;
    Check(GuideLessons(catalog, warriorStudent, { { RUNIC_CONTAGION, 1, 1 } }).empty(),
        "a bot's build never teaches an enchant of another class");
    Character wildcardStudent = student;
    wildcardStudent.GameModes = WILDCARD_MODE;
    Check(GuideLessons(catalog, wildcardStudent, { { rares[1], 1, 1 } }).empty(), "Wildcard learns no enchants");
    std::vector<std::uint32_t> taught = firstOnly;
    for (std::uint32_t spell : GuideLessons(catalog, student, { { rares[1], 1, 1 }, { rares[2], 1, 1 } }))
        taught.push_back(spell);
    Character graduate = Hero(fusion, 80);
    graduate.Known = &taught;
    guided = GuideSlots(catalog, graduate, Slots{}, { { rares[1], 1, 1 }, { rares[2], 1, 1 } });
    Check(guided[1] == rares[1] && guided[2] == rares[2], "once taught, a bot's build fills its slots");

    Character nowhere = Hero(plain, 80);
    nowhere.RealmGates = {};
    Check(!RollReveal(catalog, nowhere, nullptr, nullptr, 0.5, 0.5, 0.5), "a realm without enchants reveals nothing");

    return failures ? 1 : 0;
}
"""


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-mystic-enchant-rules-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionMysticEnchantRules.cpp",
                   ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("rules.exe" if os.name == "nt" else "rules")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Mystic enchant rules harness did not compile:\n" + build.stdout + build.stderr)
        raise SystemExit(subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True).returncode)


if __name__ == "__main__":
    main()
