ASCENSION_PROC_PERCENT_EVENT = 354
AURA_MARK = f': aura {ASCENSION_PROC_PERCENT_EVENT}'
NO_CLASS_CODE = frozenset({'stock', 'data_row'})
SHOWN_CODE_HITS = 3


class Aura354Error(ValueError):
    pass


def class_entry(class_map: dict, class_id: int) -> dict:
    entry = class_map.get('classes', {}).get(str(class_id))
    if entry is None:
        raise Aura354Error(f'class {class_id} is not in the class map (classes: {sorted(class_map.get("classes", {}))})')
    return entry


def aura354_rows(class_map: dict, class_id: int) -> list[dict]:
    rows = []
    for spell in class_entry(class_map, class_id)['spells']:
        carriers = sorted({mechanic.split(':', 1)[0] for mechanic in spell['custom_mechanics']
                           if mechanic.endswith(AURA_MARK)})
        if not carriers:
            continue
        rows.append({'spell': spell['spell'], 'name': spell['name'], 'risk': spell['risk'],
                     'carriers': [int(carrier) for carrier in carriers],
                     'custom_mechanics': spell['custom_mechanics'], 'code_hits': spell['code_hits'],
                     'candidate_defect': spell['risk'] in NO_CLASS_CODE})
    return rows


def aura354_lines(rows: list[dict], class_id: int) -> list[str]:
    lines = [f"{row['spell']}\t{row['name']}\t{row['risk']}\t"
             f"{'CANDIDATE DEFECT: no class code' if row['candidate_defect'] else 'check the 354 handling'}\t"
             f"{', '.join(row['custom_mechanics'])}\t{', '.join(row['code_hits'][:SHOWN_CODE_HITS])}" for row in rows]
    candidates = sum(row['candidate_defect'] for row in rows)
    return lines + [f'class {class_id}: {len(rows)} spells with aura {ASCENSION_PROC_PERCENT_EVENT}, {candidates} '
                    f'candidate defects (risk stock or data_row)']
