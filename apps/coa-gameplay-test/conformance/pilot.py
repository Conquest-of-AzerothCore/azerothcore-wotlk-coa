from pathlib import Path
from typing import Callable, Mapping, Sequence

from behaviours import BEHAVIOUR_HIT_RATIO, HIT_RATIO_PILOT_TRIALS, hit_ratio_entry_label
from compare import Verdict
from prove import Pilot

MakeSized = Callable[[Path, Mapping[str, int]], Path]


def sizable_labels(entries: Sequence[dict]) -> list[str]:
    return [hit_ratio_entry_label(entry) for entry in entries if entry.get('kind') == 'hit_ratio']


def pilot_record(label: str, verdict: Verdict | None, pilot_trials: int) -> tuple[int | None, dict]:
    if verdict is None:
        return None, {'label': label, 'pilot_status': None, 'trials': None,
                      'reason': 'the pilot run holds no verdict for this label; generated sizing kept'}
    detail = verdict.detail or {}
    sized, limit = detail.get('sized_trials'), detail.get('trial_limit')
    if sized is None:
        return None, {'label': label, 'pilot_status': verdict.status, 'trials': None,
                      'reason': f'the pilot reads no interval ({verdict.explanation}); generated sizing kept'}
    trials = max(pilot_trials, int(sized))
    capped = limit is not None and trials > int(limit)
    trials = int(limit) if capped else trials
    return trials, {'label': label, 'pilot_status': verdict.status, 'sized': int(sized), 'trial_limit': limit,
                    'capped': capped, 'trials': trials}


def hit_ratio_pilot(labels: Sequence[str], pilot_make: MakeSized, sized_make: MakeSized,
                    pilot_trials: int = HIT_RATIO_PILOT_TRIALS) -> Pilot | None:
    if not labels:
        return None

    def generate(out: Path) -> Path:
        return pilot_make(Path(out), {label: pilot_trials for label in labels})

    def size(verdicts: Sequence[Verdict]) -> tuple[dict[str, int], list[dict]]:
        by_label = {verdict.label: verdict for verdict in verdicts if verdict.check == BEHAVIOUR_HIT_RATIO}
        trials, records = {}, []
        for label in labels:
            sized, record = pilot_record(label, by_label.get(label), pilot_trials)
            records.append(record)
            if sized is not None:
                trials[label] = sized
        return trials, records

    def sized(out: Path, trials: Mapping[str, int]) -> Path:
        return sized_make(Path(out), dict(trials))

    return Pilot(generate, size, sized)
