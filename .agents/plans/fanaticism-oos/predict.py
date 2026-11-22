import math
import sys

import numpy as np

f = np.float32
MULT = 3.3
WEAPON = (73.62, 103.34)
ROLLS = range(0)
Z = 3.84
PER_ARM_CASTS = {"Gavel of Wrath 800617": 1400, "Gavel of Grace 800614": 1600, "Gavel of Light 800611": 1900,
                 "Horusath Blast 500154": 3500}


def armor_hit(damage, armor, level=60):
    tmp = f(armor) / f(f(85.0) * f(level) + f(400.0))
    tmp = tmp / (f(1.0) + tmp)
    return int(np.ceil(max(f(damage) * (f(1.0) - tmp), f(0.0))))


def mod12(v):
    return int(f(v) * f(1.2))


def gavel_hits(flat_values, passive, armor):
    flat_values = list(flat_values)
    percent = mod12(100) if passive else 100
    mod = f(f(100.0) * f(percent)) / f(100.0)
    hits = []
    for roll in ROLLS:
        for v in flat_values:
            fixed = mod12(v) if passive else v
            wd = int(f(f(roll + fixed) * mod) / f(100.0))
            hits.append(armor_hit(wd, armor))
    return [(h, 1.0 / len(hits)) for h in hits]


def resist_probs(avg):
    return [max(float(f(0.5) - f(2.5) * f(abs(f(f(0.1) * f(i)) - avg))), 0.0) for i in range(11)]


def horusath_hits(passive):
    avg = f(f(f(60.0) * f(1.0)) / f(5.0)) / f(100.0)
    probs = resist_probs(avg)
    total = sum(probs)
    out = []
    for die in range(1, 13):
        v = 72 + int(f(5) * f(1.06)) + die
        dmg = mod12(v) if passive else v
        for i, p in enumerate(probs):
            out.append((dmg - (dmg * i // 10), p / total / 12))
    return out


def moments(dist):
    mean = sum(h * p for h, p in dist)
    var = sum(p * (h - mean) ** 2 for h, p in dist)
    return mean, var


def row(name, without, with_):
    m0, v0 = moments(without)
    m1, v1 = moments(with_)
    ratio = m1 / m0
    bonus = 100 * (ratio - 1)
    band = max(0.05 * bonus, 2.0)
    n = PER_ARM_CASTS[name]
    out = [name, m0, m1, bonus, band]
    for label, hits in (("all casts non-critical", n), ("half the casts lost", n // 2)):
        rel = math.sqrt(v1 / (hits * m1 ** 2) + v0 / (hits * m0 ** 2))
        out.append(100 * ratio * rel * Z)
    out.append(out[5] * 2.576 / Z)
    return out, math.sqrt(v0) / m0, math.sqrt(v1) / m1


def main(armor, ap):
    global ROLLS
    bonus = f(f(ap) / f(14.0)) * f(MULT)
    ROLLS = range(int(f(WEAPON[0]) + bonus), int(f(WEAPON[1]) + bonus) + 1)
    rows = {"Gavel of Wrath 800617": range(45, 56), "Gavel of Grace 800614": range(23, 27),
            "Gavel of Light 800611": [12]}
    print(f"attack power {ap}; target armor {armor}; rolls {ROLLS[0]}..{ROLLS[-1]}; z {Z} (two-sided p "
          f"{math.erfc(Z / math.sqrt(2)):.2e}, eight readings: {8 * math.erfc(Z / math.sqrt(2)):.2e})")
    print("| Spell | Mean hit without | Mean hit with | Predicted bonus | G-19 band (+/- pts) | 99.99% half-width, "
          "full casts (pts) | half-width, half the casts (pts) | 99% half-width, full casts (pts) | relative sd without / with |")
    print("|---|---|---|---|---|---|---|---|---|")
    results = []
    for name, values in rows.items():
        results.append((name, row(name, gavel_hits(values, False, armor), gavel_hits(values, True, armor))))
    results.append(("Horusath Blast 500154", row("Horusath Blast 500154", horusath_hits(False), horusath_hits(True))))
    for name, (r, s0, s1) in results:
        print(f"| {r[0]} | {r[1]:.4f} | {r[2]:.4f} | {r[3]:+.2f}% | {r[4]:.2f} | {r[5]:.2f} | {r[6]:.2f} | {r[7]:.2f} | "
              f"{s0:.3f} / {s1:.3f} |")


main(int(sys.argv[1]), int(sys.argv[2]))
