# F0range robustness report (measurement validity)

Excursion definitions compared: maxmin (12log2 max/min), maxmin_clean
(suspect f0_min dropped), p95p5 (12log2 p95/p5), winsor (per-speaker).
JND bands (config): static 0.5-1 / movement 1-1.5 st.

## per-corpus
- CSJ Monologue: all defs > JND1.0 = TRUE; spread = 19% of maxmin
- Buckeye: all defs > JND1.0 = TRUE; spread = 25% of maxmin
- CSJ Dialogue: all defs > JND1.0 = TRUE; spread = 25% of maxmin

## verdict: ROBUST — every definition clears JND 1.0 in every corpus.
## under the stricter movement band (>1.5 st): 2/15 cells dip below — Buckeye/landmark (1.48 st), CSJ Dialogue/landmark (1.44 st)

## log
    loaded master: 392163 rows; Flag_MinSuspect overall = 4.7%
    CSJ Monologue  maxmin  eff(5-95)=2.16 st slope=0.452 (N=93156 spk=31)
    CSJ Monologue  p95p5   eff(5-95)=1.83 st slope=0.273 (N=93156 spk=31)
    CSJ Monologue  winsor  eff(5-95)=2.16 st slope=0.447 (N=92952 spk=31)
    CSJ Monologue  landmark eff(5-95)=1.76 st slope=0.250 (N=93151 spk=31)
    CSJ Monologue  clean   eff(5-95)=2.03 st slope=0.347 (N=91726, dropped 1430 suspect)
    Buckeye        maxmin  eff(5-95)=1.98 st slope=0.557 (N=274271 spk=40)
    Buckeye        p95p5   eff(5-95)=1.63 st slope=0.396 (N=274271 spk=40)
    Buckeye        winsor  eff(5-95)=1.97 st slope=0.552 (N=273608 spk=40)
    Buckeye        landmark eff(5-95)=1.48 st slope=0.385 (N=274239 spk=40)
    Buckeye        clean   eff(5-95)=1.90 st slope=0.529 (N=258286, dropped 15985 suspect)
    CSJ Dialogue   maxmin  eff(5-95)=1.90 st slope=0.440 (N=24734 spk=18)
    CSJ Dialogue   p95p5   eff(5-95)=1.58 st slope=0.289 (N=24734 spk=18)
    CSJ Dialogue   winsor  eff(5-95)=1.92 st slope=0.442 (N=24672 spk=18)
    CSJ Dialogue   landmark eff(5-95)=1.44 st slope=0.237 (N=24732 spk=18)
    CSJ Dialogue   clean   eff(5-95)=1.83 st slope=0.434 (N=23784, dropped 950 suspect)
    wrote Fig3_robustness.png
