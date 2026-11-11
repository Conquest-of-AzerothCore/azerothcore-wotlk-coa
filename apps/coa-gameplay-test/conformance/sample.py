from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
from typing import Iterable, Mapping, Sequence


class SampleError(ValueError):
    pass


def spell_key(seed: str, spell: int) -> str:
    return hashlib.sha256(f'{seed}|{spell}'.encode('utf-8')).hexdigest()


def spell_order(seed: str, spells: Iterable[int]) -> list[int]:
    return sorted(set(spells), key=lambda spell: (spell_key(seed, spell), spell))


def largest_remainder(sizes: Mapping[str, int], total: int) -> dict[str, int]:
    whole = sum(sizes.values())
    if whole == 0 or total <= 0:
        return {bucket: 0 for bucket in sizes}
    shares = {bucket: total * size / whole for bucket, size in sizes.items()}
    quotas = {bucket: int(share) for bucket, share in shares.items()}
    order = sorted(sizes, key=lambda bucket: (-(shares[bucket] - quotas[bucket]), list(sizes).index(bucket)))
    for bucket in order[:total - sum(quotas.values())]:
        quotas[bucket] += 1
    return quotas


def bucket_quotas(sizes: Mapping[str, int], total: int, minimums: Mapping[str, int]) -> dict[str, int]:
    unknown = sorted(set(minimums) - set(sizes))
    if unknown:
        raise SampleError(f'minimums name buckets {unknown} that hold no clause')
    fixed = {}
    while True:
        rest = {bucket: size for bucket, size in sizes.items() if bucket not in fixed}
        quotas = largest_remainder(rest, total - sum(fixed.values()))
        raised = {bucket: min(minimums[bucket], sizes[bucket]) for bucket, quota in quotas.items()
                  if bucket in minimums and quota < min(minimums[bucket], sizes[bucket])}
        if not raised:
            return {bucket: min(size, {**quotas, **fixed}[bucket]) for bucket, size in sizes.items()}
        fixed.update(raised)


@dataclass(frozen=True)
class Draw:
    bucket: str
    spell: int
    key: str
    clauses: tuple[dict, ...]


def draw(clauses: Sequence[dict], seed: str, total: int, buckets: Sequence[str],
         minimums: Mapping[str, int]) -> tuple[list[Draw], dict[str, int], dict[str, int]]:
    by_bucket = {bucket: [clause for clause in clauses if clause['bucket'] == bucket] for bucket in buckets}
    sizes = {bucket: len(found) for bucket, found in by_bucket.items()}
    quotas = bucket_quotas(sizes, total, minimums)
    drawn = []
    for bucket in buckets:
        taken = 0
        for spell in spell_order(seed, (clause['spell'] for clause in by_bucket[bucket])):
            if taken >= quotas[bucket]:
                break
            own = tuple(clause for clause in by_bucket[bucket] if clause['spell'] == spell)
            drawn.append(Draw(bucket, spell, spell_key(seed, spell), own))
            taken += len(own)
    return drawn, sizes, quotas


def chunk_split(drawn: Sequence[Draw], buckets: Sequence[str], first_size: int) -> tuple[list[int], list[int]]:
    queues = {bucket: [item.spell for item in drawn if item.bucket == bucket] for bucket in buckets}
    clauses_of = {}
    for item in drawn:
        clauses_of[item.spell] = clauses_of.get(item.spell, 0) + len(item.clauses)
    first, held = [], 0
    while held < first_size and any(queues.values()):
        for bucket in buckets:
            while queues[bucket] and queues[bucket][0] in first:
                queues[bucket].pop(0)
            if not queues[bucket] or held >= first_size:
                continue
            spell = queues[bucket].pop(0)
            first.append(spell)
            held += clauses_of[spell]
    second = []
    for item in drawn:
        if item.spell not in first and item.spell not in second:
            second.append(item.spell)
    return first, second


def sample_document(clauses: Sequence[dict], seed: str, total: int, buckets: Sequence[str],
                    minimums: Mapping[str, int], first_size: int) -> dict:
    drawn, sizes, quotas = draw(clauses, seed, total, buckets, minimums)
    first, second = chunk_split(drawn, buckets, first_size)
    chunk_of = {**{spell: 1 for spell in first}, **{spell: 2 for spell in second}}
    rows = [{'order': order, 'bucket': item.bucket, 'spell': item.spell, 'sha256': item.key,
             'chunk': chunk_of[item.spell], 'clauses': list(item.clauses)} for order, item in enumerate(drawn, 1)]
    held = {bucket: sum(len(row['clauses']) for row in rows if row['bucket'] == bucket) for bucket in buckets}
    return {'seed': seed, 'key': f'sha256 of "{seed}|<spell id>", ascending, inside each bucket',
            'total': total, 'buckets': list(buckets), 'minimums': dict(minimums), 'bucket_sizes': sizes,
            'quotas': quotas, 'drawn_clauses': held, 'first_chunk_size': first_size,
            'chunks': {'1': {'spells': first, 'clauses': sum(len(row['clauses']) for row in rows if row['chunk'] == 1)},
                       '2': {'spells': second, 'clauses': sum(len(row['clauses']) for row in rows
                                                              if row['chunk'] == 2)}},
            'draws': rows}


def load_buckets(path: Path) -> list[dict]:
    document = json.loads(Path(path).read_text(encoding='utf-8'))
    clauses = document['clauses'] if isinstance(document, dict) else document
    for index, clause in enumerate(clauses):
        if not isinstance(clause, dict) or not isinstance(clause.get('spell'), int) \
                or not isinstance(clause.get('bucket'), str):
            raise SampleError(f'{path}[{index}] is not a clause with an integer spell and a bucket')
    return clauses


def parse_minimums(values: Sequence[str]) -> dict[str, int]:
    minimums = {}
    for value in values:
        bucket, _, count = value.partition('=')
        if not bucket or not count.isdigit():
            raise SampleError(f'minimum {value!r} is not BUCKET=COUNT')
        minimums[bucket] = int(count)
    return minimums
