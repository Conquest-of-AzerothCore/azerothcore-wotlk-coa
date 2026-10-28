import json
from pathlib import Path
import sys


def completed(folder):
    result = json.loads((folder / 'result.json').read_text())
    summary = json.loads((folder / 'summary.json').read_text())
    scenario = json.loads((folder / 'scenario.json').read_text())
    if result['status'] != 'passed' or summary['status'] != 'passed':
        raise ValueError('Both completed native case-boundary scenarios are required')
    counts = [int(record['actual']) for record in result['steps']
              if scenario['steps'][int(record['index'])].get('metric') == 'nearby_creature_count'
              and scenario['steps'][int(record['index'])].get('entry') == 10482]
    if len(counts) != 1:
        raise ValueError('Each native scenario must observe its actual Risen Lackey count')
    return result, counts[0]


def check(folders):
    if len(folders) != 2:
        raise ValueError('The ordered producer and consumer bundles are required')
    (producer, created), (consumer, remaining) = [completed(folder) for folder in folders]
    if producer['batch_id'] != consumer['batch_id'] or producer['phase_mask'] != consumer['phase_mask']:
        raise ValueError('The consumer must reuse the producer phase in the same native batch')
    if int(producer['sequence']) >= int(consumer['sequence']):
        raise ValueError('The native producer must complete before the consumer starts')
    if created < 1 or remaining != 0:
        raise ValueError(f'Native fixture descendants: created {created}, remaining {remaining}')
    print(f'Native fixture descendants: created {created}, remaining {remaining}; same private phase reused')


if __name__ == '__main__':
    check([Path(value) for value in sys.argv[1:]])
