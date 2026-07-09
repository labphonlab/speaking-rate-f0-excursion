# Paper data pack — every number, table, and figure for writing

*Single git-tracked reference. All values copied from the regenerated
`results/supplement/TableS_*.csv` (source noted per block). Durable because
`results/`/`data/` are gitignored. Regenerate with `./scripts/run_all.sh`
(steps 0–9). Reflects the landmark-DV re-analysis (commit `9d7f61f`).*

**PRIMARY DV = `F0_excursion_LM_ST`** (fixed-landmark excursion). Raw max-min
`F0_range_ST` is a frame-count artifact (§0b) and is reported only for contrast.
Sign convention: `sign_p5_minus_p95` = partial effect at p5 duration (short=FAST)
minus p95 (long=SLOW); **negative ⇒ excursion smaller when fast ⇒ shrinks_when_fast**.
JND (config.jnd): static 0.5/1.0 st; movement 1.0/1.5 st ('t Hart 1981, stricter
yardstick for an excursion DV).

---

## 0. Provenance
Master `data/03_processed/rate_f0_master.csv` (377,518 rows). Pitch: floor 75,
ceiling 600 Hz, step 10 ms. Filters: dur 0.03–0.50 s, ≥3 voiced frames, |ΔF0|>50 Hz
octave-jump. Landmark: F0 at proportional points 0.1/0.3/0.5/0.7/0.9, interpolated
over voiced frames, edges clamped (config.landmark.props).

## 0b. Frame-count artifact & why the landmark DV  ·  src: 09_artifact_check.R, artifact_resample.py, artifact_gate_lm.py · Fig 8

Raw F0range = max−min over voiced frames. Short (fast) vowels have fewer frames, so
max−min is downward-biased ⇒ the rate→range effect risks being a sampling artifact.

- **cor(Duration, num_valid)** = 0.908 (Mono) / 0.886 (Buckeye) / 0.908 (Dial) — near-deterministic.
- **s(num_valid) covariate** shrinks the raw Duration effect 50 / 49 / 75%, but concurvity 0.97–0.98 ⇒ only suggestive.
- **Within num_valid band [5–7]**, raw Duration effect is small (0.46 / 0.62 / 0.33 st) but significant.
- **Contiguous-slice resample** (part 3): looked "MOSTLY ARTIFACT" (long 1.89 → thinned 0.48 st) — but this OVERSTATES it: a contiguous middle-slice is a flat plateau, not a compressed gesture.
- **Span-preserving downsample gate**: cut long vowels to k=4 frames holding span → raw drops only **6%**, landmark only **2%** ⇒ the pure count/order-statistic artifact is SMALL.
- **Landmark excursion** is time-scale invariant (5 fixed proportional points) and SURVIVES: 1.52 / 1.48 / 1.38 st (below); also survives within num_valid≥5 (1.39 / 1.33 / 1.25 st) ⇒ not a short-vowel under-resolution artifact.

**Conclusion:** raw max-min was ~18–25% inflated by oversampling long vowels; the
rate→excursion effect is largely REAL. Landmark DV adopted as primary.

## 1. Table 1 — Corpora  ·  src: TableS_N_audit_build.csv
| Corpus | Language | Register | Speakers | Vowel tokens |
|---|---|---|---:|---:|
| CSJ Monologue | Japanese | spontaneous monologue | 31 | 81,687 |
| CSJ Dialogue  | Japanese | dialogue (1 talker/ch) | 18 | 21,558 |
| Buckeye       | English  | conversational | 40 | 274,273 |
| **Total** | | | **89** | **377,518** |

## 2. Table 2 — Effect size: F0max vs raw F0range vs landmark excursion  ·  §3.1 · src: TableS_effect_size.csv · Fig 1, effect_size_partial.png (3×3)

5–95% effective range of s(Duration), semitones. All excursion cells shrinks_when_fast.

| Corpus | DV | eff 5-95 (ST) | slope /100ms | fit@p5 (fast) | fit@p95 (slow) | >0.5 | >1.0 | >1.5 |
|---|---|---:|---:|---:|---:|:--:|:--:|:--:|
| CSJ Monologue | max | 0.669 | 0.205 | −0.526 | −0.517 | ✓ | ✗ | ✗ |
| CSJ Monologue | raw range | 1.861 | 0.428 | −1.902 | −0.042 | ✓ | ✓ | ✓ |
| **CSJ Monologue** | **landmark** | **1.519** | 0.191 | −1.503 | 0.049 | ✓ | ✓ | ✓ |
| Buckeye | max | 0.345 | 0.121 | −0.368 | −0.086 | **✗** | ✗ | ✗ |
| Buckeye | raw range | 1.976 | 0.558 | −1.883 | 0.126 | ✓ | ✓ | ✓ |
| **Buckeye** | **landmark** | **1.484** | 0.385 | −1.388 | 0.122 | ✓ | ✓ | ✗ |
| CSJ Dialogue | max | 0.550 | 0.097 | −0.285 | −0.071 | ✓ | ✗ | ✗ |
| CSJ Dialogue | raw range | 1.739 | 0.370 | −1.568 | 0.172 | ✓ | ✓ | ✓ |
| **CSJ Dialogue** | **landmark** | **1.377** | 0.204 | −1.180 | 0.203 | ✓ | ✓ | ✗ |

Headline: F0max 0.34–0.67 ST (≤ JND; <0.5 in Buckeye). Landmark excursion 1.38–1.52
ST, clears JND 1.0 in all; clears the stricter 1.5 only in CSJ Monologue.

## 3. Robustness · §3.2 · src: TableS_robustness.csv · Fig 3
Landmark added as a definition alongside maxmin/p95p5/winsor/clean. Landmark eff:
Mono 1.519, Buckeye 1.484, Dial 1.377 st — all clear JND 1.0, shrinks_when_fast.
(Raw maxmin 1.74–1.98; p95p5 1.48–1.63; winsor ≈ maxmin; clean 1.71–1.90.)

## 4. Within/between (Mundlak) + mechanism · §3.5/§4 · src: TableS_mundlak.csv · Fig 7
Model: `DV ~ Duration_Between + s(Duration_Within) + fs(Within,Speaker) + re(Vowel)`.

| Corpus | WITHIN exc eff (ST) | dir | >1.0 | between slope | between p | within F0min sign | within F0max sign |
|---|---:|---|:--:|---:|---:|---:|---:|
| CSJ Monologue | 1.471 | down_when_fast | ✓ | −0.085 | 0.96 | +1.681 | +0.158 |
| Buckeye | 1.437 | down_when_fast | ✓ | +0.839 | 0.28 | +1.445 | −0.002 |
| CSJ Dialogue | 1.251 | down_when_fast | ✓ | −0.207 | 0.72 | +1.236 | −0.132 |

- The excursion effect is **within-speaker** (1.25–1.47 st, clears JND 1.0); between-speaker slopes are n.s. ⇒ not a between-speaker confound.
- **Mechanism:** within-speaker **F0min RISES** when fast (+1.24 to +1.68) while **F0max is ~flat** (−0.13 to +0.16) ⇒ excursion compresses because the FLOOR rises, not the ceiling falls = register-raising (Caspers & van Heuven 1993; Ladd et al. 1999).
- **Mechanism robustness** (src: TableS_mechanism_robustness.csv, mechanism_robustness_report.md). F0_LMmin_ST / F0_LMmax_ST each under the 3 checks. Base: F0min up_when_fast (eff 1.69/1.45/1.42 st) ≫ F0max ~flat (0.71/0.21/0.44); this min≫max relation is preserved under the concurvity-free checks (num_valid≥5 subset and ososagari exclusion, ≤4–26% shift, same direction). NB the smooth-covariate frame/intensity controls are concurvity-dominated for these absolute-level DVs (concurvity 0.97–0.98) and inflate rather than reduce — reported with concurvity + endpoint SEs, not interpreted as confounding.

## 5. Cross-linguistic · §3.4 · src: TableS_language_test.csv · Fig 4
Study 1 = CSJ Monologue (JP) + Buckeye (EN), N = 355,925.
- Japanese 1.519 st (clears 1.0 & 1.5); English 1.484 st (clears 1.0, below 1.5).
- Difference smooth **p = 6.7e-7 (significant)**, language-level p = 0.057; but the magnitude gap is only **0.035 st** ⇒ significance-vs-effect-size again (both clear JND, gap perceptually negligible).

## 5b. Register-matched · §3.4b · src: TableS_language_register.csv · Fig 6
Study = CSJ Dialogue (JP) + Buckeye (EN), N = 295,796.
- Japanese/Dialogue 1.377 st; English/Buckeye 1.484 st (both clear 1.0, below 1.5).
- Difference smooth **p = 0.0205 (significant)**, language-level p = 0.927; gap 0.107 st.
- NOTE: on the robust DV the register-closer difference smooth is significant (unlike the raw-range run where it was n.s. p=0.09). Honest reading: a small but significant cross-linguistic shape difference persists on both pairings, yet magnitude is tiny and both languages clear the JND ⇒ generality holds in MAGNITUDE; the earlier "register matching removes the difference" sub-claim does NOT hold on the landmark DV.

## 6. Accent-nucleus (pitch-target validity) · §3.6 · src: TableS_accent_nucleus.csv, TableS_accent_threshold_sweep.csv · Fig 5
X-JToBI accentual fall 'A'; CSJ only (Buckeye has no tone tier).

| Corpus | Subset | N | eff (ST) | >1.0 | >1.5 |
|---|---|---:|---:|:--:|:--:|
| CSJ Monologue | all | 81,686 | 1.519 | ✓ | ✓ |
| CSJ Monologue | strict | 11,799 | 1.273 | ✓ | ✗ |
| CSJ Monologue | near | 25,974 | 1.783 | ✓ | ✓ |
| CSJ Dialogue | all | 21,557 | 1.377 | ✓ | ✗ |
| CSJ Dialogue | strict | 3,238 | 1.031 | ✓ | ✗ |
| CSJ Dialogue | near | 6,984 | 1.385 | ✓ | ✗ |

Effect survives on accent-nucleus vowels (strict Mono 1.27, Dial 1.03; both clear
JND 1.0). Threshold sweep: Mono 1.27–1.78, Dial 1.03–1.39, all clear JND 1.0.

**Peak-delay / ososagari robustness** (src: TableS_peak_delay_check.csv,
peak_delay_report.md; Ishihara 2003). The X-JToBI 'A' point falls in the *next*
vowel (ososagari) for 9.7% (Mono) / 9.4% (Dial) of vowels; for those, the
within-vowel excursion under-captures by ~1 ST (current 0.85 → concat 2.07–2.23).
But **excluding them barely moves the headline** (Mono 1.52→1.54, Dial 1.38→1.35)
⇒ the effect is robust to ososagari. Caveat: AccentNucleus tags the peak-bearing
(2nd-syllable) vowel for CVCV, not the lexically accented mora — a labelling note.

## 7. Controls · §3.5 · src: TableS_AIC_study1/2.csv, TableS_buckeye_control.csv, TableS_jpgradient_*.csv
All re-fit on the landmark DV (01_fit_models.R, DV=F0_excursion_LM_ST):
- **Speaker-specific rate slopes** warranted: ΔAIC **−6,048** (study1) / **−381** (study2); full (random rate curves) favoured.
- **Buckeye segmental control**: following-consonant voicing coef **0.126 st** (p≈7e-112) but Duration effective range unchanged **1.484 → 1.492** (shift +0.008) ⇒ does not confound.
- **Japanese style gradient (§3.3)**: difference smooth s(Duration):StyleO **p = 0.678 (n.s.)**, style level term p = 0.072; per-style eff Monologue **1.52** vs Dialogue **1.38** st ⇒ style-invariant within Japanese.
- Within-speaker vs between (Mundlak, §4) gives the mechanism on the LM DV.
- **Intensity / loudness is not the confound** (src: TableS_intensity_check.csv, Fig_intensity_control.png). Duration–Intensity_Max *r* = 0.04–0.14 (fast ≠ much louder). Adding s(Intensity_Max): landmark Duration eff **1.52→1.47 / 1.48→1.42 / 1.38→1.31 st (3–5% reduction)**; s(Intensity_Mean) ≈ 0%; accent-nucleus strict ≤7%. Intensity means (dB): Mono 69.3, Buckeye 65.5, Dial 66.9. ⇒ pitch-target-specific, not loudness scaling.

## 8. Figures (`results/figures/`)
- Fig 1 `Fig1_max_vs_range.png` — §3.1, 3×3 rows: F0max / raw range / **landmark** (rebuilt)
- Fig 2 `Fig2_japanese_gradient.png` — §3.3 (landmark; diff smooth n.s. p=0.68)
- Fig 3 `Fig3_robustness.png` — §3.2
- Fig 4 `Fig4_language.png` — §3.4
- Fig 5 `Fig5_accent_nucleus.png` — §3.6
- Fig 6 `Fig6_language_register.png` — §3.4b
- Fig 7 `Fig7_mundlak.png` — §4 within-speaker F0min↑ vs F0max flat (mechanism)
- Fig 8 `Fig8_artifact_framecount.png` — §0b Duration vs num_valid
- Fig (intensity) `Fig_intensity_control.png` — §7 Duration effect before/after intensity control
- `effect_size_partial.png` — §3.1 3×3 (max / raw range / landmark) with direction

## 9. One-line claims
- 377,518 vowel tokens, 89 speakers, JP + EN.
- Raw max-min F0range is a frame-count artifact (~20% inflated); **landmark excursion** is the robust DV.
- F0max effect 0.34–0.67 ST (≤ JND). **Landmark excursion 1.38–1.52 ST, clears JND 1.0** (movement JND 1.5 only in CSJ Monologue), shrinks_when_fast.
- WITHIN-speaker (Mundlak 1.25–1.47 st, between n.s.) — not a between-speaker confound.
- Mechanism: fast speech raises the F0 FLOOR (min ↑) more than the ceiling (max flat) ⇒ register-raising compression.
- Survives on accent-nucleus vowels (strict 1.03–1.27 st).
- Generalises across JP/EN in magnitude (both clear JND; gaps 0.04/0.11 st, significant but negligible).
