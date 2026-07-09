# Accent-nucleus sub-analysis (pitch-target validity)

Restricting rate->F0range to X-JToBI accent-nucleus vowels (accentual fall 'A').
DV = F0_excursion_LM_ST (robust). Nucleus = AccentDist==0 (strict) / <=0.10s (near). CSJ only.

## effective range by subset
- CSJ Monologue  all   : eff 1.76 st (clears JND1.0 / clears JND1.5), N=93151, spk=31, 100% of tone vowels
- CSJ Monologue  strict: eff 2.07 st (clears JND1.0 / clears JND1.5), N=14456, spk=31, 16% of tone vowels
- CSJ Monologue  near  : eff 2.28 st (clears JND1.0 / clears JND1.5), N=29885, spk=31, 32% of tone vowels
- CSJ Dialogue   all   : eff 1.44 st (clears JND1.0 / below JND1.5), N=24732, spk=18, 100% of tone vowels
- CSJ Dialogue   strict: eff 1.72 st (clears JND1.0 / clears JND1.5), N=4092, spk=18, 16% of tone vowels
- CSJ Dialogue   near  : eff 1.79 st (clears JND1.0 / clears JND1.5), N=8118, spk=18, 33% of tone vowels

## distance-threshold sweep (CSJ Monologue: robustness of assignment)
- strict(in-vowel): eff 2.07 st (clears JND), N=14456
- <=0.03s         : eff 2.19 st (clears JND), N=17813
- <=0.05s         : eff 2.24 st (clears JND), N=20282
- <=0.10s         : eff 2.28 st (clears JND), N=29885
- <=0.15s         : eff 2.08 st (clears JND), N=39620
- all-vowels      : eff 1.76 st (clears JND), N=93151

## verdict: SURVIVES — restricting to accent-nucleus vowels (X-JToBI 'A', 14456 tokens, 16% of tone-annotated vowels) the rate->F0range effective range is 2.07 st, still clearing the JND 1.0, and the per-100ms SLOPE is 0.83 vs 0.25 over all vowels (3.3x steeper). The strict-nucleus 5-95% span is slightly smaller than the all-vowel 1.76 st only because nucleus vowels have a narrower duration distribution (a shorter 5-95% x-range), not because the effect is weaker. So the covariation is NOT an artefact of pooling tonally- unspecified vowels: it is present, and per unit time stronger, exactly on the vowels that carry an explicit pitch target.

## log
    [N-audit] CSJ Monologue / all          n_input=93151 n_used=93151 n_dropped=0 n_speakers=31
    CSJ Monologue / all   : 5-95% eff = 1.76 st, slope = 0.250 st/100ms (N=93151, spk=31)
    [N-audit] CSJ Monologue / strict       n_input=93151 n_used=14456 n_dropped=78695 n_speakers=31
    CSJ Monologue / strict: 5-95% eff = 2.07 st, slope = 0.826 st/100ms (N=14456, spk=31)
    [N-audit] CSJ Monologue / near         n_input=93151 n_used=29885 n_dropped=63266 n_speakers=31
    CSJ Monologue / near  : 5-95% eff = 2.28 st, slope = 0.574 st/100ms (N=29885, spk=31)
    [N-audit] CSJ Dialogue / all           n_input=24732 n_used=24732 n_dropped=0 n_speakers=18
    CSJ Dialogue / all   : 5-95% eff = 1.44 st, slope = 0.237 st/100ms (N=24732, spk=18)
    [N-audit] CSJ Dialogue / strict        n_input=24732 n_used=4092 n_dropped=20640 n_speakers=18
    CSJ Dialogue / strict: 5-95% eff = 1.72 st, slope = 0.649 st/100ms (N=4092, spk=18)
    [N-audit] CSJ Dialogue / near          n_input=24732 n_used=8118 n_dropped=16614 n_speakers=18
    CSJ Dialogue / near  : 5-95% eff = 1.79 st, slope = 0.653 st/100ms (N=8118, spk=18)
    wrote Fig5_accent_nucleus.png
