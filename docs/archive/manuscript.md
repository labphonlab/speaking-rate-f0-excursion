# Speech rate compresses F0 excursion, not F0 maximum: an effect-size–first, cross-linguistic corpus study of Japanese and English

*Superseded development draft (not the final manuscript; see `../manuscript_final/`).
Numeric values from `results/supplement/TableS_*` and `results/figures/`, regenerated
by `scripts/run_all.sh`.*

*Primary DV = frame-count-robust **landmark excursion** (§2.2, §3.1b). `docs/paper_data_pack.md`
holds the full number set. In-text citations drafted (see References — verify each
against the original); remaining before submission: final copy-edit.*

---

## Abstract

Speech rate is widely held to modulate fundamental frequency (F0): faster speech
is said to compress the pitch range. Large speech corpora make such effects
trivially "significant", yet significance at *N* in the hundreds of thousands says
nothing about whether an effect is perceptually or mechanistically real. We
reanalyse the rate–F0 relationship in three corpora (**377,518** vowel tokens from
**89** speakers of Japanese and English), making **effect size in perceptual units
(semitones, ST) the primary outcome** and comparing it throughout to the F0
just-noticeable difference (JND ≈ 0.5–1.0 ST). We show that the dependent variable
is decisive. Measured as **F0 maximum per vowel**, the rate effect is 0.34–0.67 ST —
at or below the JND, and below 0.5 ST in the largest corpus. A naïve max−min
excursion is larger (1.74–1.98 ST) but we show it is partly a **frame-count
artifact** (short vowels have fewer voiced F0 frames, biasing max−min downward). We
therefore adopt a **frame-count-robust fixed-landmark excursion** (F0 at five fixed
proportional positions; time-scale invariant). On this measure the effect survives
at a **5–95% effective range of 1.38–1.52 ST — above the 1.0 ST JND in every
corpus** (~20% below the inflated max−min). The effect is (i) robust to how
excursion is operationalised, (ii) a **within-speaker** phenomenon (Mundlak
decomposition; between-speaker slopes n.s.), (iii) present and JND-exceeding in
both languages, and (iv) surviving on vowels that bear an explicit tonal target
(X-JToBI accent nuclei). A within-speaker decomposition of the excursion shows the
mechanism: **fast speech raises the F0 floor (minimum) while the ceiling (maximum)
stays flat**, compressing the excursion — a register-raising undershoot. We argue
that rate–F0 covariation is real but must be measured with a frame-count-robust
excursion and judged by effect size, not significance.

---

## 1. Introduction

That speaking faster reduces pitch movement is an old and intuitive claim, and a
common control variable in intonation research (Fougeron & Jun, 1998; Caspers &
van Heuven, 1993; Ladd, Faulkner, Faulkner, & Schepman, 1999). The predicted pattern is
simple: as vowels shorten, there is less time to realise pitch movement, so the
F0 range contracts. Testing this in large spontaneous corpora, however, exposes
three methodological hazards that, we argue, have obscured the phenomenon:
significance-inflation, measurement validity, and — newly — a frame-count artefact
in the excursion measure itself.

**Significance versus effect size.** With corpora of hundreds of thousands of
tokens, virtually any non-zero association is "significant". The relevant question
is not whether rate affects F0 (*p* < .05 is guaranteed) but whether the effect is
large enough to matter — perceptually and mechanistically. We therefore adopt an
**effect-size–first** stance: for every model we report the fitted population
effect as an **effective range in semitones over the 5th–95th percentile of vowel
duration**, and compare it directly to the F0 JND (≈0.5–1.0 ST; 't Hart, 1981).
*p*-values are reported but ground no claim.

**Measurement validity.** Summarising a vowel's pitch by its **F0 maximum**
presupposes a single pitch *target* on every vowel — an assumption inconsistent
with autosegmental-metrical intonational phonology and with (X-)ToBI, in which
tonal targets are sparse and associated with prominent or boundary positions, not
with each vowel (Pierrehumbert, 1980; Beckman & Pierrehumbert, 1986; Ladd, 2008).
A maximum is also not an *excursion*: it is a level, not a
movement. We therefore adopt an **F0 excursion** DV, and additionally verify the
result on the subset of vowels that *do* carry a tonal specification.

**Frame-count artefact.** An excursion taken as max−min over the voiced F0 frames
of a vowel is biased by the number of frames: short (fast) vowels are sampled less,
so their max−min is systematically smaller — the very effect under test can be an
artefact of the estimator. We diagnose this directly and adopt a **fixed-landmark
excursion** whose point count is independent of duration (§2.2, §3.1b).

**Design confound.** Comparing languages across corpora that also differ in
speaking style confounds language with register. We mitigate this by **sampling
Japanese in two styles** (spontaneous monologue and dialogue), so that style
varies within a language, and we are explicit about the residual register mismatch
in the cross-linguistic comparison.

We test four hypotheses: **H1** the excursion effect exceeds the JND; **H2** it is
robust to how excursion is operationalised; **H3** it is invariant across speaking
style within Japanese; **H4** it generalises across languages. A fifth question —
whether the effect depends on the "one target per vowel" assumption — is addressed
by an accent-nucleus sub-analysis.

## 2. Method

### 2.1 Corpora

Three corpora were analysed (Table 1). Two are Japanese: the **Corpus of
Spontaneous Japanese (CSJ)** monologue subset (Maekawa, 2003), and a CSJ
**dialogue** subset. One is English: the **Buckeye Corpus** of conversational
speech (Pitt et al., 2007). After filtering (§2.4), the data comprise 377,518
vowel tokens from 89 speakers.

### 2.2 Pitch measurement and the dependent variable

F0 was extracted with Praat's autocorrelation algorithm (Boersma & Weenink, 2021)
via `parselmouth` (Jadoul, Thompson, & de Boer, 2018) (pitch floor 75 Hz,
ceiling 600 Hz, time step 10 ms). For each vowel we computed,
over voiced frames, f0_max/min/mean and percentiles.

A naïve within-vowel excursion `12·log2(f0_max/f0_min)` over all voiced frames is,
however, **confounded with frame count**: short (fast) vowels have fewer F0 samples
(Duration–frame-count *r* ≈ 0.9), so their max−min is downward-biased by order
statistics (§3.1b). We therefore define the **primary dependent variable** as a
**frame-count-robust fixed-landmark excursion**:

> **F0 excursion (landmark)** = `12·log2(F0_LMmax / F0_LMmin)` (semitones),

where F0_LMmax/min are the max/min of F0 at **five fixed proportional positions**
(10, 30, 50, 70, 90% of the vowel), obtained by linear interpolation over the
voiced track (edges clamped). Because the number of measurement points is fixed
regardless of duration, this estimator is **time-scale invariant** and not
frame-count-biased. The raw max−min excursion (`F0_range_ST`) and **F0 maximum**
(`12·log2(f0_max)`) are retained only for the contrast in §3.1. Semitone
*differences* are reference-invariant.

### 2.3 CSJ Dialogue speaker attribution

The dialogue recordings pair a single segmentation tier with two channel files
(-L, -R). We verified empirically that the labelled segments belong to a **single
talker**: within labelled speech, per-segment RMS is ~10× larger on one channel.
We therefore measured F0 only on the annotated (dominant) channel and set speaker
= session (**18 speakers**). Applying the same intervals and filters to *both*
channels (the naive two-channel treatment) yields 25,560 tokens; keeping only the
dominant channel yields 21,558 — so the naive treatment would add **4,002** phantom
cross-channel tokens (~16% of the naive total) as a spurious second speaker.

### 2.4 Filtering

Vowel tokens were retained if duration ∈ [0.03, 0.50] s and there were ≥3 voiced
frames. Octave errors were removed with an **absolute Hz criterion** (any adjacent
frame-to-frame |ΔF0| > 50 Hz flags the token), following the manuscript's stated
criterion rather than a ratio heuristic. A complete, auditable N-audit
(input/used/dropped/speakers) and an exclusive exclusion breakdown accompany every
step (Tables S).

### 2.5 Statistical models

We fitted generalised additive mixed models (`mgcv::bam`, fREML, `discrete=TRUE`;
Wood, 2017) of the form

```
F0_excursion_LM_ST ~ s(Duration, k=20)
            + s(Duration, Speaker, bs="fs", m=1, k=5)   # speaker-specific rate curves
            + s(Vowel, bs="re")                          # vowel random effect
```
A **within/between (Mundlak) variant** replaces Duration with its speaker mean
(Duration_Between, linear) and within-speaker deviation (s(Duration_Within)) to
separate within-speaker rate changes from between-speaker differences (§3.5).

with `+ Language + s(Duration, by=Language)` for the cross-linguistic test and an
ordered-factor difference smooth for the within-Japanese style test. From each
fitted population smooth we report the **5–95% effective range** (max − min of the
partial effect over the central 90% of durations) and the **slope in ST per
100 ms**. (The R build lacks OpenMP, so `bam` runs single-threaded; this affects
only runtime.)

### 2.6 Accent-nucleus tagging

To test whether the effect depends on tonally-unspecified vowels, we used the CSJ
**X-JToBI tone tier** (Maekawa, Kikuchi, Igarashi, & Venditti, 2002). Each accentual-fall label ('A'/'Ax') was mapped to vowel
intervals: a vowel is a **strict** accent nucleus if an 'A' point falls inside it,
and a **near** nucleus if the nearest 'A' is within 100 ms. Sensitivity to this
mapping is assessed by sweeping the distance threshold (§3.6).

## 3. Results

### 3.1 Effect size: F0 maximum vs. raw range vs. landmark excursion (Fig. 1, Table 2)

The choice of dependent variable is decisive (Fig. 1, three rows). With **F0
maximum**, the 5–95% effective range is **0.67 ST (CSJ Monologue), 0.34 ST
(Buckeye), and 0.55 ST (CSJ Dialogue)** — at or below the JND, and **below the
0.5 ST JND in the largest corpus** despite overwhelming significance. A naïve
max−min range is much larger (1.86 / 1.98 / 1.74 ST) but partly artefactual
(§3.1b). On the **frame-count-robust landmark excursion** the effect is **1.52
(CSJ Monologue), 1.48 (Buckeye), and 1.38 ST (CSJ Dialogue)** — all above the
1.0 ST JND (and above the stricter 1.5 ST movement threshold in CSJ Monologue),
about 18–25% below the inflated max−min. All excursion cells are *shrinks_when_fast*
(partial effect lower at short duration). Had F0 maximum been retained the
significance-vs-effect critique would have been fatal; on the landmark excursion
the effect is perceptually substantial and not a sampling artefact.

### 3.1b The max−min excursion is partly a frame-count artefact (Fig. 8)

A max−min excursion is computed over the voiced F0 frames of a vowel, and short
(fast) vowels have fewer frames (Duration–num_valid *r* = 0.89–0.91), so max−min is
downward-biased by order statistics. We quantified this. Adding a `s(num_valid)`
covariate shrinks the raw Duration effect 49–75%, but the two are nearly collinear
(concurvity 0.97–0.98), so this is only suggestive. A **span-preserving downsample**
is decisive: cutting long vowels to four frames while holding the vowel's time span
fixed drops raw max−min by only ~6% and the landmark excursion by ~2% — the pure
count/order-statistic artefact is *small*. The landmark excursion (five fixed
proportional points; time-scale invariant) survives at 1.38–1.52 ST, and still at
1.25–1.39 ST when restricted to adequately-sampled vowels (num_valid ≥ 5). Because
the landmark measure is invariant to pure time-scaling, a "same gesture, faster"
would give a *zero* effect; the surviving 1.4–1.5 ST is genuine undershoot. We
therefore use the landmark excursion throughout.

### 3.2 Robustness of the excursion measure (Fig. 3, Table S)

We recomputed the effect under several excursion definitions — landmark, raw
max/min, a percentile excursion (p95/p5), a per-speaker winsorised excursion, and a
refit excluding suspicious-f0_min tokens. **Every definition, in every corpus,
clears the 1.0 ST JND**; the landmark excursion (1.38–1.52 ST) is the most
conservative frame-count-robust member and is *shrinks_when_fast* throughout.

### 3.3 Style-invariance within Japanese (Fig. 2)

Sampling Japanese in two styles separates style from language. On the landmark DV
the rate→excursion curve does **not** differ between monologue and dialogue: the
ordered-factor difference smooth is non-significant (*p* = 0.68) and the style level
term is only marginal (*p* = 0.07); the per-style effective ranges are similar
(**1.52 vs. 1.38 ST**). The effect is not a by-product of speaking style.

### 3.4 Cross-linguistic generality (Fig. 4 & 6, Table S)

In Japanese and English the effect clears the 1.0 ST JND in both (**1.52 vs.
1.48 ST**). The difference smooth is statistically significant (*p* = 7×10⁻⁷), but
the magnitude gap is only **0.035 ST** at N ≈ 356,000 — a within-data demonstration
of the significance-vs-effect-size point (§3.1/§4.2). Because the monologue-Buckeye
contrast is register-*mismatched*, we also ran the register-*closest* pair, **CSJ
Dialogue** vs. Buckeye (Fig. 6): the effect again clears the JND in both (**1.38 vs.
1.48 ST**), with a significant but tiny difference smooth (*p* = 0.02; gap 0.11 ST).
We are candid that, on the robust DV, a small cross-linguistic *shape* difference is
statistically detectable in both pairings — we do **not** claim register matching
removes it. What the data show is that the effect is JND-exceeding and near-identical
in magnitude across languages and register pairings (gaps 0.04–0.11 ST), so the
generality holds where it matters — in effect size — while any language difference is
perceptually negligible.

### 3.5 Within-speaker locus and mechanism (Fig. 7)

A within/between (Mundlak) decomposition shows the effect is a **within-speaker**
phenomenon: the within-speaker excursion effect is 1.47 / 1.44 / 1.25 ST (Monologue
/ Buckeye / Dialogue), clearing the JND in every corpus, while between-speaker
slopes are non-significant — it is not a between-speaker confound. Decomposing the
excursion into its floor and ceiling reveals the mechanism (Fig. 7): **within a
speaker, speeding up raises the F0 minimum (+1.24 to +1.68 ST) while the F0 maximum
stays essentially flat (−0.13 to +0.16 ST)**. The excursion compresses because the
*floor rises*, not because the ceiling falls — a register-raising undershoot
consistent with Caspers & van Heuven (1993) and Ladd et al. (1999). **Controls:**
speaker-specific rate slopes are warranted (ΔAIC = −6,048 cross-language; −381
dialogue); following-consonant voicing in Buckeye is significant (0.13 ST,
*p* ≈ 10⁻¹¹²) but does not confound the rate effect (Duration effective range
1.48 → 1.49 ST with the control); basis-dimension checks (`k.check`) are satisfactory.
**Intensity is not the explanation.** A rival account is that fast speech simply
raises vocal effort, so the excursion compression is loudness scaling rather than a
pitch-target effect. But speech rate and intensity are only weakly correlated
(Duration–Intensity_Max *r* = 0.04–0.14), and adding `s(Intensity_Max)` reduces the
Duration effective range by only 3–5% (1.52→1.47 / 1.48→1.42 / 1.38→1.31 ST; ≤7% on
accent-nucleus vowels; an intensity-mean control leaves it unchanged). The effect is
pitch-target-specific, not loudness scaling.

### 3.6 The effect holds on tonally-targeted vowels (Fig. 5, Table S)

Restricting the analysis to X-JToBI **accent-nucleus** vowels — the vowels for
which a pitch target *is* posited — does not remove the effect. On the landmark DV
the CSJ Monologue strict in-vowel-nucleus subset (N = 11,799; 14% of tone-annotated
vowels) gives a 5–95% effective range of **1.27 ST** (above the 1.0 ST JND), with a
per-100 ms slope **~4.9× steeper** than over all vowels (0.94 vs. 0.19 ST/100 ms) —
as expected if the accented mora is where the excursion is realised and thus where
temporal compression bites hardest. CSJ Dialogue shows the same pattern (strict
nucleus 1.03 ST, above the JND). The result is insensitive to how tightly the 'A'
label is tied to the vowel: sweeping the label-to-vowel distance from strict
(in-vowel) through ≤150 ms yields **1.27–1.78 ST (Monologue) / 1.03–1.39 ST
(Dialogue)**, every value above the 1.0 ST JND. The covariation is therefore not an
artefact of pooling tonally-unspecified vowels.

## 4. Discussion

### 4.1 A mechanism: temporal undershoot of pitch targets

The results cohere under a single mechanism: **temporal undershoot realised as
register-raising**. As a vowel shortens, there is less time to execute the pitch
movement, so the realised excursion contracts. Crucially, the within-speaker
decomposition (§3.5) shows *how*: it is the **F0 floor that rises** while the
ceiling stays flat — fast speech does not pull the peak down so much as fail to
reach the low end, lifting F0 minima. This is the register-raising pattern reported
by Caspers & van Heuven (1993) and Ladd et al. (1999). The framework unifies our
observations. The effect surfaces on **excursion, not maximum** (§3.1): undershoot
is a reduced *span*, and specifically a raised floor. It is a **within-speaker**
effect (§3.5), not a between-speaker artefact. Its slope is **steepest on
accent-nucleus vowels** (§3.6), the locus of the largest intended movement. And it
is **style- and language-invariant in magnitude** (§3.3–3.4), as expected of a
general articulatory–tonal timing constraint. Because the landmark excursion
measures realised movement with a frame-count-robust, time-scale-invariant estimator,
it is both a defensible observable and the quantity the mechanism predicts.

### 4.2 Significance is not effect size

Our cross-linguistic contrast (§3.4) is a cautionary example in miniature: a
"highly significant" language difference (*p* = 7×10⁻⁷) that is perceptually
negligible (0.035 ST) purely because N is large. The frame-count artefact (§3.1b)
is a second cautionary example — a large, "robust" max−min effect that partly
reflects the estimator, not the phenomenon. Both vindicate reporting and
adjudicating large-corpus phonetic findings in perceptual effect-size units on a
measure whose bias is understood.

### 4.3 Limitations

(a) **Register matching** across languages is imperfect; the register-closer
Dialogue-vs-Buckeye test (§3.4) narrows but does not eliminate a (small,
perceptually negligible) cross-linguistic shape difference, and a fully
register-matched *conversational Japanese* point would be ideal. (b) The **Corpus of
Everyday Japanese Conversation (CEJC)** would complete a within-Japanese
monologue→dialogue→conversation gradient; it was unavailable for this submission and
would strengthen the generality claim. (e) The landmark excursion uses five fixed
points; the shortest vowels still carry the largest measurement uncertainty, though
the num_valid ≥ 5 sub-analysis (§3.1b) shows the effect does not depend on them.
(c) Extraction used a fixed 75–600 Hz pitch range rather than speaker-specific
ranges (a config-documented choice; two-pass speaker-adaptive extraction is left
for future work). (d) Accent-nucleus tagging relies on tone-tier label alignment;
we mitigate this with a distance-threshold sweep (§3.6). (f) **Peak delay
(ososagari).** In Tokyo Japanese the F0 peak of a word-initial CVCV accent aligns
to the *following* vowel (Ishihara, 2003), so a within-vowel excursion can miss the
peak. Using the X-JToBI 'A' points we find the accentual fall falls in the *next*
vowel for **9.4–9.7%** of CSJ vowels; for those tokens the within-vowel landmark
excursion under-captures the F0 movement by ~1 ST relative to the concatenated
vowel-plus-next-vowel interval. Crucially, **excluding these tokens leaves the
headline effect essentially unchanged** (CSJ Monologue 1.52→1.54, Dialogue
1.38→1.35 ST), so the conclusion is robust to ososagari; the caveat is one of
phonological *labelling* — for CVCV, the vowel our procedure tags as the "nucleus"
is the peak-bearing second-syllable vowel, not the lexically accented first mora.

## 5. Conclusion

Measured with a frame-count-robust landmark excursion, the rate–F0 relationship is
perceptually meaningful (1.4–1.5 ST, above the JND), robust to measurement
definition, a within-speaker effect, invariant in magnitude across speaking style
and language, and present on tonally-targeted vowels. Its mechanism is a
register-raising undershoot — fast speech lifts the F0 floor while the ceiling
stays put. The phenomenon is real, but it is ~20% smaller than a naïve max−min
suggests and must be measured with an estimator whose frame-count bias is
controlled and judged by effect size rather than significance.

---

## Table 1 — Corpora (final, post-filter)

| Corpus | Language | Register | Speakers | Vowel tokens |
|---|---|---|---|---|
| CSJ Monologue | Japanese | spontaneous monologue | 31 | 81,687 |
| CSJ Dialogue  | Japanese | dialogue (1 talker/channel) | 18 | 21,558 |
| Buckeye       | English  | conversational | 40 | 274,273 |
| **Total**     |          |                | **89** | **377,518** |

## Table 2 — Effect size vs. JND (5–95% effective range, semitones)

Primary DV = landmark excursion; raw max−min shown for contrast (frame-count inflated).

| Corpus | F0max | > 0.5 | raw range | **landmark** | > JND 1.0 | > 1.5 | LM slope (ST/100 ms) |
|---|---|---|---|---|---|---|---|
| CSJ Monologue | 0.67 | yes | 1.86 | **1.52** | yes | yes | 0.19 |
| Buckeye       | 0.34 | **no** | 1.98 | **1.48** | yes | no | 0.38 |
| CSJ Dialogue  | 0.55 | yes | 1.74 | **1.38** | yes | no | 0.20 |

## Figures (`results/figures/`)

- **Fig. 1** `Fig1_max_vs_range.png` — 3 rows: F0max / raw max−min / landmark excursion, 3 corpora.
- **Fig. 2** `Fig2_japanese_gradient.png` — within-Japanese style invariance (difference smooth n.s.).
- **Fig. 3** `Fig3_robustness.png` — effect stable across excursion definitions.
- **Fig. 4** `Fig4_language.png` — Japanese vs. English generality.
- **Fig. 5** `Fig5_accent_nucleus.png` — effect holds (steeper slope) on X-JToBI accent-nucleus vowels.
- **Fig. 6** `Fig6_language_register.png` — register-closer pair (CSJ Dialogue vs. Buckeye).
- **Fig. 7** `Fig7_mundlak.png` — within-speaker F0min↑ vs F0max flat (mechanism).
- **Fig. 8** `Fig8_artifact_framecount.png` — Duration vs frame count (artifact diagnostic).
- **Fig. (intensity)** `Fig_intensity_control.png` — Duration effect before/after intensity control (unchanged).

## Reproducibility

Extraction (Python/`parselmouth`, pinned via `uv`) → modelling (R/`mgcv`, pinned
via `renv`) → figures are fully scripted; the entire pipeline runs end-to-end via
`scripts/run_all.sh` (steps 0–10). Supplementary tables `TableS_*` and per-step
reports are written to `results/supplement/`.

## References

*⚠ Verify each entry against the original before submission — author lists, years,
volume/page numbers should be double-checked; formatted here in APA-ish style.*

- Beckman, M. E., & Pierrehumbert, J. B. (1986). Intonational structure in Japanese and English. *Phonology Yearbook, 3*, 255–309.
- Boersma, P., & Weenink, D. (2021). *Praat: Doing phonetics by computer* [Computer program]. http://www.praat.org/
- Caspers, J., & van Heuven, V. J. (1993). Effects of time pressure on the phonetic realization of the Dutch accent-lending pitch rise and fall. *Phonetica, 50*(3), 161–171.
- Fougeron, C., & Jun, S.-A. (1998). Rate effects on French intonation: Prosodic organization and phonetic realization. *Journal of Phonetics, 26*(1), 45–69.
- 't Hart, J. (1981). Differential sensitivity to pitch distance, particularly in speech. *Journal of the Acoustical Society of America, 69*(3), 811–821.
- Ishihara, T. (2003). A phonological effect on tonal alignment in Tokyo Japanese. In *Proceedings of the 15th International Congress of Phonetic Sciences (ICPhS)*, Barcelona, 615–619.
- Jadoul, Y., Thompson, B., & de Boer, B. (2018). Introducing Parselmouth: A Python interface to Praat. *Journal of Phonetics, 71*, 1–15.
- Ladd, D. R. (2008). *Intonational Phonology* (2nd ed.). Cambridge University Press.
- Ladd, D. R., Faulkner, D., Faulkner, H., & Schepman, A. (1999). Constant "segmental anchoring" of F0 movements under changes in speech rate. *Journal of the Acoustical Society of America, 106*(3), 1543–1554.
- Maekawa, K. (2003). Corpus of Spontaneous Japanese: Its design and evaluation. In *Proc. ISCA & IEEE Workshop on Spontaneous Speech Processing and Recognition (SSPR)*, 7–12.
- Maekawa, K., Kikuchi, H., Igarashi, Y., & Venditti, J. (2002). X-JToBI: An extended J-ToBI for spontaneous speech. In *Proc. 7th International Conference on Spoken Language Processing (ICSLP)*, 1545–1548.
- Pierrehumbert, J. B. (1980). *The phonology and phonetics of English intonation* (Doctoral dissertation). MIT.
- Pitt, M. A., Dilley, L., Johnson, K., Kiesling, S., Raymond, W., Hume, E., & Fosler-Lussier, E. (2007). *Buckeye Corpus of Conversational Speech* (2nd release) [Data set]. Department of Psychology, Ohio State University.
- Wood, S. N. (2017). *Generalized Additive Models: An Introduction with R* (2nd ed.). Chapman & Hall/CRC.
