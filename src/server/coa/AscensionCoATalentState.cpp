#include "AscensionCoATalentState.h"
#include <algorithm>
#include <cstring>
#include <unordered_set>

namespace AscensionCoATalentState
{
namespace
{
constexpr std::size_t RECORD_SIZE = 21;

void AppendUInt32(std::vector<std::uint8_t>& out, std::uint32_t value)
{
    for (int shift = 0; shift < 32; shift += 8)
        out.push_back(std::uint8_t(value >> shift));
}

std::uint32_t ReadUInt32(std::uint8_t const* data)
{
    return std::uint32_t(data[0]) | (std::uint32_t(data[1]) << 8) | (std::uint32_t(data[2]) << 16) |
        (std::uint32_t(data[3]) << 24);
}

AscensionCompatData::CoATalentEntry const* FindEntry(std::uint32_t entryId)
{
    auto const& entries = AscensionCompatData::CoATalentEntries;
    auto itr = std::lower_bound(entries.begin(), entries.end(), entryId,
        [](AscensionCompatData::CoATalentEntry const& entry, std::uint32_t id) { return entry.EntryId < id; });
    return itr != entries.end() && itr->EntryId == entryId ? &*itr : nullptr;
}

bool IsSelectableFree(std::uint32_t entryId)
{
    return std::any_of(AscensionCompatData::CoASelectableFreeEntries.begin(),
        AscensionCompatData::CoASelectableFreeEntries.end(),
        [entryId](AscensionCompatData::CoASelectableFreeEntry const& entry) { return entry.EntryId == entryId; });
}

bool IsIdentity(std::uint32_t entryId)
{
    return std::any_of(AscensionCompatData::CoASpecializations.begin(),
        AscensionCompatData::CoASpecializations.end(),
        [entryId](AscensionCompatData::CoASpecialization const& specialization)
        {
            return specialization.IdentityEntryId == entryId;
        });
}
}

std::vector<std::uint32_t> SpecializationSlotRecord(SpecializationSlot const& slot)
{
    std::vector<std::uint32_t> record = { 1, slot.ClassId, slot.SpecId, std::uint32_t(slot.Entries.size()) };
    for (KnownEntry const& entry : slot.Entries)
    {
        record.push_back(entry.EntryId);
        record.push_back(entry.Rank);
    }
    record.push_back(std::uint32_t(slot.Actions.size()));
    for (auto const& [button, action] : slot.Actions)
    {
        record.push_back(button);
        record.push_back(action);
    }
    return record;
}

bool ParseSpecializationSlot(std::vector<std::uint32_t> const& record, SpecializationSlot& slot)
{
    if (record.size() < 5 || record[0] != 1 || record[1] < 12 || record[1] > 32 ||
        record[3] > (record.size() - 5) / 2)
        return false;

    SpecializationSlot parsed;
    parsed.ClassId = record[1];
    parsed.SpecId = record[2];
    std::size_t cursor = 4;
    for (std::size_t index = 0; index < record[3]; ++index, cursor += 2)
        parsed.Entries.push_back({ record[cursor], record[cursor + 1] });

    std::uint32_t const actions = record[cursor++];
    if (actions > (record.size() - cursor) / 2)
        return false;
    std::unordered_set<std::uint32_t> buttons;
    for (std::uint32_t index = 0; index < actions; ++index, cursor += 2)
    {
        if (record[cursor] >= 144 || !record[cursor + 1] || !buttons.insert(record[cursor]).second)
            return false;
        parsed.Actions.emplace_back(record[cursor], record[cursor + 1]);
    }
    if (std::any_of(record.begin() + cursor, record.end(), [](std::uint32_t value) { return value != 0; }))
        return false;
    slot = std::move(parsed);
    return true;
}

std::uint32_t KnownRank(AscensionCompatData::CoATalentEntry const& entry, HasSpell const& hasSpell)
{
    std::uint32_t rank = 0;
    for (std::uint32_t index = 0; index < entry.SpellCount; ++index)
        if (entry.SpellIds[index] && hasSpell(entry.SpellIds[index]))
            rank = index + 1;
    return rank;
}

std::vector<KnownEntry> KnownEntries(std::uint8_t classId, HasSpell const& hasSpell)
{
    std::vector<KnownEntry> known;
    for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
    {
        if (entry.ClassId != classId)
            continue;
        if (std::uint32_t rank = KnownRank(entry, hasSpell))
            known.push_back({ entry.EntryId, rank });
    }
    return known;
}

bool CanGrantAutomatic(AscensionCompatData::CoATalentEntry const& entry, std::uint8_t classId, std::uint32_t level,
    std::uint32_t specId, HasSpell const& hasSpell)
{
    if (entry.ClassId != classId || (entry.SpecId != 0 && entry.SpecId != specId) || entry.AECost != 0 ||
        entry.TECost != 0 || entry.RequiredLevel > level || !entry.SpellCount || IsSelectableFree(entry.EntryId))
        return false;

    auto const& dependencies = AscensionCompatData::CoAAutomaticDependencies;
    auto dependency = std::lower_bound(dependencies.begin(), dependencies.end(), entry.EntryId,
        [](AscensionCompatData::CoAAutomaticDependency const& value, std::uint32_t id) { return value.EntryId < id; });
    if (dependency == dependencies.end() || dependency->EntryId != entry.EntryId)
        return true;

    for (std::uint32_t requiredId : dependency->RequiredEntryIds)
    {
        if (!requiredId)
            continue;
        AscensionCompatData::CoATalentEntry const* required = FindEntry(requiredId);
        if (!required || required->ClassId != classId ||
            std::none_of(required->SpellIds.begin(), required->SpellIds.end(),
                [&hasSpell](std::uint32_t spellId) { return spellId && hasSpell(spellId); }))
            return false;
    }
    return true;
}

std::vector<KnownEntry> SlotKnownEntries(SpecializationSlot const& slot, std::uint32_t level,
    HasSpell const& carried)
{
    std::unordered_set<std::uint32_t> spells;
    for (KnownEntry const& pick : slot.Entries)
        if (AscensionCompatData::CoATalentEntry const* entry = FindEntry(pick.EntryId);
            entry && entry->ClassId == slot.ClassId && pick.Rank && pick.Rank <= entry->SpellCount &&
            entry->SpellIds[pick.Rank - 1])
            spells.insert(entry->SpellIds[pick.Rank - 1]);

    HasSpell const known = [&spells, &carried](std::uint32_t spellId)
    {
        return spells.contains(spellId) || (carried && carried(spellId));
    };
    std::uint8_t const classId = std::uint8_t(slot.ClassId);
    bool changed = level > 1;
    for (std::size_t pass = 0; changed && pass < AscensionCompatData::CoATalentEntries.size(); ++pass)
    {
        changed = false;
        for (AscensionCompatData::CoATalentEntry const& entry : AscensionCompatData::CoATalentEntries)
        {
            std::uint32_t const spellId = entry.SpellCount ? entry.SpellIds[entry.SpellCount - 1] : 0;
            if (spellId && !known(spellId) && CanGrantAutomatic(entry, classId, level, slot.SpecId, known))
                changed = spells.insert(spellId).second || changed;
        }
    }
    return KnownEntries(classId, known);
}

std::vector<std::uint8_t> InspectSpecsPayload(std::vector<std::vector<KnownEntry>> const& specs)
{
    std::vector<std::uint8_t> out;
    AppendUInt32(out, std::uint32_t(specs.size()));
    for (std::vector<KnownEntry> const& known : specs)
    {
        std::vector<std::uint8_t> const list = KnownEntriesPayload(known);
        out.insert(out.end(), list.begin(), list.end());
    }
    return out;
}

SpentPoints Spent(std::vector<KnownEntry> const& known)
{
    SpentPoints spent;
    std::unordered_set<std::uint32_t> charged;
    for (KnownEntry const& item : known)
    {
        AscensionCompatData::CoATalentEntry const* entry = FindEntry(item.EntryId);
        if (!entry || (!entry->AECost && !entry->TECost))
            continue;

        std::uint32_t const ranks = std::min<std::uint32_t>(item.Rank, entry->SpellCount);
        for (std::uint32_t index = 0; index < ranks; ++index)
        {
            if (!charged.insert(entry->SpellIds[index]).second)
                continue;
            if (entry->SpecId)
                spent.TE += entry->TECost;
            else
                spent.AE += entry->AECost;
        }
    }
    return spent;
}

std::vector<std::uint8_t> KnownEntriesPayload(std::vector<KnownEntry> const& known)
{
    std::vector<std::uint8_t> out;
    out.reserve(sizeof(std::uint32_t) + known.size() * RECORD_SIZE);
    AppendUInt32(out, std::uint32_t(known.size()));
    for (KnownEntry const& item : known)
    {
        AppendUInt32(out, item.EntryId);
        AppendUInt32(out, item.Rank);
        AppendUInt32(out, item.LearnedSpellRank);
        out.push_back(item.Locked ? 1 : 0);
        AppendUInt32(out, item.LearnOrder);
        AppendUInt32(out, 0);
    }
    return out;
}

bool ParseKnownEntriesUpload(std::uint8_t const* data, std::size_t size, std::vector<KnownEntry>& known)
{
    known.clear();
    if (!data || size < sizeof(std::uint32_t))
        return false;

    std::uint32_t const count = ReadUInt32(data);
    if (size != sizeof(std::uint32_t) + std::size_t(count) * RECORD_SIZE)
        return false;

    known.reserve(count);
    for (std::uint32_t index = 0; index < count; ++index)
    {
        std::uint8_t const* record = data + sizeof(std::uint32_t) + std::size_t(index) * RECORD_SIZE;
        known.push_back({ ReadUInt32(record), ReadUInt32(record + 4) });
    }
    return true;
}

UploadedSpecialization SpecializationOf(std::vector<KnownEntry> const& upload)
{
    UploadedSpecialization uploaded;
    std::vector<AscensionCompatData::CoATalentEntry const*> chosen;
    for (KnownEntry const& item : upload)
    {
        AscensionCompatData::CoATalentEntry const* entry = item.Rank ? FindEntry(item.EntryId) : nullptr;
        if (!entry || !entry->SpecId)
            continue;
        bool const paid = entry->AECost || entry->TECost || IsSelectableFree(entry->EntryId);
        if (!paid && !IsIdentity(entry->EntryId))
            continue;
        if (uploaded.SpecId && uploaded.SpecId != entry->SpecId)
            uploaded.Mixed = true;
        else
            uploaded.SpecId = entry->SpecId;
        if (paid)
            chosen.push_back(entry);
    }

    AscensionCompatData::CoASpecialization const* signature = nullptr;
    for (AscensionCompatData::CoASpecialization const& specialization : AscensionCompatData::CoASpecializations)
        if (specialization.SpecId == uploaded.SpecId)
            signature = &specialization;
    uploaded.ChoosesTalents = std::any_of(chosen.begin(), chosen.end(),
        [signature](AscensionCompatData::CoATalentEntry const* entry)
        {
            return !signature || entry->EntryId != signature->SignatureEntryId;
        });
    return uploaded;
}

std::vector<std::uint32_t> SpellsAboveRank(AscensionCompatData::CoATalentEntry const& entry, std::uint32_t rank)
{
    std::vector<std::uint32_t> spells;
    for (std::uint32_t index = rank; index < entry.SpellCount; ++index)
        if (entry.SpellIds[index])
            spells.push_back(entry.SpellIds[index]);
    return spells;
}

bool IsUnpricedRemoval(AscensionCompatData::CoATalentEntry const& entry)
{
    if (!entry.AECost && !entry.TECost && !IsSelectableFree(entry.EntryId))
        return true;
    return std::any_of(AscensionCompatData::CoASpecializations.begin(), AscensionCompatData::CoASpecializations.end(),
        [&entry](AscensionCompatData::CoASpecialization const& specialization)
        {
            return specialization.SignatureEntryId == entry.EntryId;
        });
}

UnlearnPrice UnlearnPriceAt(std::uint32_t level, ResetCredits const& credits, bool freeUnlearn)
{
    if (level <= 10 || freeUnlearn)
        return {};
    std::uint32_t const tier = level <= 19 ? 32 : level <= 29 ? 71 : level <= 49 ? 521 : level <= 59 ? 1107 : 2221;
    double const base = double(tier) * level * 0.25;
    std::uint32_t const repeats = credits[std::size_t(ResetCreditType::TalentReset) - 1] +
        credits[std::size_t(ResetCreditType::AbilityUnlearn) - 1];
    double const extra = double(std::int32_t(repeats)) * 4.16666666666667 * level * 0.25;
    UnlearnPrice price;
    price.Money = std::uint32_t(std::int32_t(std::min(std::max(2147483647.0 - base, 0.0), extra) + base));
    price.Marks = level * 4;
    return price;
}

PurgePrice TalentPurgePriceAt(std::uint32_t level, ResetCredits const& credits)
{
    PurgePrice price;
    price.Item = TALENT_PURGE_ITEM;
    if (level <= 10)
        return price;
    double const lvl = double(level);
    double const resets = double(credits[std::size_t(ResetCreditType::TalentReset) - 1]);
    double cost = lvl * lvl * 1.16220833333333 + resets * 0.0416666666666667 * 10000.0;
    cost = (cost + lvl * 18.7038333333333 - 359.025) * lvl * 0.25;
    price.Money = std::uint32_t(std::int64_t(cost > 4294967295.0 ? 4294967295.0 : cost));
    price.Marks = level * 125;
    price.ItemCount = 1;
    return price;
}

RemovalPayment PayForRemovals(std::vector<UnlearnPrice> const& prices, std::uint32_t marksHeld,
    std::uint32_t moneyHeld)
{
    RemovalPayment payment;
    for (UnlearnPrice const& price : prices)
    {
        if (!price.Marks && !price.Money)
            continue;
        if (price.Marks && marksHeld >= price.Marks)
        {
            marksHeld -= price.Marks;
            payment.Marks += price.Marks;
            continue;
        }
        if (!price.Money || std::uint64_t(payment.Money) + price.Money > moneyHeld)
            return { false, 0, 0 };
        payment.Money += price.Money;
    }
    return payment;
}

std::vector<KnownEntry> SpecializationSwitch(std::uint8_t classId, HasSpell const& hasSpell, std::uint32_t specId,
    std::vector<KnownEntry> const* current)
{
    std::unordered_set<std::uint32_t> departedSignatures;
    for (AscensionCompatData::CoASpecialization const& specialization : AscensionCompatData::CoASpecializations)
        if (specialization.ClassId == classId && specialization.SpecId != specId)
            if (auto const* identity = FindEntry(specialization.IdentityEntryId);
                identity && KnownRank(*identity, hasSpell))
                departedSignatures.insert(specialization.SignatureEntryId);

    std::vector<KnownEntry> upload;
    for (KnownEntry const& known : current ? *current : KnownEntries(classId, hasSpell))
        if (AscensionCompatData::CoATalentEntry const* entry = FindEntry(known.EntryId);
            entry && !entry->SpecId && !departedSignatures.contains(known.EntryId))
            upload.push_back(known);

    for (AscensionCompatData::CoASpecialization const& specialization : AscensionCompatData::CoASpecializations)
    {
        if (specialization.SpecId != specId || specialization.ClassId != classId)
            continue;
        upload.push_back({ specialization.IdentityEntryId, 1 });
        if (specialization.SignatureEntryId && specialization.SignatureEntryId != specialization.IdentityEntryId &&
            std::none_of(upload.begin(), upload.end(),
                [&specialization](KnownEntry const& item) { return item.EntryId == specialization.SignatureEntryId; }))
            upload.push_back({ specialization.SignatureEntryId, 1 });
        break;
    }
    return upload;
}
}
