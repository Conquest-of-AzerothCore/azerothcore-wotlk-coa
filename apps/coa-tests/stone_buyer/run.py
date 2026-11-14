from pathlib import Path
import shutil
import subprocess
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = ROOT / "src/server/coa/AscensionStoneBuyer.cpp"
LOADER = ROOT / "src/server/coa/CoAScriptLoader.cpp"
HOT_PATCH_DOC = ROOT / "docs/coa/client-hot-patch.md"
RAW_LUA = re.compile(r'constexpr char StoneBuyerLua\[\] = R"lua\((.*?)\)lua";', re.S)


def extract_lua():
    source = SOURCE.read_text(encoding="utf-8")
    match = RAW_LUA.search(source)
    assert match, "StoneBuyerLua raw string is missing"
    lua = match.group(1)
    assert "C_VanityCollection.PurchaseCollectionItem" in lua
    assert "WorldMapButton_OnClick" in lua
    assert 'SLASH_STONEBUYER1 = "/stonebuyer"' in lua
    assert 'SLASH_STONEBUYER2 = "/sbuy"' in lua
    assert '"zabrajin"' in lua
    assert '"zabragin"' not in lua
    assert "SendAddonMessage" not in lua
    assert "AFK" not in lua
    assert "TOKEN_COST" not in lua
    assert "local TOKEN_ITEM = 975001" in lua
    stone_ids = re.findall(r"\d+", lua[lua.find("local STONES = {"):lua.find("local ZONE_ALIASES")])
    assert len({int(v) for v in stone_ids if int(v)}) >= 100, "STONES should list the retreat stone items"
    return lua


def check_server_path(source):
    assert "RunAscensionClientLua(player," in source
    assert "BuildStoneBuyerLua()" in source
    assert "coa_client_vanity_collection" in source
    assert "BazaarTokenCost" in source
    assert "PLAYERHOOK_ON_LOGIN" in source
    assert "LoginLuaDelay = 5s" in source
    assert "IsBot()" in source
    assert "SendCriteriaUpdate" not in source
    assert "afk-realm" not in source.lower()
    assert re.search(r'constexpr char Token\[\] = "COA_STONE_BUYER";', source)


def check_registration():
    loader = LOADER.read_text(encoding="utf-8")
    assert "void AddSC_AscensionStoneBuyer();" in loader
    assert "    AddSC_AscensionStoneBuyer();" in loader
    doc = HOT_PATCH_DOC.read_text(encoding="utf-8")
    assert "Stone of Retreat" in doc


def find_lua():
    for name in ("lua5.1", "lua"):
        found = shutil.which(name)
        if found:
            return found
    for name in ("lua5.1", "lua"):
        candidate = Path.home() / ".local/bin" / name
        if candidate.is_file():
            return str(candidate)
    return None


def main():
    source = SOURCE.read_text(encoding="utf-8")
    lua = extract_lua()
    check_server_path(source)
    check_registration()

    lua_bin = find_lua()
    if not lua_bin:
        raise SystemExit("Lua 5.1 is required for the pushed client Lua regression.")

    out = HERE / ".chunk.lua"
    try:
        out.write_text(lua, encoding="utf-8")
        subprocess.run([lua_bin, str(HERE / "harness.lua"), str(out)], check=True, timeout=30)
    finally:
        if out.exists():
            out.unlink()

    print("PASS: StoneBuyer hot-patch Lua, login hook, vanity purchase path and map-click behaviour")


if __name__ == "__main__":
    main()
