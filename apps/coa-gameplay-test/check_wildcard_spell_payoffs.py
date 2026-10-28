CLI_DESCRIPTION = 'Check independent Elemental Blast, Bloodbath, Cremation and Solar Burn native outcomes.'

import json
import math
from pathlib import Path
import sys


def check(directory):
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if result['status'] != 'passed':
        raise ValueError('Native scenario must pass before checking spell payoffs')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    if 'elemental_eligible_hits' in values:
        hits = int(values['elemental_eligible_hits'])
        crit = int(values['elemental_crit_casts'])
        haste = int(values['elemental_haste_casts'])
        if hits != 32 or crit + haste != hits or not (0 < crit < hits and 0 < haste < hits):
            raise ValueError(f'Elemental Blast: {hits} eligible hits, {crit} crit buffs, {haste} haste buffs')
        print(f'Elemental Blast: exactly one buff on each of {hits} hits ({crit} crit, {haste} haste)')
    elif 'bloodbath_base' in values:
        expected_tick = int(int(values['bloodbath_base'] + values['bloodbath_ap'] * .026) / 5)
        if values['bloodbath_tick'] != expected_tick or values['bloodbath_total'] != expected_tick * 5:
            raise ValueError(f'Bloodbath: expected five ticks of {expected_tick}, observed {values}')
        print(f'Bloodbath: five ticks of {expected_tick}, total {expected_tick * 5}')
    elif 'solar_base' in values:
        expected_tick = int(values['solar_base'] + values['solar_ap'] * .02 + values['solar_sp'] * .02)
        if values['solar_tick'] != expected_tick or values['solar_total'] != expected_tick * 3:
            raise ValueError(f'Solar Burn: expected three ticks of {expected_tick}, observed {values}')
        print(f'Solar Burn: three ticks of {expected_tick}, total {expected_tick * 3}')
    elif 'cremation_tick' in values:
        remaining = sum(values[f'cremation_{spell}_amount'] * math.ceil(
            values[f'cremation_{spell}_duration'] / values[f'cremation_{spell}_interval'])
                        for spell in (133, 11366, 44457, 289443))
        minimum = int((remaining * 7 + 60 * 35) / 5)
        maximum = int((remaining * 7 + 60 * 37) / 5)
        tick = values['cremation_tick']
        if not minimum <= tick <= maximum or values['cremation_total'] != tick * 5:
            raise ValueError(f'Cremation: remaining {remaining}, expected tick {minimum}-{maximum}, observed {values}')
        print(f'Cremation: {remaining} remaining DOT damage, five ticks of {tick}')
    else:
        raise ValueError('Spell payoff observations are missing')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(CLI_DESCRIPTION)
    check(Path(sys.argv[1]))
