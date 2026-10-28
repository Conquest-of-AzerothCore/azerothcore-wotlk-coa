CLI_DESCRIPTION = """Check the CoA talent budget table and the spellbook-derived talent state without a server.

Compiles the module's talent catalog loader and talent state code against the client DBC set the server loads
(--dbc-dir), then checks the essence budgets, rank derivation, point accounting, the known-entries wire form and
the specialization a known-entries upload selects.
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
#include "AscensionCoATalentData.h"
#include "AscensionCoATalentState.h"
#include "DBCStores.h"
#include <algorithm>
#include <cstdio>
#include <set>

using namespace AscensionCompatData;
using namespace AscensionCoATalentState;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

CoATalentEntry const* Find(std::uint32_t entryId)
{
    for (CoATalentEntry const& entry : CoATalentEntries)
        if (entry.EntryId == entryId)
            return &entry;
    return nullptr;
}

// The first paid entry of a class on a tree, with at least `ranks` ranks.
CoATalentEntry const* FirstPaid(std::uint8_t classId, bool classTree, std::uint32_t ranks = 1)
{
    for (CoATalentEntry const& entry : CoATalentEntries)
        if (entry.ClassId == classId && (entry.AECost || entry.TECost) && (entry.SpecId == 0) == classTree &&
            entry.SpellCount >= ranks)
            return &entry;
    return nullptr;
}
}

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    Check(LoadCoATalentData(), "catalog loads with the essence table");

    // Budgets: the client's local rule is one class point at 10, one specialization point at 11, alternating.
    std::uint32_t ae = 0, te = 0;
    bool everyClass = true;
    for (std::uint8_t classId = 12; classId <= 32; ++classId)
    {
        everyClass = everyClass && GetCoATalentBudget(classId, 10, ae, te) && ae == 1 && te == 0;
        everyClass = everyClass && GetCoATalentBudget(classId, 11, ae, te) && ae == 1 && te == 1;
        everyClass = everyClass && GetCoATalentBudget(classId, 60, ae, te) && ae == 26 && te == 25;
        everyClass = everyClass && GetCoATalentBudget(classId, 80, ae, te) && ae == 36 && te == 35;
    }
    Check(everyClass, "every custom class has the 1/0, 1/1, 26/25 and 36/35 budgets at levels 10, 11, 60, 80");
    Check(GetCoATalentBudget(30, 9, ae, te) && ae == 0 && te == 0, "level 9 holds no points");
    Check(GetCoATalentBudget(30, 255, ae, te) && ae == 36 && te == 35, "a level past the table keeps the last row");
    Check(!GetCoATalentBudget(1, 60, ae, te), "a native class has no budget row");

    // Ranks and points from a spellbook.
    CoATalentEntry const* three = nullptr;
    for (CoATalentEntry const& entry : CoATalentEntries)
        if ((entry.AECost || entry.TECost) && entry.SpellCount == 3 && entry.SpecId == 0)
        {
            three = &entry;
            break;
        }
    Check(three != nullptr, "a paid three-rank class talent exists");
    CoATalentEntry const* spec = three ? FirstPaid(three->ClassId, false) : nullptr;
    Check(spec != nullptr, "the same class has a paid specialization talent");
    if (three && spec)
    {
        std::set<std::uint32_t> spellbook = { three->SpellIds[1], spec->SpellIds[0] };
        HasSpell hasSpell = [&spellbook](std::uint32_t id) { return spellbook.count(id) != 0; };
        Check(KnownRank(*three, hasSpell) == 2, "rank is the highest owned rank spell");
        Check(KnownRank(*spec, hasSpell) == 1, "a single owned rank spell is rank 1");
        std::vector<KnownEntry> known = KnownEntries(three->ClassId, hasSpell);
        Check(known.size() == 2, "known entries list exactly the owned entries");
        SpentPoints spent = Spent(known);
        Check(spent.AE == 2 * three->AECost && spent.TE == spec->TECost,
              "spent points charge every rank on the tree it belongs to");
        Check(Spent({}).AE == 0 && Spent({}).TE == 0, "nothing owned spends nothing");
        Check(KnownEntries(three->ClassId, [](std::uint32_t) { return false; }).empty(),
              "an empty spellbook knows no entry");

        // Shared rank spell: charged once, to the lower entry id (7131 and 12264 share 503748 in the catalog).
        CoATalentEntry const* first = Find(7131);
        CoATalentEntry const* second = Find(12264);
        if (first && second && first->SpellIds[0] == second->SpellIds[0])
        {
            std::vector<KnownEntry> shared = { { 7131, 1 }, { 12264, 1 } };
            SpentPoints once = Spent(shared);
            Check(once.AE + once.TE == 1, "a rank spell two entries share is charged once");
            Check(once.TE == 1 && once.AE == 0, "the shared spell is charged to the lower entry id's tree");
        }
        else
            Check(false, "catalog still shares spell 503748 between entries 7131 and 12264");

        // Wire form.
        std::vector<std::uint8_t> body = KnownEntriesPayload(known);
        Check(body.size() == 4 + 21 * known.size(), "known-entries body is u32 count plus 21 bytes per record");
        Check(body[0] == 2 && body[1] == 0 && body[2] == 0 && body[3] == 0, "count is little-endian");
        std::vector<KnownEntry> parsed;
        Check(ParseKnownEntriesUpload(body.data(), body.size(), parsed) && parsed.size() == 2 &&
                  parsed[0].EntryId == known[0].EntryId && parsed[0].Rank == known[0].Rank &&
                  parsed[1].EntryId == known[1].EntryId && parsed[1].Rank == known[1].Rank,
              "the upload parser reads back what the payload wrote");
        Check(!ParseKnownEntriesUpload(body.data(), body.size() - 1, parsed), "a short body is refused");
        body.push_back(0);
        Check(!ParseKnownEntriesUpload(body.data(), body.size(), parsed), "a long body is refused");
        std::uint8_t empty[4] = { 0, 0, 0, 0 };
        Check(ParseKnownEntriesUpload(empty, 4, parsed) && parsed.empty(), "count zero is an empty set");
        Check(!ParseKnownEntriesUpload(empty, 3, parsed), "less than a count is refused");
        Check(KnownEntriesPayload({}).size() == 4, "an empty set is a bare zero count");
    }

    std::set<std::uint8_t> specializedClasses;
    for (CoATalentEntry const& entry : CoATalentEntries)
        if (entry.SpecId)
            specializedClasses.insert(entry.ClassId);
    std::set<std::uint8_t> identifiedClasses;
    bool identitiesBelong = !CoASpecializations.empty();
    bool switchesDetected = true;
    for (CoASpecialization const& specialization : CoASpecializations)
    {
        identifiedClasses.insert(specialization.ClassId);
        CoATalentEntry const* identity = Find(specialization.IdentityEntryId);
        identitiesBelong = identitiesBelong && identity && identity->ClassId == specialization.ClassId &&
            identity->SpecId == specialization.SpecId;
        UploadedSpecialization const uploaded = SpecializationOf(
            SpecializationSwitch(specialization.ClassId, [](std::uint32_t) { return false; }, specialization.SpecId));
        switchesDetected = switchesDetected && uploaded.SpecId == specialization.SpecId && !uploaded.Mixed &&
            !uploaded.ChoosesTalents;
    }
    Check(identitiesBelong,
          "every specialization identity entry is a catalog entry of its own class and specialization");
    Check(identifiedClasses == specializedClasses, "every class with specialization talents has identity entries");
    Check(switchesDetected,
          "a switch upload names exactly the specialization it enters and chooses none of its talents");

    CoATalentEntry const* classTalent = spec ? FirstPaid(spec->ClassId, true) : nullptr;
    std::vector<CoASpecialization> specializations;
    for (CoASpecialization const& specialization : CoASpecializations)
        if (classTalent && specialization.ClassId == classTalent->ClassId)
            specializations.push_back(specialization);
    Check(classTalent && specializations.size() >= 2, "a class has a paid class talent and two specializations");
    if (classTalent && specializations.size() >= 2)
    {
        std::set<std::uint32_t> spellbook = { classTalent->SpellIds[0] };
        HasSpell hasSpell = [&spellbook](std::uint32_t id) { return spellbook.count(id) != 0; };
        std::vector<KnownEntry> const entering =
            SpecializationSwitch(classTalent->ClassId, hasSpell, specializations[0].SpecId);
        Check(std::any_of(entering.begin(), entering.end(),
                  [classTalent](KnownEntry const& item) { return item.EntryId == classTalent->EntryId; }),
              "a switch upload keeps the class tree");
        Check(SpecializationOf({ { classTalent->EntryId, 1 } }).SpecId == 0,
              "a class-tree upload names no specialization");
        Check(SpecializationOf({ { specializations[0].IdentityEntryId, 0 } }).SpecId == 0,
              "an entry at rank 0 names no specialization");
        Check(SpecializationOf({ { specializations[0].IdentityEntryId, 1 },
                  { specializations[1].IdentityEntryId, 1 } }).Mixed,
              "entries of two specializations are a mixed upload");

        CoATalentEntry const* chosen = nullptr;
        CoATalentEntry const* automatic = nullptr;
        for (CoATalentEntry const& entry : CoATalentEntries)
        {
            if (entry.SpecId != specializations[0].SpecId)
                continue;
            if (!chosen && (entry.AECost || entry.TECost) && entry.EntryId != specializations[0].SignatureEntryId)
                chosen = &entry;
            if (!automatic && !entry.AECost && !entry.TECost && entry.EntryId != specializations[0].IdentityEntryId)
                automatic = &entry;
        }
        Check(chosen && automatic, "the specialization has a paid talent and an automatic entry");
        if (chosen && automatic)
        {
            UploadedSpecialization const picked = SpecializationOf({ { chosen->EntryId, 1 } });
            Check(picked.SpecId == specializations[0].SpecId && picked.ChoosesTalents,
                  "a paid specialization talent names its specialization and chooses a talent");
            Check(SpecializationOf({ { automatic->EntryId, 1 } }).SpecId == 0,
                  "an automatic entry other than the identity names no specialization");
            Check(!SpecializationOf({ { automatic->EntryId, 1 }, { specializations[1].IdentityEntryId, 1 } }).Mixed,
                  "an automatic entry of another specialization does not mix the upload");
        }
    }

    CoATalentEntry const* sanguineIdentity = Find(4025);
    CoATalentEntry const* sanguineSignature = Find(29543);
    CoATalentEntry const* eternalSignature = Find(31117);
    Check(sanguineIdentity && sanguineSignature && eternalSignature,
          "Bloodmage archetypes have their native identity and shared signature entries");
    if (sanguineIdentity && sanguineSignature && eternalSignature)
    {
        std::set<std::uint32_t> spellbook = { sanguineIdentity->SpellIds[0], sanguineSignature->SpellIds[0] };
        std::vector<KnownEntry> const entering = SpecializationSwitch(20,
            [&spellbook](std::uint32_t id) { return spellbook.contains(id); }, 99);
        Check(std::none_of(entering.begin(), entering.end(),
                  [](KnownEntry const& item) { return item.EntryId == 29543; }),
              "leaving Sanguine removes its shared signature from the native upload");
        Check(std::any_of(entering.begin(), entering.end(),
                  [](KnownEntry const& item) { return item.EntryId == 31117 && item.Rank == 1; }),
              "entering Eternal uploads Blood Pact at rank one");
        Check(Spent(entering).AE == 1 && Spent(entering).TE == 0,
              "a native Bloodmage archetype switch fits the level-eleven point budget");
    }

    SpecializationSlot saved;
    saved.ClassId = 20;
    saved.SpecId = 99;
    for (std::uint32_t id = 1; id <= 80; ++id)
        saved.Entries.push_back({ id, id % 3 + 1 });
    saved.Actions = { { 11, 804197 }, { 143, 0x40000001 } };
    auto record = SpecializationSlotRecord(saved);
    SpecializationSlot restored;
    Check(ParseSpecializationSlot(record, restored) && restored.Entries.size() == 80 &&
              restored.Entries.back().EntryId == 80 && restored.Actions == saved.Actions,
          "slot records preserve more than 32 rows and complete packed action buttons");
    record.push_back(0);
    Check(ParseSpecializationSlot(record, restored), "slot records accept cleared storage tails");
    record.back() = 1;
    Check(!ParseSpecializationSlot(record, restored), "slot records reject unknown trailing data");
    record = SpecializationSlotRecord(saved);
    record[3] = 0xFFFFFFFF;
    Check(!ParseSpecializationSlot(record, restored), "slot records reject overflowing row counts");
    record = SpecializationSlotRecord(saved);
    record.pop_back();
    Check(!ParseSpecializationSlot(record, restored), "slot records reject truncated action bars");
    record = SpecializationSlotRecord(saved);
    record[0] = 2;
    Check(!ParseSpecializationSlot(record, restored), "slot records reject unknown revisions");
    saved.Actions = { { 11, 804197 }, { 11, 801955 } };
    Check(!ParseSpecializationSlot(SpecializationSlotRecord(saved), restored),
          "slot records reject duplicated action buttons");

    ResetCredits const fresh{};
    UnlearnPrice const unlearn13 = UnlearnPriceAt(13, fresh);
    Check(unlearn13.Money == 104 && unlearn13.Marks == 52, "a level 13 unlearn costs 1g 4c or 52 marks");
    UnlearnPrice const repeated = UnlearnPriceAt(13, { 0, 1, 1, 0 });
    Check(repeated.Money == 131 && repeated.Marks == 52,
          "talent resets and ability unlearns raise the unlearn gold the way the client prices it");
    Check(UnlearnPriceAt(60, { 0, 0, 0, 5 }).Money == 33315, "talent unlearns alone leave the unlearn price unchanged");
    Check(UnlearnPriceAt(10, fresh).Money == 0 && UnlearnPriceAt(10, fresh).Marks == 0,
          "unlearning is free at level 10");
    Check(UnlearnPriceAt(13, fresh, true).Money == 0, "a free-unlearn entry costs nothing");

    PurgePrice const purge13 = TalentPurgePriceAt(13, fresh);
    Check(purge13.Money == 261 && purge13.Marks == 1625 && purge13.Item == TALENT_PURGE_ITEM && purge13.ItemCount == 1,
          "a level 13 talent purge costs one purge item, 1625 marks or 2s 61c");
    Check(TalentPurgePriceAt(13, { 0, 2, 0, 0 }).Money == 2970, "each talent reset raises the purge gold");
    Check(TalentPurgePriceAt(80, fresh).Money == 171508 && TalentPurgePriceAt(80, fresh).Marks == 10000,
          "a level 80 talent purge matches the client price");
    Check(TalentPurgePriceAt(10, fresh).ItemCount == 0 && TalentPurgePriceAt(10, fresh).Money == 0,
          "a talent purge is free at level 10");

    RemovalPayment const split = PayForRemovals({ unlearn13, unlearn13 }, 60, 1000);
    Check(split.Affordable && split.Marks == 52 && split.Money == 104,
          "removals take marks while a whole price is covered, then gold");
    Check(!PayForRemovals({ unlearn13, unlearn13 }, 0, 200).Affordable, "removals the gold cannot cover are refused");
    bool anchorsFree = !CoASpecializations.empty();
    for (CoASpecialization const& specialization : CoASpecializations)
    {
        CoATalentEntry const* identity = Find(specialization.IdentityEntryId);
        CoATalentEntry const* signature = Find(specialization.SignatureEntryId);
        anchorsFree = anchorsFree && identity && IsUnpricedRemoval(*identity) &&
            (!specialization.SignatureEntryId || (signature && IsUnpricedRemoval(*signature)));
    }
    Check(anchorsFree, "every specialization identity and signature entry is removed without a charge");
    CoATalentEntry const* levelPassive = Find(4436);
    Check(levelPassive && !levelPassive->AECost && !levelPassive->TECost && IsUnpricedRemoval(*levelPassive),
          "a cost-free automatic entry is removed without a charge");
    Check(three && !IsUnpricedRemoval(*three), "an ordinary class talent is charged when removed");
    if (three)
    {
        std::vector<std::uint32_t> const aboveOne = SpellsAboveRank(*three, 1);
        Check(aboveOne.size() == 2 && aboveOne[0] == three->SpellIds[1] && aboveOne[1] == three->SpellIds[2],
              "the ranks above a set rank are the ones a lower learn must not keep");
        Check(SpellsAboveRank(*three, 3).empty() && SpellsAboveRank(*three, 0).size() == 3,
              "a full rank keeps every rank spell and rank 0 keeps none");
    }
    CoATalentEntry const* specTalent = FirstPaid(three ? three->ClassId : 0, false);
    Check(specTalent && !IsUnpricedRemoval(*specTalent), "an ordinary specialization talent is charged when removed");
    RemovalPayment const nothing = PayForRemovals({ UnlearnPriceAt(10, fresh) }, 0, 0);
    Check(nothing.Affordable && !nothing.Marks && !nothing.Money, "free removals need no payment");

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
    with tempfile.TemporaryDirectory(prefix="coa-talent-state-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores",
                    ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionCoATalentData.cpp",
                   ROOT / "src/server/coa/AscensionCoATalentState.cpp",
                   ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("state.exe" if os.name == "nt" else "state")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Talent state harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
