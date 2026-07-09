# Peak-delay / ososagari check (does landmark excursion miss the peak?)

Ishihara (2003, ICPhS 15, Barcelona, 615-619): CVCV word-initial accents realise
the F0 peak at the onset of the SECOND-syllable vowel (peak skips the accented
mora); CVN: no delay; F(2,90)=31.417, p<.0001. We quantify via X-JToBI 'A' points.
Adjacency gap for 'next vowel' = 0.15s. Buckeye excluded (no tone tier).

## A1 — where does the X-JToBI 'A' point fall (per corpus)
- CSJ Monologue: A_in_current 15.5% | **A_in_next_vowel 11.5%** (ososagari) | neither 73.0%
- CSJ Dialogue: A_in_current 16.5% | **A_in_next_vowel 10.7%** (ososagari) | neither 72.7%

## A2 — next_vowel_peak vs Duration
- CSJ Monologue: median Duration all 0.073 vs next_vowel_peak 0.068 s (shorter vowels tend to be pre-nuclear).
- CSJ Dialogue: median Duration all 0.074 vs next_vowel_peak 0.067 s (shorter vowels tend to be pre-nuclear).

## A3 — landmark excursion under-capture (vowel alone vs vowel+next vowel)
- CSJ Monologue (N=10689): current 0.89 -> concat 2.36 st, **median under-capture 1.26 st**.
- CSJ Dialogue (N=2648): current 0.91 -> concat 2.20 st, **median under-capture 1.01 st**.

## A4 — impact on the headline landmark effect (5-95% eff)
- CSJ Monologue: all 1.76 | excl next_vowel_peak 1.79 | only next_vowel_peak 1.11 st.
- CSJ Dialogue: all 1.44 | excl next_vowel_peak 1.44 | only next_vowel_peak 1.10 st.

## A5 — interpretive note on the accent-nucleus-strict analysis (no correction)
The current AccentNucleus = AccentDist==0 flags the vowel that CONTAINS an 'A'
point. Under CVCV ososagari the 'A' lands in the SECOND-syllable vowel, so
'strict nucleus' partly tags the post-accentual vowel where the peak is realised,
not the lexically accented mora. The strict-nucleus effect (Mono 1.27 / Dial 1.03
st) should therefore be read as 'vowels that carry the realised accentual fall',
which for CVCV is the second-syllable vowel; the rate->excursion conclusion is
unaffected (both the accent-bearing and peak-bearing vowels show the effect), but
the phonological labelling of WHICH vowel is 'the nucleus' is approximate.

## log
    CSJ Monologue: A_in_current 15.5% | A_in_next_vowel 11.5% | neither 73.0% (N=93151)
      CSJ Monologue: median Duration all=0.073 vs next_vowel_peak=0.068 s; next_vowel_peak share short-tertile=13.7% vs long-tertile=8.4%
      A3 concat excursion (next_vowel_peak, N=10689): current 0.89 -> concat 2.36 st (median under-capture 1.26 st)
      A4 landmark eff(5-95): all=1.76 | excl next_vowel_peak=1.79 | only next_vowel_peak=1.11 st
    CSJ Dialogue: A_in_current 16.5% | A_in_next_vowel 10.7% | neither 72.7% (N=24732)
      CSJ Dialogue: median Duration all=0.074 vs next_vowel_peak=0.067 s; next_vowel_peak share short-tertile=13.0% vs long-tertile=7.4%
      A3 concat excursion (next_vowel_peak, N=2648): current 0.91 -> concat 2.20 st (median under-capture 1.01 st)
      A4 landmark eff(5-95): all=1.44 | excl next_vowel_peak=1.44 | only next_vowel_peak=1.10 st
