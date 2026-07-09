# DV change: raw max−min F0range → fixed-landmark excursion (before/after)

*Kept as a standalone record for the Methods "robustness of the DV" paragraph and
for the revision summary, where the change of dependent variable must be explained.
This is the ONLY file that juxtaposes raw-range and landmark numbers; every other
current results file (paper_data_pack, results_landmark_consolidated, the four docs'
results sections) reports the **landmark** DV only.*

## Why the DV was changed
Raw excursion = `12·log2(f0_max/f0_min)` over **all** voiced F0 frames of a vowel.
Short (fast) vowels have fewer frames (Duration–num_valid *r* = 0.886–0.908), so
their max−min is downward-biased by order statistics — i.e. part of the observed
rate→range effect is a frame-count sampling artefact (see artifact_check_report.md).
The **fixed-landmark excursion** samples F0 at a duration-independent number of
points (5 fixed proportional positions), so its bias does not scale with vowel
length. It is adopted as the primary DV; raw max−min is inflated ~18–25%.

## Headline effect size — 5–95% Duration effective range (ST)
| Corpus | F0max | raw max−min | **landmark (primary)** | raw→landmark change |
|---|---:|---:|---:|---:|
| CSJ Monologue | 0.67 | 1.86 | **1.52** | −18% |
| Buckeye | 0.34 | 1.98 | **1.48** | −25% |
| CSJ Dialogue | 0.55 | 1.74 | **1.38** | −21% |

All landmark values clear the 1.0 ST JND (CSJ Monologue also clears the stricter
1.5 ST movement threshold; Buckeye/Dialogue sit just below 1.5). Direction on both
DVs: shrinks_when_fast.

## Downstream analyses — raw vs landmark (both computed under identical models)
| Analysis | raw max−min | landmark | note |
|---|---|---|---|
| Robustness p95/p5 (most conservative) | 1.48–1.63 | landmark 1.38–1.52 | all clear JND 1.0 |
| JP style gradient (Mono vs Dial) | 1.86 / 1.74; diff-smooth p=0.46 | 1.52 / 1.38; p=0.678 | style-invariant on both |
| Cross-linguistic (JP vs EN) | 1.86 / 1.98; diff p=6e-4; gap 0.12 | 1.52 / 1.48; diff p=7e-7; gap 0.035 | both clear JND; gap tiny |
| Register-closer (Dial vs Buckeye) | 1.74 / 1.98; diff p=0.09 (n.s.) | 1.38 / 1.48; diff p=0.02 (sig) | see caveat below |
| Accent-nucleus strict (Mono / Dial) | 1.59 / 1.40 | 1.27 / 1.03 | clears JND 1.0 on both DVs |
| Within-speaker (Mundlak) | — (run on landmark) | 1.47 / 1.44 / 1.25 | between-speaker n.s. |

**Caveat that flipped with the DV.** On raw range the register-closer difference
smooth was non-significant (p=0.09); on the robust landmark DV it is significant
(p=0.02), though the magnitude gap stays tiny (0.11 ST). The generality claim is
therefore argued from *effect-size magnitude* (gaps 0.04–0.11 ST, both clear JND),
NOT from a non-significant difference smooth. (This is the one substantive
conclusion that changed with the DV; all others are preserved.)

## Effect-size controls unaffected by the DV change
Speaker-specific rate slopes (ΔAIC −6,048/−381), Buckeye segmental control
(1.48→1.49 ST), and the intensity-confound control (3–5% reduction) were all
re-fit on the landmark DV and hold. Source tables: TableS_effect_size,
TableS_robustness, TableS_language_test, TableS_language_register,
TableS_accent_nucleus, TableS_mundlak, TableS_AIC_study1/2, TableS_buckeye_control,
TableS_intensity_check.
