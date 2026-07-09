# Rate–F0 results — LANDMARK DV only (consolidated)

*Single consolidated reference. **Every effect size here is the fixed-landmark
excursion `F0_excursion_LM_ST`** (F0 at 5 fixed proportional points 10/30/50/70/90%,
linearly interpolated over voiced frames, edges clamped; frame-count-independent).
Raw max−min numbers are deliberately **excluded** — they live only in
`dv_change_raw_vs_landmark.md`. F0max is retained solely as the level-DV contrast
for the effect-size question. All values from regenerated `results/supplement/TableS_*.csv`.*

Why landmark (not raw max−min): raw max−min over all voiced frames is frame-count
biased (Duration–num_valid r≈0.9); the landmark estimator uses a fixed number of
points and is time-scale invariant. Full diagnostic: `artifact_check_report.md`.

JND bands (config.jnd): static 0.5/1.0 ST; movement 1.0/1.5 ST ('t Hart 1981).
Sign: all excursion cells **shrinks_when_fast** (partial effect lower at short/fast).

---

## Table 1 — Corpora (post-filter) · TableS_N_audit_build.csv
| Corpus | Language | Register | Speakers | Vowel tokens |
|---|---|---|---:|---:|
| CSJ Monologue | Japanese | spontaneous monologue | 31 | 81,687 |
| CSJ Dialogue  | Japanese | dialogue (1 talker/ch) | 18 | 21,558 |
| Buckeye       | English  | conversational | 40 | 274,273 |
| **Total** | | | **89** | **377,518** |

## Table 2 — Effect size (landmark excursion) · §3.1 · TableS_effect_size.csv
5–95% Duration effective range, ST. (F0max contrast: 0.34–0.67 ST, ≤ JND — the
level DV, not an excursion.)
| Corpus | landmark eff (ST) | slope /100ms | fit@p5 (fast) | fit@p95 (slow) | >1.0 | >1.5 |
|---|---:|---:|---:|---:|:--:|:--:|
| CSJ Monologue | **1.519** | 0.191 | −1.503 | 0.049 | ✓ | ✓ |
| Buckeye | **1.484** | 0.385 | −1.388 | 0.122 | ✓ | ✗ |
| CSJ Dialogue | **1.377** | 0.204 | −1.180 | 0.203 | ✓ | ✗ |

## Table 3 — Robustness (excursion definitions) · §3.2 · TableS_robustness.csv
Landmark is the frame-count-robust definition; all definitions clear JND 1.0.
| Corpus | landmark eff (ST) | sign(p5−p95) | direction | >1.0 | >1.5 |
|---|---:|---:|---|:--:|:--:|
| CSJ Monologue | 1.519 | −1.551 | shrinks_when_fast | ✓ | ✓ |
| Buckeye | 1.484 | −1.510 | shrinks_when_fast | ✓ | ✗ |
| CSJ Dialogue | 1.377 | −1.383 | shrinks_when_fast | ✓ | ✗ |

## Table 4 — Within/between (Mundlak) + mechanism · §3.5/§4 · TableS_mundlak.csv
| Corpus | WITHIN exc eff (ST) | dir | >1.0 | between p | within F0min sign | within F0max sign |
|---|---:|---|:--:|---:|---:|---:|
| CSJ Monologue | 1.471 | down_when_fast | ✓ | 0.96 | +1.681 | +0.158 |
| Buckeye | 1.437 | down_when_fast | ✓ | 0.28 | +1.445 | −0.002 |
| CSJ Dialogue | 1.251 | down_when_fast | ✓ | 0.72 | +1.236 | −0.132 |

Within-speaker effect (not a between-speaker confound); mechanism = F0 **floor
rises** when fast, ceiling flat ⇒ register-raising undershoot.

## Table 5 — Cross-linguistic · §3.4 · TableS_language_test.csv / TableS_language_register.csv
| Pair | JP eff | EN eff | diff-smooth p | gap (ST) | both > JND 1.0 |
|---|---:|---:|---:|---:|:--:|
| Mono vs Buckeye | 1.519 | 1.484 | 7e-7 | 0.035 | ✓ |
| Dialogue vs Buckeye (register-closer) | 1.377 | 1.484 | 0.02 | 0.107 | ✓ |
Difference smooths are significant but the magnitude gaps are perceptually
negligible ⇒ generality holds in effect size.

## Table 6 — Japanese style-invariance · §3.3 · TableS_jpgradient_*.csv
Per-style eff: Monologue 1.52 / Dialogue 1.38 ST; difference smooth s(Duration):StyleO
**p = 0.678 (n.s.)**, style level p = 0.072 ⇒ style-invariant within Japanese.

## Table 7 — Accent-nucleus (pitch-target validity) · §3.6 · TableS_accent_nucleus.csv
| Corpus | all | strict | near | strict > JND1.0 |
|---|---:|---:|---:|:--:|
| CSJ Monologue | 1.519 | 1.273 | 1.783 | ✓ |
| CSJ Dialogue | 1.377 | 1.031 | 1.385 | ✓ |
Threshold sweep: Mono 1.27–1.78 / Dial 1.03–1.39, all clear JND 1.0.

## Table 8 — Controls (all on landmark DV)
- Speaker-specific rate slopes: ΔAIC −6,048 (study1) / −381 (study2) → warranted.
- Buckeye segmental (NextVoiceless): 0.126 ST (p≈7e-112); Duration eff 1.484 → 1.492 (no confound).
- Intensity control (Intensity_Max): eff 1.52→1.47 / 1.48→1.42 / 1.38→1.31 (3–5% reduction; Duration–intensity r=0.04–0.14) → not loudness scaling.

## Figures
Fig1 (max/raw/landmark 3-row), Fig2 (JP style), Fig3 (robustness), Fig4 (language),
Fig5 (accent), Fig6 (register), Fig7 (mundlak mechanism), Fig8 (artifact),
Fig_intensity_control, effect_size_partial.

## One-line summary
377,518 tokens / 89 speakers. Landmark excursion effect **1.38–1.52 ST (all > JND
1.0)**, shrinks_when_fast, within-speaker, mechanism = F0-floor raising, robust to
excursion definition / style / language / accent-nucleus / intensity.
