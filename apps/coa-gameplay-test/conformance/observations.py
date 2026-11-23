from dataclasses import dataclass
import re

CITATION = re.compile(r'^player report (\d{4}-\d{2}-\d{2})$')
REQUIRED_FIELDS = ('spell', 'name', 'date', 'citation', 'claim', 'corroborates')


@dataclass(frozen=True)
class PlayerObservation:
    spell: int
    name: str
    date: str
    citation: str
    claim: str
    corroborates: str


def checked_observation(entry: dict) -> dict:
    missing = [field for field in REQUIRED_FIELDS if field not in entry]
    if missing:
        raise ValueError(f'Player observation {entry} is missing {missing}')
    matched = CITATION.fullmatch(entry['citation'])
    if not matched:
        raise ValueError(f'Player observation citation {entry["citation"]!r} is not "player report YYYY-MM-DD"')
    if matched.group(1) != entry['date']:
        raise ValueError(f'Player observation {entry["spell"]} date {entry["date"]!r} does not match its citation '
                         f'{entry["citation"]!r}')
    return entry


def player_observations(class_file: dict) -> list[PlayerObservation]:
    return [PlayerObservation(**checked_observation(entry)) for entry in class_file.get('player_observations', [])]


def observations_by_spell(observations: list[PlayerObservation]) -> dict[int, list[PlayerObservation]]:
    by_spell: dict[int, list[PlayerObservation]] = {}
    for observation in observations:
        by_spell.setdefault(observation.spell, []).append(observation)
    return by_spell
