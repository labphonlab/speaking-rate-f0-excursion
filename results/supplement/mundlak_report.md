# Within/between (Mundlak) decomposition on landmark DVs

DV ~ Duration_Between + s(Duration_Within) + fs(Within,Speaker) + re(Vowel).
WITHIN = same speaker speeding up; BETWEEN = slow vs fast speakers.

## landmark excursion
- CSJ Monologue  within eff=1.73 st (clears JND1.0), dir=down_when_fast, within-slope=0.290 | between-slope=0.049 (p=0.97)
- Buckeye        within eff=1.44 st (clears JND1.0), dir=down_when_fast, within-slope=0.423 | between-slope=0.839 (p=0.28)
- CSJ Dialogue   within eff=1.38 st (clears JND1.0), dir=down_when_fast, within-slope=0.373 | between-slope=-0.386 (p=0.59)

## mechanism (F0 max vs min, within-speaker; sign>0 => rises when fast)
- CSJ Monologue: within max-sign=-0.14, min-sign=1.62 (min rises MORE than max => register-raising compression)
- Buckeye: within max-sign=-0.00, min-sign=1.45 (min rises MORE than max => register-raising compression)
- CSJ Dialogue: within max-sign=-0.03, min-sign=1.49 (min rises MORE than max => register-raising compression)

## verdict: WITHIN-SPEAKER rate effect on excursion is REAL and clears JND in every corpus — not a between-speaker confound.

## log
    CSJ Monologue  landmark_exc  within eff=1.73 slope=0.290 sign=-1.75 [down_when_fast] | between slope=0.049 (p=0.97) N=93151
    CSJ Monologue  landmark_max  within eff=0.58 slope=-0.651 sign=-0.14 [down_when_fast] | between slope=-10.852 (p=0.38) N=93156
    CSJ Monologue  landmark_min  within eff=1.60 slope=-0.937 sign=1.62 [up_when_fast] | between slope=-10.889 (p=0.38) N=93156
    Buckeye        landmark_exc  within eff=1.44 slope=0.423 sign=-1.46 [down_when_fast] | between slope=0.839 (p=0.28) N=274239
    Buckeye        landmark_max  within eff=0.21 slope=0.002 sign=-0.00 [flat] | between slope=-7.826 (p=0.25) N=274273
    Buckeye        landmark_min  within eff=1.42 slope=-0.415 sign=1.45 [up_when_fast] | between slope=-8.532 (p=0.21) N=274273
    CSJ Dialogue   landmark_exc  within eff=1.38 slope=0.373 sign=-1.41 [down_when_fast] | between slope=-0.386 (p=0.59) N=24732
    CSJ Dialogue   landmark_max  within eff=0.46 slope=-0.226 sign=-0.03 [down_when_fast] | between slope=4.332 (p=0.53) N=24734
    CSJ Dialogue   landmark_min  within eff=1.44 slope=-0.617 sign=1.49 [up_when_fast] | between slope=4.605 (p=0.51) N=24734
    wrote Fig7_mundlak.png
