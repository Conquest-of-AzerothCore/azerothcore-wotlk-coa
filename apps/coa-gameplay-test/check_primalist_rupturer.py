#!/usr/bin/env python3
CLI_DESCRIPTION = """Check Rupturer's per-hit resource additions and rank-aware, talent-gated cooldown reduction."""

import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: int(float(step['actual'])) for step in result['steps'] if 'actual' in step}
    for spell in (582532, 503264):
        for critical in (0, 1):
            suffix = f'{spell}_{critical}'
            hits = values[f'baseline_{suffix}_hits']
            for phase in ('talented', 'removed'):
                if values[f'{phase}_{suffix}_hits'] != hits:
                    raise ValueError(f'{phase}_{suffix}: unequal damage event counts')
                critical_hits = values[f'{phase}_{suffix}_crits']
                if not 0 <= critical_hits <= hits or critical and critical_hits != hits:
                    raise ValueError(f'{phase}_{suffix}: invalid critical event count {critical_hits}')
                for buff, additions in ((560170, hits + critical_hits), (680441, critical_hits)):
                    base = values[f'baseline_{suffix}_{buff}']
                    expected = min(values[f'cap_{buff}'], base + additions) if phase == 'talented' else base
                    actual = values[f'{phase}_{suffix}_{buff}']
                    if actual != expected:
                        raise ValueError(f'{phase}_{suffix}_{buff}: {actual}, expected {expected}')
            print(f'{spell}, critical={critical}: {hits} events, resource additions and removal verified')
    for phase, expected in (('talented', -4000), ('removed', 0)):
        elapsed = values[f'{phase}_cd_delta_500696']
        for spell in (681119, 574162):
            reduction = values[f'{phase}_cd_delta_{spell}'] - elapsed
            if abs(reduction - expected) > 150:
                raise ValueError(f'{phase}, {spell}: adjusted cooldown delta {reduction}, expected {expected}')
            print(f'{phase}, {spell}: cooldown delta excluding elapsed time {reduction} ms')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
