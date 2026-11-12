from dataclasses import dataclass
import re

from tooltip import SPELL_POWER_SCHOOLS, CasterStats

CITATION = re.compile(r'^player report (\d{4}-\d{2}-\d{2})$')
REQUIRED_FIELDS = ('spell', 'token', 'value', 'ap', 'sp', 'citation')
READING_LEVEL = 60


@dataclass(frozen=True)
class TooltipReading:
    spell: int
    token: str
    value: float
    ap: float
    sp: tuple[float, ...]
    citation: str
    note: str = ''


def checked_tooltip_reading(entry: dict) -> dict:
    missing = [field for field in REQUIRED_FIELDS if field not in entry]
    if missing:
        raise ValueError(f'Player tooltip reading {entry} is missing {missing}')
    matched = CITATION.fullmatch(entry['citation'])
    if not matched:
        raise ValueError(f'Player tooltip reading citation {entry["citation"]!r} is not "player report YYYY-MM-DD"')
    return entry


def player_tooltip_readings(class_file: dict) -> list[TooltipReading]:
    readings = []
    for entry in class_file.get('player_tooltip_readings', []):
        checked = checked_tooltip_reading(entry)
        readings.append(TooltipReading(**{**checked, 'sp': tuple(checked['sp'])}))
    return readings


def reading_for(readings: list[TooltipReading], spell: int, token: str) -> TooltipReading | None:
    return next((reading for reading in readings if reading.spell == spell and reading.token == token), None)


def reading_caster(reading: TooltipReading, sp: float) -> CasterStats:
    sp_by_school = dict.fromkeys(SPELL_POWER_SCHOOLS.values(), sp)
    return CasterStats(READING_LEVEL, reading.ap, reading.ap, sp_by_school, {})


def reading_band(tooltips, reading: TooltipReading) -> tuple[float, float]:
    sp_values = reading.sp or (0.0,)
    values = []
    for sp in sp_values:
        readout = tooltips.read(reading.spell, reading_caster(reading, sp))
        found = next((value for value in readout.values if value.text == reading.token), None)
        if found is None:
            raise ValueError(f'{reading.token!r} not found reading spell {reading.spell} at ap={reading.ap} sp={sp}')
        values.append(found.value)
    return min(values), max(values)
