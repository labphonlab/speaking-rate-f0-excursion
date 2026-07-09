# F0range frame-count artifact check

Q: is rate->F0range just a sampling artifact (fewer frames in short vowels =>
downward-biased max-min)? Parts 1-2 below; the DECISIVE resampling test is
part 3 (src/artifact_resample.py, appended).

## Part 1 — Duration vs num_valid correlation
- CSJ Monologue  pearson r=0.918, spearman=0.913 (num_valid median=7, range 3-50)
- Buckeye        pearson r=0.886, spearman=0.871 (num_valid median=7, range 3-50)
- CSJ Dialogue   pearson r=0.916, spearman=0.888 (num_valid median=7, range 3-48)

## Part 2a — add s(num_valid) covariate (NOTE: near-collinear => concurvity high;
shrinkage is an UPPER bound on the artifact, not proof)
- CSJ Monologue  Duration eff 2.16 -> 1.16 st (shrink 46%), concurvity(Dur,num_valid)=0.98
- Buckeye        Duration eff 1.98 -> 1.01 st (shrink 49%), concurvity(Dur,num_valid)=0.97
- CSJ Dialogue   Duration eff 1.90 -> 0.39 st (shrink 80%), concurvity(Dur,num_valid)=0.97

## Part 2b — within a fixed num_valid band [5-7 frames], does Duration still predict F0range?
- CSJ Monologue  N=37845, Duration spread(5-95)=43ms, within-band Duration eff=0.46 st (p=0)
- Buckeye        N=91493, Duration spread(5-95)=69ms, within-band Duration eff=0.62 st (p=0)
- CSJ Dialogue   N=9578, Duration spread(5-95)=49ms, within-band Duration eff=0.33 st (p=0)

## interim verdict (parts 1-2): within a fixed frame-count band, Duration does NOT clearly predict F0range (eff falls below JND1.0 in all corpora).
Concurvity makes part-2a shrinkage only suggestive; part 3 (resampling) is decisive.

## log
    CSJ Monologue  cor(Duration,num_valid): pearson=0.918 spearman=0.913 (N=93156)
    CSJ Monologue  Duration eff: base=2.16 -> +s(num_valid)=1.16 st (shrink 46%); concurvity=0.98
    CSJ Monologue  band[num_valid 5-7]: N=37845, Duration spread(5-95)=43ms, within-band Duration eff=0.46 st (s(Duration) p=0)
    Buckeye        cor(Duration,num_valid): pearson=0.886 spearman=0.871 (N=274271)
    Buckeye        Duration eff: base=1.98 -> +s(num_valid)=1.01 st (shrink 49%); concurvity=0.97
    Buckeye        band[num_valid 5-7]: N=91493, Duration spread(5-95)=69ms, within-band Duration eff=0.62 st (s(Duration) p=0)
    CSJ Dialogue   cor(Duration,num_valid): pearson=0.916 spearman=0.888 (N=24734)
    CSJ Dialogue   Duration eff: base=1.90 -> +s(num_valid)=0.39 st (shrink 80%); concurvity=0.97
    CSJ Dialogue   band[num_valid 5-7]: N=9578, Duration spread(5-95)=49ms, within-band Duration eff=0.33 st (s(Duration) p=0)
    wrote Fig8_artifact_framecount.png

## Part 3 — DECISIVE resampling test (CSJ Monologue)

Long vowels (Duration>=p75, 23289 tokens) thinned to fast frame-counts (3-4, 100 contiguous draws each) vs real fast vowels (15885 tokens).

- median F0range: long_full=2.09 | thinned_pseudo=0.45 | fast_obs=0.80 st
- artifact_fraction = 1.27 (share of the long->fast range drop reproduced by thinning alone)
- residual_real_fraction = -0.27; KS(pseudo,fast) = 0.225

## VERDICT: MOSTLY ARTIFACT — thinning long vowels to fast frame-counts reproduces the small fast-vowel range: the rate->range effect is largely a sampling artifact.
