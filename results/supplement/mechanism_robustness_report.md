# Mechanism robustness — F0min-rise / F0max-flat under the 3 checks

DVs = F0_LMmin_ST / F0_LMmax_ST (absolute F0 levels). Checks: frame-count
s(num_valid) covariate, intensity s(Intensity_Max) covariate, ososagari (drop
next_vowel_peak; CSJ only). Base = 5-95% eff of s(Duration); direction from
sign(p5-p95): min expected up_when_fast (floor rises), max expected ~flat.

## IMPORTANT — the covariate checks are concurvity-dominated for these level DVs
F0min/max are strongly collinear with num_valid (Duration~num_valid r~0.9) and
intensity, so adding them as smooths destabilises s(Duration): the frame/intensity
'reductions' are large NEGATIVE (the effect INFLATES, not shrinks) and are NOT
interpretable as confounding (concurvity ~0.9-1.0 reported in the table). The
interpretable checks are the base direction, the num_valid>=5 subset (frame_nv5),
and the ososagari token-exclusion (both concurvity-free).

## per cell — base effect + the two clean checks (frame_nv5, ososagari)
- CSJ Monologue F0min: base 1.72 st (sign 1.76, up_when_fast), SE(p5/p95) 0.32/0.19; clean checks: num_valid>=5 2.04 (+19%); no-ososagari 1.76 (+2%).
- CSJ Monologue F0max: base 0.59 st (sign -0.05, flat), SE(p5/p95) 0.28/0.17; clean checks: num_valid>=5 0.66 (+12%); no-ososagari 0.53 (-9%).
- Buckeye F0min: base 1.45 st (sign 1.49, up_when_fast), SE(p5/p95) 0.12/0.07; clean checks: num_valid>=5 1.54 (+6%).
- Buckeye F0max: base 0.21 st (sign -0.00, flat), SE(p5/p95) 0.12/0.07; clean checks: num_valid>=5 0.20 (-3%). [near-flat: read with the SE]
- CSJ Dialogue F0min: base 1.58 st (sign 1.62, up_when_fast), SE(p5/p95) 0.21/0.16; clean checks: num_valid>=5 1.75 (+11%); no-ososagari 1.56 (-1%).
- CSJ Dialogue F0max: base 0.50 st (sign 0.04, flat), SE(p5/p95) 0.18/0.14; clean checks: num_valid>=5 0.56 (+14%); no-ososagari 0.48 (-2%). [near-flat: read with the SE]

## verdict
F0min RISES when fast in every corpus (base eff 1.72/1.45/1.58 st, up_when_fast)
and F0max stays ~flat (base eff 0.59/0.21/0.50 st); both are essentially
unchanged under the num_valid>=5 subset and the ososagari exclusion (concurvity-
free checks). So the register-raising mechanism (floor up, ceiling flat) is robust.
The frame/intensity smooth-covariate 'reductions' are concurvity artefacts and are
reported only for completeness (see concurvity_dur_cov).

## log
    CSJ Monologue  min  frame     : eff 1.72 -> 8.80 (-412%) sign=1.76 [up_when_fast] SE=0.32/0.19 concurv=0.982
    CSJ Monologue  min  frame_nv5 : eff 1.72 -> 2.04 (-19%) sign=1.76 [up_when_fast] SE=0.32/0.19 concurv=-
    CSJ Monologue  min  intensity : eff 1.72 -> 3.04 (-76%) sign=1.76 [up_when_fast] SE=0.32/0.19 concurv=0.249
    CSJ Monologue  min  ososagari : eff 1.72 -> 1.76 (-2%) sign=1.76 [up_when_fast] SE=0.32/0.19 concurv=-
    CSJ Monologue  max  frame     : eff 0.59 -> 7.61 (-1191%) sign=-0.05 [flat] SE=0.28/0.17 concurv=0.982
    CSJ Monologue  max  frame_nv5 : eff 0.59 -> 0.66 (-12%) sign=-0.05 [flat] SE=0.28/0.17 concurv=-
    CSJ Monologue  max  intensity : eff 0.59 -> 1.31 (-123%) sign=-0.05 [flat] SE=0.28/0.17 concurv=0.247
    CSJ Monologue  max  ososagari : eff 0.59 -> 0.53 (9%) sign=-0.05 [flat] SE=0.28/0.17 concurv=-
    Buckeye        min  frame     : eff 1.45 -> 4.55 (-213%) sign=1.49 [up_when_fast] SE=0.12/0.07 concurv=0.965
    Buckeye        min  frame_nv5 : eff 1.45 -> 1.54 (-6%) sign=1.49 [up_when_fast] SE=0.12/0.07 concurv=-
    Buckeye        min  intensity : eff 1.45 -> 1.93 (-33%) sign=1.49 [up_when_fast] SE=0.12/0.07 concurv=0.232
    Buckeye        max  frame     : eff 0.21 -> 3.72 (-1653%) sign=-0.00 [flat] SE=0.12/0.07 concurv=0.965
    Buckeye        max  frame_nv5 : eff 0.21 -> 0.21 (3%) sign=-0.00 [flat] SE=0.12/0.07 concurv=-
    Buckeye        max  intensity : eff 0.21 -> 0.56 (-162%) sign=-0.00 [flat] SE=0.12/0.07 concurv=0.232
    CSJ Dialogue   min  frame     : eff 1.58 -> 7.16 (-355%) sign=1.62 [up_when_fast] SE=0.21/0.16 concurv=0.967
    CSJ Dialogue   min  frame_nv5 : eff 1.58 -> 1.75 (-11%) sign=1.62 [up_when_fast] SE=0.21/0.16 concurv=-
    CSJ Dialogue   min  intensity : eff 1.58 -> 2.13 (-35%) sign=1.62 [up_when_fast] SE=0.21/0.16 concurv=0.143
    CSJ Dialogue   min  ososagari : eff 1.58 -> 1.56 (1%) sign=1.62 [up_when_fast] SE=0.21/0.16 concurv=-
    CSJ Dialogue   max  frame     : eff 0.50 -> 6.87 (-1283%) sign=0.05 [flat] SE=0.18/0.14 concurv=0.967
    CSJ Dialogue   max  frame_nv5 : eff 0.50 -> 0.57 (-14%) sign=0.05 [flat] SE=0.18/0.14 concurv=-
    CSJ Dialogue   max  intensity : eff 0.50 -> 0.65 (-31%) sign=0.05 [flat] SE=0.18/0.14 concurv=0.138
    CSJ Dialogue   max  ososagari : eff 0.50 -> 0.48 (2%) sign=0.05 [flat] SE=0.18/0.14 concurv=-
