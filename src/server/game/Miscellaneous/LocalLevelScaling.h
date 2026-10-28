/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU GPL.
 */

#ifndef AC_LOCAL_LEVEL_SCALING_H
#define AC_LOCAL_LEVEL_SCALING_H

#include "Define.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cstdint>
#include <optional>
#include <utility>

class Creature;
class Item;
class Player;
class Quest;
class Unit;
struct ItemTemplate;

namespace LocalLevelScaling
{
inline std::atomic<bool> QuestEnabled{false};
inline std::atomic<std::uint8_t> CreatureOffset{4};

/// Whether a query response marks a quest on its curve with the client's scaling flag, which colours
/// it "standard" instead of by level. Off by default: live quest caches never carried the flag.
inline std::atomic<bool> QuestClientScalingFlag{false};

/// The realm switches above are the default. A character can have a choice of their own, and
/// whichever module owns that choice installs a resolver here; the realm switches keep the final
/// say, because the resolver is only asked while they are on. With no resolver installed, or when
/// it has no opinion about the character, the realm-wide behaviour stands - which is what a
/// resolver returning true means.
using QuestScalingResolver = bool (*)(Player const*);
inline std::atomic<QuestScalingResolver> QuestScalingOwner{nullptr};

/// The character's own answer, with no realm switch in front of it: whether this character asked
/// for open-world scaling. The realm switches ask *whether* a character's choice is consulted at
/// all; this asks *what* it is, and is what the per-viewer combat paths resolve.
inline bool ScalingChoiceEnabled(Player const* player)
{
    QuestScalingResolver const owner = QuestScalingOwner.load(std::memory_order_relaxed);
    return owner && owner(player);
}

/// The parts of level scaling the character's active challenge switches off, as a mask of the
/// ChallengeBlocks* bits. The challenge module installs the resolver; zero means nothing is blocked.
inline constexpr std::uint8_t ChallengeBlocksCreatureScaling = 0x1;
inline constexpr std::uint8_t ChallengeBlocksQuestScaling = 0x2;
using ChallengeBlocksResolver = std::uint8_t (*)(Player const*);
inline std::atomic<ChallengeBlocksResolver> ChallengeBlocksOwner{nullptr};

inline std::uint8_t ChallengeBlocksFor(Player const* player)
{
    ChallengeBlocksResolver const owner = ChallengeBlocksOwner.load(std::memory_order_relaxed);
    return owner && player ? owner(player) : 0;
}

/// War Mode and High-Risk switch all level scaling off in the open world; their own tooltips say
/// "Level scaling is disabled while in War Mode / High-Risk". The ruleset owner installs the resolver.
using RulesetBlocksResolver = bool (*)(Player const*);
inline std::atomic<RulesetBlocksResolver> RulesetBlocksOwner{nullptr};

/// Everything that holds this character to the authored world, whatever their own choice: the
/// active challenge's rules and the open-world ruleset, as a mask of the ChallengeBlocks* bits.
inline std::uint8_t ScalingBlocksFor(Player const* player)
{
    RulesetBlocksResolver const ruleset = RulesetBlocksOwner.load(std::memory_order_relaxed);
    if (ruleset && player && ruleset(player))
        return ChallengeBlocksCreatureScaling | ChallengeBlocksQuestScaling;
    return ChallengeBlocksFor(player);
}

/// Whether the character stands in a dungeon that scales for everyone inside it, whatever their own or
/// their leader's choice. The module that owns the dungeon list installs the resolver.
using ScaledDungeonResolver = bool (*)(Player const*);
inline std::atomic<ScaledDungeonResolver> ScaledDungeonOwner{nullptr};

inline bool InScaledDungeon(Player const* player)
{
    ScaledDungeonResolver const owner = ScaledDungeonOwner.load(std::memory_order_relaxed);
    return owner && player && owner(player);
}

/// Whether the loot this character takes is scaled to them: only inside a scaled dungeon, and never
/// while a challenge holds them to the authored world. Open-world loot keeps its authored stats.
inline bool DungeonLootScales(Player const* player)
{
    return InScaledDungeon(player) && !(ScalingBlocksFor(player) & ChallengeBlocksCreatureScaling);
}

/// Something other than the character's own choice changed whether they see scaled content: a
/// challenge started or stopped, or the open-world ruleset changed. The module that owns the creature
/// view installs the resolver and re-sends what the client is holding; false means nobody did, so the
/// caller refreshes what it can.
using ScalingChangedResolver = void (*)(Player*);
inline std::atomic<ScalingChangedResolver> ScalingChangedOwner{nullptr};

inline bool NotifyScalingChanged(Player* player)
{
    ScalingChangedResolver const owner = ScalingChangedOwner.load(std::memory_order_relaxed);
    if (!owner || !player)
        return false;

    owner(player);
    return true;
}

inline bool QuestScalingEnabled(Player const* player)
{
    if (!QuestEnabled.load(std::memory_order_relaxed))
        return false;

    QuestScalingResolver const owner = QuestScalingOwner.load(std::memory_order_relaxed);
    if (owner && !owner(player))
        return false;
    return !(ScalingBlocksFor(player) & ChallengeBlocksQuestScaling);
}

/// One quest's row of QuestTemplateScaling.dbc: the levels it is held within and up to six
/// (player level, offset) points. Only quests with a row scale at all.
struct QuestCurve
{
    std::int32_t MinLevel = 0;
    std::int32_t MaxLevel = 0;
    std::uint8_t Count = 0;
    std::array<std::pair<std::int32_t, std::int32_t>, 6> Points{};
};

using QuestCurveResolver = QuestCurve const* (*)(std::uint32_t questId);
inline std::atomic<QuestCurveResolver> QuestCurveOwner{nullptr};

inline QuestCurve const* QuestCurveFor(std::uint32_t questId)
{
    QuestCurveResolver const owner = QuestCurveOwner.load(std::memory_order_relaxed);
    return owner ? owner(questId) : nullptr;
}

/// The curve a quest follows for a caller that already resolved the character's choice, or nullptr when
/// the quest is played at its authored level.
inline QuestCurve const* ScalingCurveFor(bool levelScaling, std::uint32_t questId)
{
    if (!levelScaling || !QuestEnabled.load(std::memory_order_relaxed))
        return nullptr;
    return QuestCurveFor(questId);
}

/// The level the curve puts a quest at for a character of `playerLevel`, before the row's bounds: the
/// point with the highest player level at or below the character's applies, so the quest trails the
/// character by that point's offset. Below every point the quest stays at its minimum; a row without
/// points follows the character.
inline std::int32_t UnclampedCurveLevel(QuestCurve const& curve, std::uint8_t playerLevel)
{
    std::int32_t const level = playerLevel;
    std::int32_t result = curve.Count ? std::max<std::int32_t>(1, curve.MinLevel) : level;
    bool found = false;
    std::int32_t bestThreshold = 0;
    for (std::uint8_t i = 0; i < curve.Count && i < curve.Points.size(); ++i)
    {
        auto const [threshold, offset] = curve.Points[i];
        if (level >= threshold && (!found || threshold > bestThreshold))
        {
            found = true;
            bestThreshold = threshold;
            result = level + offset;
        }
    }
    return result;
}

inline std::int32_t CurveLevel(QuestCurve const& curve, std::uint8_t playerLevel)
{
    std::int32_t const low = std::max<std::int32_t>(1, curve.MinLevel);
    std::int32_t const high = std::max(low, curve.MaxLevel);
    return std::clamp(UnclampedCurveLevel(curve, playerLevel), low, high);
}

/// Whether the quest is trailing the character right now: at or past its minimum and not yet held
/// down by its maximum.
inline bool OnCurve(QuestCurve const& curve, std::uint8_t playerLevel)
{
    std::int32_t const low = std::max<std::int32_t>(1, curve.MinLevel);
    std::int32_t const high = std::max(low, curve.MaxLevel);
    return std::int32_t(playerLevel) >= low && UnclampedCurveLevel(curve, playerLevel) <= high;
}

/// The level a quest is played at: its authored level (the character's own for a quest without one),
/// raised by its curve when it scales. Scaling never lowers a quest.
inline std::int32_t EffectiveQuestLevel(std::int32_t authoredLevel, std::uint8_t playerLevel,
    QuestCurve const* curve)
{
    std::int32_t const stock = authoredLevel > 0 ? authoredLevel : std::int32_t(playerLevel);
    return curve ? std::max(stock, CurveLevel(*curve, playerLevel)) : stock;
}

/// One character's version of one creature, asked for by the few places in the core that compute a
/// fight and cannot see the viewer's object fields: the armor a blow lands against, today. Returns
/// the armor the viewer's version of the creature wears, or nullopt when the creature is already their
/// version of it.
///
/// The implementation stays with whichever module owns the character's choice, so the level, the
/// pool, the armor and the damage all come out of one place and cannot disagree.
using CreatureViewArmorResolver = std::optional<std::uint32_t> (*)(Player const*, Creature const*);
inline std::atomic<CreatureViewArmorResolver> CreatureViewArmorOwner{nullptr};

inline std::optional<std::uint32_t> ViewArmorFor(Player const* viewer, Creature const* creature)
{
    CreatureViewArmorResolver const owner = CreatureViewArmorOwner.load(std::memory_order_relaxed);
    return owner ? owner(viewer, creature) : std::nullopt;
}

/// The level one character's version of one creature stands at, or zero when that character sees
/// the authored creature.
///
/// This is the lever every level-derived term in a fight hangs off. `Unit::getLevelForTarget` is
/// the function the core asks "how high is this unit, *relative to me*" - spell hit and resistance
/// tables, weapon and defence skill (`GetMaxSkillValueForLevel`, `GetUnitMeleeSkill`, and therefore
/// `GetWeaponSkillValue` / `GetDefenseSkillValue` for a creature), the glancing and crushing tables,
/// stealth detection, aggro radius, and kill experience all read it. It is already virtual and
/// already overridden to give world bosses a target-relative level, which is exactly the shape a
/// per-viewer level needs: with a view installed, one character rolls against the level they are
/// fighting while everybody else rolls against the authored creature, from one definition.
///
/// Zero means "no view", so an unset owner, a character who never chose scaling, or a creature that
/// already is their version of it all keep the stock behaviour.
using CreatureViewLevelResolver = std::uint8_t (*)(Player const*, Creature const*);
inline std::atomic<CreatureViewLevelResolver> CreatureViewLevelOwner{nullptr};

inline std::uint8_t ViewLevelFor(Player const* viewer, Creature const* creature)
{
    CreatureViewLevelResolver const owner = CreatureViewLevelOwner.load(std::memory_order_relaxed);
    return owner ? owner(viewer, creature) : 0;
}

/// The max health one character's version of one creature has, or zero when that character sees the
/// authored creature. For effects worded as a share of "the creature's health", which the character
/// reads off the health bar they are shown.
using CreatureViewMaxHealthResolver = std::uint32_t (*)(Player const*, Creature const*);
inline std::atomic<CreatureViewMaxHealthResolver> CreatureViewMaxHealthOwner{nullptr};

inline std::uint32_t ViewMaxHealthFor(Player const* viewer, Creature const* creature)
{
    CreatureViewMaxHealthResolver const owner = CreatureViewMaxHealthOwner.load(std::memory_order_relaxed);
    return owner ? owner(viewer, creature) : 0;
}

/// `threat` that the character behind `source` generated against `threatOwner`, in the creature's real
/// health pool: their damage already reaches the pool converted, and threat from anything else (healing,
/// threat spells, mana drains) is converted by the same ratio so it keeps pace with damage threat. Unchanged
/// when no character sees a version of the creature.
AC_GAME_API float PoolThreatFor(Unit const* source, Unit const* threatOwner, float threat);

/// The health `victim` shows the character behind `attacker`: the real health scaled to that character's
/// version of the creature, which is the size damage logs report hits in. The real health otherwise.
AC_GAME_API std::uint32_t ShownHealthFor(Unit const* attacker, Unit const* victim);

/// The level a *viewer* is shown for an open-world creature: never lowered, and lifted to the viewer's
/// level minus the offset. A view is told to nobody else, so it has no ceiling: the creature in front
/// of a character comes all the way up to that character's band, which is the whole point of the
/// feature (a starting-zone creature stays relevant to the character standing in front of it).
inline std::uint8_t ScaleCreatureLevelForViewer(std::uint8_t originalLevel, std::uint8_t playerLevel,
    std::uint8_t offset = 4)
{
    std::uint8_t floor = playerLevel > offset ? playerLevel - offset : 1;
    return std::max(originalLevel, floor);
}

/// The levels one classic dungeon is scaled within, as the dungeon finder lists it.
struct LevelBand
{
    std::uint8_t Low;
    std::uint8_t High;
};

/// The band of one dungeon finder entry. Entries the finder never offers carry placeholder levels
/// (100/100 for Wailing Caverns, Gnomeregan and Uldaman), so a bound outside 1-60 falls back to
/// 15-59, the range the finder's classic dungeons share.
inline LevelBand DungeonBandFromFinder(std::uint32_t minLevel, std::uint32_t maxLevel)
{
    std::uint8_t const low = minLevel >= 1 && minLevel <= 60 ? static_cast<std::uint8_t>(minLevel) : 15;
    std::uint8_t const high = maxLevel >= low && maxLevel <= 60 ? static_cast<std::uint8_t>(maxLevel) : 59;
    return { low, high };
}

/// One map can be listed by several finder entries (Scarlet Monastery's four wings, Maraudon's three):
/// its band covers all of them.
inline LevelBand MergeBands(LevelBand a, LevelBand b)
{
    return { std::min(a.Low, b.Low), std::max(a.High, b.High) };
}

/// The viewer's rule inside a scaled five-player dungeon: every creature stands at the viewer's own
/// level, held inside the dungeon's band on both sides. The dungeon finder admits a group well below a
/// classic dungeon's authored level (Scarlet Monastery - Cathedral from 20 against creatures of 36-40),
/// so a dungeon creature comes down as well as up.
inline std::uint8_t ScaleDungeonCreatureLevelForViewer(std::uint8_t playerLevel, LevelBand band)
{
    return std::clamp(playerLevel, band.Low, band.High);
}

/// Item templates that are not in the world database: lifted copies of authored items, made when
/// scaled content drops or rewards an item for a character above the content's level. Items already
/// handed out keep pointing at their copy, so the owner serves every copy it ever made even while new
/// lifts are switched off - an inventory whose template went missing would be deleted on login.
using ScaledItemTemplateResolver = ItemTemplate const* (*)(std::uint32_t entry);
inline std::atomic<ScaledItemTemplateResolver> ScaledItemTemplateOwner{nullptr};

inline ItemTemplate const* ScaledItemTemplateFor(std::uint32_t entry)
{
    ScaledItemTemplateResolver const owner = ScaledItemTemplateOwner.load(std::memory_order_relaxed);
    return owner ? owner(entry) : nullptr;
}

/// The item one character is offered and given for a quest's reward slot: the authored item, or a
/// copy lifted by as many levels as the quest itself is lifted for that character. The offer, the
/// query response and the reward all ask here, so what is shown is what is received.
using QuestRewardItemResolver = std::uint32_t (*)(Player const*, std::uint32_t itemId, Quest const* quest);
inline std::atomic<QuestRewardItemResolver> QuestRewardItemOwner{nullptr};

inline std::uint32_t QuestRewardItemFor(Player const* player, std::uint32_t itemId, Quest const* quest)
{
    QuestRewardItemResolver const owner = QuestRewardItemOwner.load(std::memory_order_relaxed);
    return owner && itemId && quest ? owner(player, itemId, quest) : itemId;
}

/// The template one item instance is built from. An item that was given a scaling level of its own keeps
/// its authored entry, so the client still knows it, but its stats, damage, armor, required level, sell
/// price and disenchant loot come from the row for that level. The paths that apply, check or price an item ask here;
/// nullptr from the owner means the instance is the authored item.
using ItemInstanceTemplateResolver = ItemTemplate const* (*)(Item const*);
inline std::atomic<ItemInstanceTemplateResolver> ItemInstanceTemplateOwner{nullptr};

inline ItemTemplate const* InstanceTemplateFor(Item const* item, ItemTemplate const* authored)
{
    ItemInstanceTemplateResolver const owner = ItemInstanceTemplateOwner.load(std::memory_order_relaxed);
    if (!owner || !item)
        return authored;

    ItemTemplate const* scaled = owner(item);
    return scaled ? scaled : authored;
}

/// The armor one character gets from wearing an item built from this template. The client shows the
/// reborn armor column to every class but the classless Hero, so the owner of item ladders answers
/// with that column for those classes; without an owner the template's own armor applies.
using WornArmorResolver = std::uint32_t (*)(Player const*, ItemTemplate const*, std::uint32_t armor);
inline std::atomic<WornArmorResolver> WornArmorOwner{nullptr};

inline std::uint32_t WornArmorFor(Player const* player, ItemTemplate const* proto, std::uint32_t armor)
{
    WornArmorResolver const owner = WornArmorOwner.load(std::memory_order_relaxed);
    return owner && player && proto ? owner(player, proto, armor) : armor;
}

/// An item instance moved into a character's inventory from somewhere the character's login did not
/// cover: a trade, a mail. The owner of instance levels tells the client the level of such an item.
using ItemArrivalResolver = void (*)(Player*, Item*);
inline std::atomic<ItemArrivalResolver> ItemArrivalOwner{nullptr};

inline void NotifyItemArrival(Player* player, Item* item)
{
    ItemArrivalResolver const owner = ItemArrivalOwner.load(std::memory_order_relaxed);
    if (owner && player && item)
        owner(player, item);
}

/// An item a master looter handed to `receiver`. That path never reaches the loot hooks, so the owner
/// of instance levels is told here and gives the item the receiver's level like any other loot.
using MasterLootResolver = void (*)(Player* receiver, Item* item);
inline std::atomic<MasterLootResolver> MasterLootOwner{nullptr};

inline void NotifyMasterLoot(Player* receiver, Item* item)
{
    MasterLootResolver const owner = MasterLootOwner.load(std::memory_order_relaxed);
    if (owner && receiver && item)
        owner(receiver, item);
}

/// A quest reward just stored for `player`, before the reward hooks run, so the owner of instance levels
/// can give it the level the quest itself showed for it.
using QuestRewardLevelResolver = void (*)(Player* player, Item* item, Quest const* quest);
inline std::atomic<QuestRewardLevelResolver> QuestRewardLevelOwner{nullptr};

inline void NotifyQuestRewardItem(Player* player, Item* item, Quest const* quest)
{
    QuestRewardLevelResolver const owner = QuestRewardLevelOwner.load(std::memory_order_relaxed);
    if (owner && player && item && quest)
        owner(player, item, quest);
}

/// The loot preview. The client shows a scaling item that has no level of its own yet (a loot slot, a
/// roll, an inspected or auctioned item) at a level the server tells it beforehand, so each character
/// sees the version they would receive. The owner of instance levels installs these hooks only while the
/// preview is on; without them the client shows the authored items.
struct ItemPreviewHooks
{
    /// Tells `roller` the level their next roll frame shows and returns it, zero for none.
    std::uint32_t (*RollLevel)(Player* roller);
    /// The level a lootable corpse shows `viewer`, zero for its usual one.
    std::uint32_t (*CorpseLevel)(Player* viewer, Creature const* corpse);
    /// Tells `inspector` the level of each item `target` wears.
    void (*Inspected)(Player* inspector, Player* target);
    /// Tells `player` the level of each item waiting in their mailbox.
    void (*MailListed)(Player* player);
    /// The level an auction of the instance `itemGuidLow` lists, zero for none.
    std::uint32_t (*AuctionLevel)(std::uint32_t itemGuidLow, ItemTemplate const* proto);
};
inline std::atomic<ItemPreviewHooks const*> ItemPreviewOwner{nullptr};

inline bool ItemPreviewActive()
{
    return ItemPreviewOwner.load(std::memory_order_relaxed) != nullptr;
}

inline std::uint32_t RollPreviewLevel(Player* roller)
{
    ItemPreviewHooks const* hooks = ItemPreviewOwner.load(std::memory_order_relaxed);
    return hooks && roller ? hooks->RollLevel(roller) : 0;
}

inline std::uint32_t CorpsePreviewLevel(Player* viewer, Creature const* corpse)
{
    ItemPreviewHooks const* hooks = ItemPreviewOwner.load(std::memory_order_relaxed);
    return hooks && viewer && corpse ? hooks->CorpseLevel(viewer, corpse) : 0;
}

inline void NotifyInspected(Player* inspector, Player* target)
{
    ItemPreviewHooks const* hooks = ItemPreviewOwner.load(std::memory_order_relaxed);
    if (hooks && inspector && target)
        hooks->Inspected(inspector, target);
}

inline void NotifyMailListed(Player* player)
{
    ItemPreviewHooks const* hooks = ItemPreviewOwner.load(std::memory_order_relaxed);
    if (hooks && player)
        hooks->MailListed(player);
}

inline std::uint32_t AuctionPreviewLevel(std::uint32_t itemGuidLow, ItemTemplate const* proto)
{
    ItemPreviewHooks const* hooks = ItemPreviewOwner.load(std::memory_order_relaxed);
    return hooks && proto ? hooks->AuctionLevel(itemGuidLow, proto) : 0;
}
}

#endif
