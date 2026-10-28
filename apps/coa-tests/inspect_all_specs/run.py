CLI_DESCRIPTION = """Check the Character Advancement inspect body and saved-slot rebuild without a server.

Compiles the CoA talent catalog loader and talent state code against the client DBC set the server loads
(--dbc-dir), then checks that the inspect body declares exactly the lists it carries, and that a saved
specialization slot rebuilds to the entries the target would hold on switching back to it.
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

std::uint32_t Read(std::vector<std::uint8_t> const& data, std::size_t offset)
{
    return std::uint32_t(data[offset]) | (std::uint32_t(data[offset + 1]) << 8) |
        (std::uint32_t(data[offset + 2]) << 16) | (std::uint32_t(data[offset + 3]) << 24);
}

bool Walk(std::vector<std::uint8_t> const& body, std::vector<std::uint32_t>& counts)
{
    if (body.size() < 4)
        return false;
    std::uint32_t const lists = Read(body, 0);
    std::size_t cursor = 4;
    for (std::uint32_t list = 0; list < lists; ++list)
    {
        if (body.size() - cursor < 4)
            return false;
        std::uint32_t const entries = Read(body, cursor);
        cursor += 4;
        if ((body.size() - cursor) / 21 < entries)
            return false;
        cursor += std::size_t(entries) * 21;
        counts.push_back(entries);
    }
    return cursor == body.size();
}

CoATalentEntry const* Find(std::uint32_t entryId)
{
    for (CoATalentEntry const& entry : CoATalentEntries)
        if (entry.EntryId == entryId)
            return &entry;
    return nullptr;
}

bool Picked(CoATalentEntry const& entry)
{
    return entry.AECost || entry.TECost || std::any_of(CoASelectableFreeEntries.begin(),
        CoASelectableFreeEntries.end(),
        [&entry](CoASelectableFreeEntry const& free) { return free.EntryId == entry.EntryId; });
}

std::set<std::uint32_t> Ids(std::vector<KnownEntry> const& known)
{
    std::set<std::uint32_t> ids;
    for (KnownEntry const& item : known)
        ids.insert(item.EntryId * 10 + item.Rank);
    return ids;
}

bool Holds(std::vector<KnownEntry> const& known, std::uint32_t entryId)
{
    return std::any_of(known.begin(), known.end(),
        [entryId](KnownEntry const& item) { return item.EntryId == entryId; });
}
}

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    Check(LoadCoATalentData() && !CoASpecializations.empty(), "the CoA talent catalog loads from the client DBCs");
    if (failures)
        return 1;

    std::vector<std::vector<KnownEntry>> specs(20);
    specs[3] = { { 101, 1 }, { 102, 2 } };
    specs[7] = { { 103, 1 } };
    std::vector<std::uint32_t> counts;
    std::vector<std::uint8_t> const twenty = InspectSpecsPayload(specs);
    Check(Walk(twenty, counts) && counts.size() == 20,
          "a twenty-slot inspect body declares twenty lists and holds exactly those bytes");
    Check(counts.size() == 20 && counts[3] == 2 && counts[7] == 1 &&
              std::count(counts.begin(), counts.end(), 0u) == 18,
          "each list sits at its own slot index and an unused slot is an empty list");
    counts.clear();
    Check(Walk(InspectSpecsPayload({ { { 101, 1 } } }), counts) && counts == std::vector<std::uint32_t>{ 1 },
          "a single-build target declares one list");

    std::size_t rebuilt = 0, stable = 0, identities = 0, foreign = 0;
    for (CoASpecialization const& specialization : CoASpecializations)
    {
        SpecializationSlot slot;
        slot.ClassId = specialization.ClassId;
        slot.SpecId = specialization.SpecId;
        for (bool classTree : { true, false })
            for (CoATalentEntry const& entry : CoATalentEntries)
                if (entry.ClassId == specialization.ClassId && Picked(entry) && entry.SpellCount &&
                    (classTree ? entry.SpecId == 0 : entry.SpecId == specialization.SpecId))
                {
                    slot.Entries.push_back({ entry.EntryId, entry.SpellCount });
                    break;
                }

        std::vector<KnownEntry> const live = SlotKnownEntries(slot, 80, {});
        ++rebuilt;
        SpecializationSlot stored = slot;
        stored.Entries.clear();
        for (KnownEntry const& item : live)
            if (CoATalentEntry const* entry = Find(item.EntryId); entry && Picked(*entry))
                stored.Entries.push_back(item);
        stable += Ids(SlotKnownEntries(stored, 80, {})) == Ids(live);

        CoATalentEntry const* identity = Find(specialization.IdentityEntryId);
        identities += identity && identity->RequiredLevel <= 80 && Holds(live, identity->EntryId);
        for (KnownEntry const& item : live)
            if (CoATalentEntry const* entry = Find(item.EntryId);
                entry && entry->SpecId && entry->SpecId != specialization.SpecId)
                ++foreign;
    }
    Check(rebuilt == CoASpecializations.size() && stable == rebuilt,
          "every specialization's slot rebuilds from its own stored picks to the same entries");
    Check(identities == CoASpecializations.size(), "a rebuilt slot holds its specialization's identity entry");
    Check(foreign == 0, "a rebuilt slot holds no entry of another specialization");

    CoASpecialization const& first = CoASpecializations.front();
    SpecializationSlot fresh;
    fresh.ClassId = first.ClassId;
    fresh.SpecId = first.SpecId;
    Check(SlotKnownEntries(fresh, 1, {}).empty(), "at level 1 a slot without picks holds nothing");
    std::size_t levelGated = 0, levelHeld = 0;
    for (KnownEntry const& item : SlotKnownEntries(fresh, 80, {}))
        if (CoATalentEntry const* entry = Find(item.EntryId); entry && entry->RequiredLevel > 20)
            ++levelGated;
    for (KnownEntry const& item : SlotKnownEntries(fresh, 20, {}))
        if (CoATalentEntry const* entry = Find(item.EntryId); entry && entry->RequiredLevel > 20)
            ++levelHeld;
    Check(levelGated > 0 && levelHeld == 0, "automatic entries follow the target's current level");

    std::size_t dependents = 0, judged = 0, ordered = 0, ordering = 0;
    for (CoAAutomaticDependency const& dependency : CoAAutomaticDependencies)
    {
        CoATalentEntry const* dependent = Find(dependency.EntryId);
        CoATalentEntry const* required = Find(dependency.RequiredEntryIds[0]);
        if (!dependent || !required || dependency.RequiredEntryIds[1])
            continue;
        ++dependents;
        std::uint8_t const classId = std::uint8_t(dependent->ClassId);
        std::uint32_t const requiredSpell = required->SpellIds[required->SpellCount ? required->SpellCount - 1 : 0];
        judged += !CanGrantAutomatic(*dependent, classId, 80, dependent->SpecId, [](std::uint32_t) { return false; }) &&
            CanGrantAutomatic(*dependent, classId, 80, dependent->SpecId,
                [requiredSpell](std::uint32_t id) { return id == requiredSpell; });
        for (CoASpecialization const& specialization : CoASpecializations)
        {
            if (specialization.ClassId != dependent->ClassId)
                continue;
            SpecializationSlot slot;
            slot.ClassId = specialization.ClassId;
            slot.SpecId = specialization.SpecId;
            std::vector<KnownEntry> const known = SlotKnownEntries(slot, 80, {});
            ++ordering;
            ordered += !Holds(known, dependent->EntryId) || Holds(known, required->EntryId);
        }
    }
    Check(dependents > 0 && judged == dependents,
          "every automatic prerequisite is judged against the spells it is given, not the live spellbook");
    Check(ordering > 0 && ordered == ordering,
          "a rebuilt slot never holds an automatic entry without its prerequisite");
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
    with tempfile.TemporaryDirectory(prefix="coa-inspect-all-specs-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores",
                    ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionCoATalentData.cpp",
                   ROOT / "src/server/coa/AscensionCoATalentState.cpp",
                   ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("inspect.exe" if os.name == "nt" else "inspect")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Inspect harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
