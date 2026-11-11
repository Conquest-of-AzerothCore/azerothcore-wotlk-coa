from dataclasses import dataclass
import math
from typing import Sequence

from stack import MINIMUM_PASSES, TWO_SIDED_99, student_t_quantile

RELATIVE_BAND = 0.05
POINT_BAND = 2.0
POWER_SHARE_OF_BAND = 0.5
SIZING_SHARE_OF_POWER = 0.8
EPSILON = 1e-9
OK, ALERT, NOT_JUDGED = 'ok', 'alert', 'insufficient_trials'


def bonus_band(expected: float) -> float:
    return max(RELATIVE_BAND * abs(expected), POINT_BAND)


@dataclass(frozen=True)
class ArmSample:
    mean: float
    share: float
    trials: int
    events: float


def per_event_sample(totals: Sequence[float], counts: Sequence[float]) -> ArmSample:
    trials, events = len(totals), sum(counts)
    if events <= 0:
        raise ValueError('an arm without an event has no mean per event')
    mean = sum(totals) / events
    if trials < MINIMUM_PASSES:
        return ArmSample(mean, math.inf, trials, events)
    residuals = sum((total - mean * count) ** 2 for total, count in zip(totals, counts))
    return ArmSample(mean, residuals / (trials - 1) / (trials * (events / trials) ** 2), trials, events)


@dataclass(frozen=True)
class Bonus:
    measured: float
    half: float
    expected: float
    trials: int

    @property
    def band(self) -> float:
        return bonus_band(self.expected)

    @property
    def power_limit(self) -> float:
        return POWER_SHARE_OF_BAND * self.band

    @property
    def low(self) -> float:
        return self.measured - self.half

    @property
    def high(self) -> float:
        return self.measured + self.half

    @property
    def excluded(self) -> tuple[float, float]:
        return self.expected - self.band - self.half, self.expected + self.band + self.half


def bonus_of(treatment: ArmSample, control: ArmSample, expected: float) -> Bonus:
    if abs(control.mean) <= EPSILON:
        raise ValueError('the control arm reads 0 per event, so the arms have no ratio')
    ratio = treatment.mean / control.mean
    terms = [(treatment.share / control.mean ** 2, treatment.trials - 1),
             (ratio ** 2 * control.share / control.mean ** 2, control.trials - 1)]
    spread = sum(term for term, _ in terms)
    if math.isinf(spread):
        half = math.inf
    elif spread <= 0:
        half = 0.0
    else:
        dof = spread ** 2 / sum(term ** 2 / dof for term, dof in terms if term > 0)
        half = student_t_quantile(TWO_SIDED_99, dof) * math.sqrt(spread) * 100
    return Bonus((ratio - 1) * 100, half, expected, min(treatment.trials, control.trials))


def delta_of(treatment: ArmSample, control: ArmSample, expected: float) -> Bonus:
    terms = [(treatment.share, treatment.trials - 1), (control.share, control.trials - 1)]
    spread = sum(term for term, _ in terms)
    if math.isinf(spread):
        half = math.inf
    elif spread <= 0:
        half = 0.0
    else:
        dof = spread ** 2 / sum(term ** 2 / dof for term, dof in terms if term > 0)
        half = student_t_quantile(TWO_SIDED_99, dof) * math.sqrt(spread)
    return Bonus(treatment.mean - control.mean, half, expected, min(treatment.trials, control.trials))


def delta_text(bonus: Bonus) -> str:
    interval = ('no interval' if not math.isfinite(bonus.half)
                else f'99% interval {bonus.low:+.4g} to {bonus.high:+.4g}')
    low, high = bonus.excluded
    excluded = ('excludes no difference (one trial per arm gives no interval)' if not math.isfinite(bonus.half)
                else f'excludes a difference below {low:+.4g} or above {high:+.4g}')
    return (f'difference {bonus.measured:+.4g} per hit ({interval}, {bonus.trials} trials per arm) against the '
            f'stated {bonus.expected:+.4g}, which passes inside +-{bonus.band:.3g} (the larger of {RELATIVE_BAND:.0%} '
            f'of it and {POINT_BAND:g}); {excluded}')


def scaled_trials(trials: int, half: float, target: float) -> int | None:
    if not math.isfinite(half) or target <= EPSILON:
        return None
    return max(trials, math.ceil(trials * (half / target) ** 2))


def bonus_status(bonus: Bonus) -> tuple[str, str, int | None]:
    band_low, band_high = bonus.expected - bonus.band, bonus.expected + bonus.band
    if bonus.high < band_low - EPSILON or bonus.low > band_high + EPSILON:
        return ALERT, 'the 99% interval lies outside the band', None
    if bonus.half > bonus.power_limit + EPSILON:
        return (NOT_JUDGED, f'not judged: the 99% half-width {bonus.half:.3g} points is above {bonus.power_limit:.3g}, '
                            f'half the band', scaled_trials(bonus.trials, bonus.half, bonus.power_limit))
    if abs(bonus.expected) > EPSILON and bonus.low <= EPSILON and bonus.high >= -EPSILON:
        return (NOT_JUDGED, 'not judged: the interval holds 0, so the treatment arm is not told apart from the '
                            'control arm', scaled_trials(bonus.trials, bonus.half, abs(bonus.measured)))
    if band_low - EPSILON <= bonus.measured <= band_high + EPSILON:
        return OK, 'the reading lies inside the band', None
    return ALERT, 'the reading lies outside the band', None


def band_status(bonus: Bonus) -> str:
    return OK if abs(bonus.measured - bonus.expected) <= bonus.band + EPSILON else ALERT


def sized_trials(bonus: Bonus) -> int | None:
    return scaled_trials(bonus.trials, bonus.half, SIZING_SHARE_OF_POWER * bonus.power_limit)


def excluded_text(bonus: Bonus) -> str:
    if not math.isfinite(bonus.half):
        return 'excludes no bonus (one trial per arm gives no interval)'
    low, high = bonus.excluded
    return f'excludes a bonus below {low:+.4g}% or above {high:+.4g}%'


def bonus_text(bonus: Bonus) -> str:
    interval = ('no interval' if not math.isfinite(bonus.half)
                else f'99% interval {bonus.low:+.4g}% to {bonus.high:+.4g}%')
    return (f'bonus {bonus.measured:+.4g}% ({interval}, {bonus.trials} trials per arm) against the stated '
            f'{bonus.expected:+.4g}%, which passes inside +-{bonus.band:.3g} points (the larger of '
            f'{RELATIVE_BAND:.0%} of it and {POINT_BAND:g} points); {excluded_text(bonus)}')


def bonus_detail(bonus: Bonus) -> dict:
    low, high = bonus.excluded
    return {'measured': bonus.measured, 'half': bonus.half if math.isfinite(bonus.half) else None,
            'expected': bonus.expected, 'band': bonus.band, 'power_limit': bonus.power_limit,
            'trials': bonus.trials, 'excluded_below': low if math.isfinite(low) else None,
            'excluded_above': high if math.isfinite(high) else None}


def band_excluded_text(low: float, high: float, quantity: str) -> str:
    return f'excludes {quantity} below {low:.6g} or above {high:.6g}'
