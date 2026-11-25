import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
BASELINE = ROOT / 'apps/coa-tests/tbc_gem_rescale/baseline.json'


def scoped_items(data):
    return [row for row in data['gem_items'] if int(row['entry']) != 33060]


def migration(data):
    identifiers = ', '.join(str(row['entry']) for row in scoped_items(data))
    return ('UPDATE `item_template`\nSET `RequiredLevel` = 60\n'
            f'WHERE `entry` IN ({identifiers}) AND `RequiredLevel` > 60;\n')


def header(data):
    props = {int(row['ID']): row for row in data['gem_properties']}
    rows = ',\n'.join('    { ' + ', '.join(str(value) for value in
        (item['entry'], item['GemProperties'], props[int(item['GemProperties'])]['Enchant_Id'])) + ' }'
        for item in sorted(scoped_items(data), key=lambda row: int(row['entry'])))
    return ('/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */\n'
            '#ifndef COA_TBC_GEM_REQUIREMENTS_DATA_H\n#define COA_TBC_GEM_REQUIREMENTS_DATA_H\n\n'
            '#include <array>\n#include <cstdint>\n\nnamespace TbcGemRequirements\n{\n'
            'struct Mapping\n{\n    std::uint32_t gem;\n    std::uint32_t property;\n    std::uint32_t enchantment;\n};\n\n'
            f'inline constexpr std::array<Mapping, {len(scoped_items(data))}> Mappings = {{{{\n{rows}\n}}}};\n'
            '}\n\n#endif\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(BASELINE.read_text())
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'migration.sql').write_text(migration(data))
    (args.output / 'CoATbcGemRequirementsData.h').write_text(header(data))
    print(f'Prepared requirements-only update for {len(scoped_items(data))} TBC gems; no client patch.')


if __name__ == '__main__':
    main()
