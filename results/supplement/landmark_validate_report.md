# Landmark-excursion validation (frame-count-robust DV)

Raw max-min vs fixed-landmark excursion, same GAMM, per corpus.

- CSJ Monologue  eff: raw 2.16 -> landmark 1.76 st (19% smaller); landmark clears JND1.0, clears JND1.5; dir=shrinks_when_fast
- Buckeye        eff: raw 1.98 -> landmark 1.48 st (25% smaller); landmark clears JND1.0, below JND1.5; dir=shrinks_when_fast
- CSJ Dialogue   eff: raw 1.90 -> landmark 1.44 st (24% smaller); landmark clears JND1.0, below JND1.5; dir=shrinks_when_fast

See artifact_resample.py (--lm) for the decisive resampling artifact_fraction on the landmark DV.

## log
    CSJ Monologue  raw_range eff=2.16 st slope=0.452 sign=-2.19 [shrinks_when_fast] cor(nv,DV)=0.39 (N=93156)
    CSJ Monologue  landmark  eff=1.76 st slope=0.250 sign=-1.78 [shrinks_when_fast] cor(nv,DV)=0.31 (N=93151)
    Buckeye        raw_range eff=1.98 st slope=0.557 sign=-2.01 [shrinks_when_fast] cor(nv,DV)=0.38 (N=274271)
    Buckeye        landmark  eff=1.48 st slope=0.385 sign=-1.51 [shrinks_when_fast] cor(nv,DV)=0.31 (N=274239)
    CSJ Dialogue   raw_range eff=1.90 st slope=0.440 sign=-1.93 [shrinks_when_fast] cor(nv,DV)=0.44 (N=24734)
    CSJ Dialogue   landmark  eff=1.44 st slope=0.237 sign=-1.46 [shrinks_when_fast] cor(nv,DV)=0.36 (N=24732)
