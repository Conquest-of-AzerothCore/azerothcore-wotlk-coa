import importlib.util
from pathlib import Path
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def main():
    path = ROOT.parent / 'tools/Test-StarcallerCompletion.py'
    spec = importlib.util.spec_from_file_location('starfire_fixture', path)
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    source = fixture.src('Contracts')
    production = fixture.t.necro.enum(fixture.M / 'AscensionStarcallerContracts.cpp', 'StarfireSpells')
    production += fixture.wrap('Scaling', 'Contracts', ['ModifySpellEffectBaseValue'])
    cases = r'''
int main()
{
    Player player;
    Scaling scaling;
    SpellInfo info;
    for (uint32 id : {801978u, 804463u, 804464u, 804465u, 804466u, 804467u, 804468u, 804469u})
    {
        manager.roots[id] = 801978;
        info.Id = id;
        for (int32 flat : {62, 124, 160})
            for (uint32 mana : {0u, 1000u, 5000u, 10000u})
            {
                manager.rows[801977].Effects[0].BasePoints = flat - 1;
                player.maxMana = mana;
                float value = 10;
                scaling.ModifySpellEffectBaseValue(&player, &info, 0, value);
                assert(close(value, flat + 0.09f * mana));
                value = 150;
                scaling.ModifySpellEffectBaseValue(&player, &info, 1, value);
                assert(value == 150); // Weapon percentage is independent of the flat helper.
            }
    }
    info.Id = 801977;
    float value = 62;
    scaling.ModifySpellEffectBaseValue(&player, &info, 0, value);
    assert(value == 62); // Reading the helper cannot recurse back into itself.
    info.Id = 804464; player.cls = 22; value = 10;
    scaling.ModifySpellEffectBaseValue(&player, &info, 0, value); assert(value == 10);
}
'''
    with tempfile.TemporaryDirectory(prefix='coa-starfire-secondary-') as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().cpp('referenced-flat-damage', production, cases)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {801977,801978,804463,804464,804465,804466,804467,804468,804469}
    rows = {r[0]:r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[801977][71] == 2 and rows[801977][80] + rows[801977][74] == 62
    for sid in ids - {801977}:
        assert rows[sid][71:73] == (121,31) and rows[sid][208:212] == (32,2048,0,0)
    print('PASS: 96 Starfire rank/helper/mana cases, weapon percentage, class scope and nonrecursive helper')


if __name__ == '__main__':
    main()
