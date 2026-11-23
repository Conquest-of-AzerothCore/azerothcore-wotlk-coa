from dataclasses import dataclass
import math
from statistics import NormalDist

from bonus import ALERT, EPSILON, NOT_JUDGED, OK, ArmSample, Bonus, bonus_band, scaled_trials
from stack import student_t_quantile

NAME = 'control_excluded'
MAXIMUM_RESIDUAL = 0.005


def parse(raw) -> dict | None:
    if raw is None:
        return None
    residual = raw.get('residual') if isinstance(raw, dict) and set(raw) == {'residual'} else None
    if isinstance(residual, bool) or not isinstance(residual, (int, float)) \
            or not 0 < residual <= MAXIMUM_RESIDUAL:
        raise ValueError(f'{NAME} is {{"residual": p}} with 0 < p <= {MAXIMUM_RESIDUAL}, not {raw!r}')
    return {'residual': float(residual)}


def check(spell: int, expected_bonus: float, option: dict | None, plain_ratio: bool) -> None:
    if option is None:
        return
    if not plain_ratio:
        raise ValueError(f'{spell} {NAME} judges a plain percent bonus, not a flat token, a rate or a stated part')
    if abs(expected_bonus) <= EPSILON or abs(expected_bonus) > bonus_band(expected_bonus) + EPSILON:
        raise ValueError(f'{spell} {NAME} is for a stated bonus whose band holds 0; {expected_bonus:+g}% passes '
                         f'within +-{bonus_band(expected_bonus):g} points, so the band alone decides')


def contract(expected_bonus: float, option: dict) -> str:
    residual = option['residual']
    side = 'lower' if expected_bonus > 0 else 'upper'
    return (f'; the stated {expected_bonus:+g}% lies within {bonus_band(expected_bonus):g} points of 0, so its band '
            f'holds the control: it counts only if the one-sided {1 - residual:.6g} {side} bound of the bonus '
            f'excludes 0 (a server without the effect passes with probability at most {residual:g}), the standard '
            f'error is at most |{expected_bonus:g}| / (2 t), so a server at the stated bonus fails that bound with '
            f'probability at most {residual:g}, and the estimate lies inside the band')


def ratio_error(treatment: ArmSample, control: ArmSample) -> tuple[float, float]:
    ratio = treatment.mean / control.mean
    terms = [(treatment.share / control.mean ** 2, treatment.trials - 1),
             (ratio ** 2 * control.share / control.mean ** 2, control.trials - 1)]
    spread = sum(term for term, _ in terms)
    if math.isinf(spread):
        return math.inf, math.nan
    if spread <= 0:
        return 0.0, math.inf
    dof = spread ** 2 / sum(term ** 2 / dof for term, dof in terms if term > 0)
    return math.sqrt(spread) * 100, dof


@dataclass(frozen=True)
class Exclusion:
    error: float
    dof: float
    residual: float
    quantile: float
    bound: float
    error_limit: float
    rerun_failure: float

    def detail(self) -> dict:
        return {'standard_error': self.error, 'dof': self.dof if math.isfinite(self.dof) else None,
                'residual': self.residual, 'quantile': self.quantile, 'bound': self.bound,
                'error_limit': self.error_limit, 'rerun_failure_at_estimate': self.rerun_failure}


def exclusion_of(bonus: Bonus, treatment: ArmSample, control: ArmSample, option: dict) -> Exclusion | None:
    error, dof = ratio_error(treatment, control)
    if not math.isfinite(error):
        return None
    residual = option['residual']
    quantile = student_t_quantile(1 - residual, dof)
    sign = 1.0 if bonus.expected > 0 else -1.0
    bound = bonus.measured - sign * quantile * error
    limit = abs(bonus.expected) / (2 * quantile)
    rerun = 0.0 if error <= 0 else NormalDist().cdf(quantile - sign * bonus.measured / error)
    return Exclusion(error, dof, residual, quantile, bound, limit, rerun)


def status(bonus: Bonus, exclusion: Exclusion | None) -> tuple[str, str, int | None]:
    band_low, band_high = bonus.expected - bonus.band, bonus.expected + bonus.band
    if bonus.high < band_low - EPSILON or bonus.low > band_high + EPSILON:
        return ALERT, 'the 99% interval lies outside the band', None
    if exclusion is None:
        return NOT_JUDGED, 'not judged: one trial per arm gives no standard error', None
    side = 'lower' if bonus.expected > 0 else 'upper'
    stated = (f'the one-sided {1 - exclusion.residual:.6g} {side} bound {exclusion.bound:+.4g}% '
              f'(t {exclusion.quantile:.4g}, standard error {exclusion.error:.4g} points)')
    if exclusion.error > exclusion.error_limit + EPSILON:
        return (NOT_JUDGED, f'not judged: the standard error {exclusion.error:.4g} points is above '
                            f'{exclusion.error_limit:.4g}, so a server at the stated bonus would miss the control '
                            f'exclusion with probability above {exclusion.residual:g}',
                scaled_trials(bonus.trials, exclusion.error, exclusion.error_limit))
    rerun = (f'; a rerun on a server whose bonus is this estimate misses the exclusion with probability about '
             f'{exclusion.rerun_failure:.2g}')
    if (bonus.expected > 0 and exclusion.bound <= EPSILON) or (bonus.expected < 0 and exclusion.bound >= -EPSILON):
        return ALERT, f'{stated} does not exclude the control (0), so the effect is not told apart from none', None
    if not band_low - EPSILON <= bonus.measured <= band_high + EPSILON:
        return ALERT, f'{stated} excludes the control, but the reading lies outside the band{rerun}', None
    return (OK, f'{stated} excludes the control (0), a server without the effect passing with probability at most '
                f'{exclusion.residual:g}, and the reading lies inside the band{rerun}', None)
