import argparse
import json
from pathlib import Path


def check(directory):
    summary = json.loads((directory / 'summary.json').read_text(encoding='utf-8'))
    result = json.loads((directory / 'result.json').read_text(encoding='utf-8'))
    if summary['status'] != 'passed' or result['status'] != 'passed':
        raise ValueError('A completed native scenario pass is required')
    values = {step['label']: float(step['actual']) for step in result['steps'] if 'actual' in step}
    for phase in ['full', 'boosted']:
        healing = values[phase + '_healing']
        damage = values[phase + '_damage']
        if healing <= 0 or damage != healing:
            raise ValueError(f'{phase}: Oblivion damage {damage} must equal full Epoch healing {healing}')
    print('PASS: Oblivion copies 100% of Epoch healing, including overhealing, without added caster scaling')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Check Oblivion damage against the full Epoch heal')
    parser.add_argument('result_directory', type=Path)
    check(parser.parse_args().result_directory)
