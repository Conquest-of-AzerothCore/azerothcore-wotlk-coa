import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    item = (ROOT / "src/server/game/Entities/Item/ItemTemplate.h").read_text()
    shared = (ROOT / "src/server/shared/SharedDefines.h").read_text()
    dbc = (ROOT / "src/server/shared/DataStores/DBCStructure.h").read_text()
    enums = "\n".join(method(item, name) + ";" for name in (
        "enum ItemModType", "enum ItemBondingType", "enum ItemFlags :", "enum InventoryType", "enum ItemClass"))
    enums += "\n" + method(shared, "enum ItemQualities") + ";\n"
    enums += method(item, "struct _ItemStat") + ";\n"
    enums += method(dbc, "struct CreatureDisplayInfoExtraEntry") + ";\n"
    prefix = "#include <cstdint>\nusing uint32 = uint32_t;using int32 = int32_t;\n"
    source = (ROOT / "src/server/coa/AscensionEquippedGearLoot.cpp").read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    aliases = (ROOT / "src/server/coa/AscensionItemAppearanceAliases.cpp").read_text()
    aliases = re.sub(r'^#include.*\n', '', aliases, flags=re.M)
    loot_path = "src/server/game/Loot/LootMgr.cpp"
    if os.environ.get("COA_EQUIPPED_LOOT_BEFORE"):
        baseline = os.environ.get("COA_EQUIPPED_LOOT_BASE", "origin/main")
        loot = subprocess.check_output(["git", "show", baseline + ":" + loot_path], cwd=ROOT).decode()
    else:
        loot = (ROOT / loot_path).read_text()
    code = prefix + enums + (HERE / "harness.cpp").read_text() + source + aliases
    code += method(loot, "void Loot::AddItem(") + "\n"
    code += method(loot, "bool Loot::FillLoot(") + "\n"
    code += (HERE / "cases.cpp").read_text()
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "A C++20 compiler is required"
    with tempfile.TemporaryDirectory(prefix="coa-equipped-gear-loot-") as directory:
        out = Path(directory)
        cpp, exe = out / "loot.cpp", out / "loot.exe"
        cpp.write_text(code)
        command = ([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", str(cpp), "/Fe" + str(exe)]
                   if Path(compiler).name.lower() == "cl.exe" else
                   [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)])
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print("PASS: appearance/slot/role matching, level and wearable limits, presets, DBC outfits, weapons, "
          "configuration, corpse-only drops, capacity, duplicates and native group loot setup")


if __name__ == "__main__":
    main()
