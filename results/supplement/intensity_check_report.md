# Intensity-confound check (is rate->excursion just loudness scaling?)

DV = F0_excursion_LM_ST (primary) & F0_range_ST (raw). Covariate = s(Intensity_Max/Mean).

## descriptive intensity (dB) per corpus
- CSJ Monologue  Intensity_Max 69.4±5.5 dB; Intensity_Mean 67.3±5.6 dB
- Buckeye        Intensity_Max 65.5±6.8 dB; Intensity_Mean 63.6±6.8 dB
- CSJ Dialogue   Intensity_Max 67.0±5.6 dB; Intensity_Mean 64.8±5.6 dB

## primary verdict — landmark DV, all vowels, Intensity_Max control
- CSJ Monologue: intensity control -> Duration eff 1.76 -> 1.69 ST (4% reduction; cor(dur,int)=0.06, concurvity=NA). [F0/pitch-target specific (NOT intensity)]
- Buckeye: intensity control -> Duration eff 1.48 -> 1.42 ST (4% reduction; cor(dur,int)=0.04, concurvity=NA). [F0/pitch-target specific (NOT intensity)]
- CSJ Dialogue: intensity control -> Duration eff 1.44 -> 1.38 ST (4% reduction; cor(dur,int)=0.07, concurvity=NA). [F0/pitch-target specific (NOT intensity)]

## accent-nucleus strict (landmark DV, Intensity_Max)
- CSJ Monologue: 2.07 -> 2.00 ST (3% red). [F0/pitch-target specific (NOT intensity)]
- CSJ Dialogue: 1.72 -> 1.64 ST (5% red). [F0/pitch-target specific (NOT intensity)]

NB: Duration and intensity are correlated, so a with-intensity model splits shared
variance; concurvity is reported. A SMALL reduction is strong evidence the effect is
not mere loudness scaling; interpret a large reduction together with concurvity.

## full table: TableS_intensity_check.csv (all DV x subset x intensity measure)

## log
    CSJ Monologue  all                   F0_range_ST        / Intensity_Max : eff 2.16 -> 2.09 (3% red), cor(dur,int)=0.06
    CSJ Monologue  all                   F0_range_ST        / Intensity_Mean: eff 2.16 -> 2.18 (-1% red), cor(dur,int)=-0.05
    CSJ Monologue  all                   F0_excursion_LM_ST / Intensity_Max : eff 1.76 -> 1.69 (4% red), cor(dur,int)=0.06
    CSJ Monologue  all                   F0_excursion_LM_ST / Intensity_Mean: eff 1.76 -> 1.78 (-1% red), cor(dur,int)=-0.05
    CSJ Monologue  accent_nucleus_strict F0_range_ST        / Intensity_Max : eff 2.56 -> 2.48 (3% red), cor(dur,int)=0.12
    CSJ Monologue  accent_nucleus_strict F0_range_ST        / Intensity_Mean: eff 2.56 -> 2.56 (0% red), cor(dur,int)=0.02
    CSJ Monologue  accent_nucleus_strict F0_excursion_LM_ST / Intensity_Max : eff 2.07 -> 2.00 (3% red), cor(dur,int)=0.12
    CSJ Monologue  accent_nucleus_strict F0_excursion_LM_ST / Intensity_Mean: eff 2.07 -> 2.07 (0% red), cor(dur,int)=0.02
    Buckeye        all                   F0_range_ST        / Intensity_Max : eff 1.98 -> 1.91 (4% red), cor(dur,int)=0.04
    Buckeye        all                   F0_range_ST        / Intensity_Mean: eff 1.98 -> 2.04 (-3% red), cor(dur,int)=-0.07
    Buckeye        all                   F0_excursion_LM_ST / Intensity_Max : eff 1.48 -> 1.42 (4% red), cor(dur,int)=0.04
    Buckeye        all                   F0_excursion_LM_ST / Intensity_Mean: eff 1.48 -> 1.54 (-3% red), cor(dur,int)=-0.07
    CSJ Dialogue   all                   F0_range_ST        / Intensity_Max : eff 1.90 -> 1.83 (4% red), cor(dur,int)=0.07
    CSJ Dialogue   all                   F0_range_ST        / Intensity_Mean: eff 1.90 -> 2.02 (-6% red), cor(dur,int)=-0.07
    CSJ Dialogue   all                   F0_excursion_LM_ST / Intensity_Max : eff 1.44 -> 1.38 (4% red), cor(dur,int)=0.07
    CSJ Dialogue   all                   F0_excursion_LM_ST / Intensity_Mean: eff 1.44 -> 1.54 (-7% red), cor(dur,int)=-0.07
    CSJ Dialogue   accent_nucleus_strict F0_range_ST        / Intensity_Max : eff 2.19 -> 2.10 (4% red), cor(dur,int)=0.12
    CSJ Dialogue   accent_nucleus_strict F0_range_ST        / Intensity_Mean: eff 2.19 -> 2.25 (-3% red), cor(dur,int)=-0.01
    CSJ Dialogue   accent_nucleus_strict F0_excursion_LM_ST / Intensity_Max : eff 1.72 -> 1.64 (5% red), cor(dur,int)=0.12
    CSJ Dialogue   accent_nucleus_strict F0_excursion_LM_ST / Intensity_Mean: eff 1.72 -> 1.77 (-3% red), cor(dur,int)=-0.01
    wrote Fig_intensity_control.png
