#!/usr/bin/env python3
"""artifact_resample.py — DECISIVE frame-count artifact test (part 3).

Q: is the rate->F0range effect a sampling artifact? A short vowel has few voiced
F0 frames; max-min over few samples is downward-biased. If we take LONG vowels
(which have many frames and a fully-sampled F0 trajectory) and THIN them to the
frame count of a fast vowel, do we reproduce the small range seen in real fast
vowels? If yes -> artifact. If the thinned-long range stays LARGER than the real
fast range -> fast vowels are genuinely flatter (real undershoot), not just
under-sampled.

Method (CSJ Monologue; cleanest single-wav corpus, exact Tmin/Tmax in master):
  - LONG vowels  = Duration >= 75th percentile (many frames, full trajectory).
  - FAST vowels  = num_valid in FAST_FRAMES (few frames = fastest).
  - Re-extract each long vowel's voiced-frame F0 (same pitch settings as build).
  - For each long vowel, 100x: draw a CONTIGUOUS window of k frames (k sampled
    from the real fast-vowel num_valid distribution), pseudo-range = 12log2(max/min).
  - Compare distributions: full-long range vs thinned-long (pseudo) vs real fast.
  - artifact_fraction = (median_long - median_pseudo) / (median_long - median_fast)
    ~1 => the long->fast range drop is reproduced by thinning alone (artifact);
    <1 => a residual REAL rate effect survives (median_pseudo > median_fast).

Outputs: results/supplement/artifact_resample.csv
         appends a section to results/supplement/artifact_check_report.md
Run: uv run python src/artifact_resample.py
"""
from __future__ import annotations
import sys, pathlib
import numpy as np
import pandas as pd
import parselmouth  # noqa: F401  (used via build_dataset.make_pitch)

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_dataset import make_pitch, CFG          # reuse identical pitch settings
import parselmouth as pm

REPO = pathlib.Path(__file__).resolve().parents[1]
CORPUS = "CSJ Monologue"
CORPUS_KEY = "csj_mono"
FAST_FRAMES = (3, 4)          # "fast vowel" frame counts (the artifact-suspect end)
N_DRAWS = 100                 # subsamples per long vowel
RNG = np.random.default_rng(0)


def st_range(v: np.ndarray) -> float:
    """Excursion in semitones over a set of voiced F0 samples (all > 0)."""
    return float(12.0 * np.log2(v.max() / v.min())) if v.size >= 2 and v.min() > 0 else np.nan


def main() -> int:
    master = pd.read_csv(REPO / CFG["paths"]["master_csv"])
    d = master[(master["Dataset"] == CORPUS) &
               master["F0_range_ST"].notna() &
               master["Duration"].notna() & master["num_valid"].notna()].copy()
    if d.empty:
        print("ERROR: no CSJ Monologue rows with Tmin/Tmax; rebuild master first.")
        return 1
    if "Tmin" not in d.columns:
        print("ERROR: master lacks Tmin/Tmax; re-run build_dataset.py.")
        return 1

    p75 = d["Duration"].quantile(0.75)
    long_v = d[d["Duration"] >= p75].copy()
    fast_v = d[d["num_valid"].between(*FAST_FRAMES)].copy()
    k_pool = fast_v["num_valid"].to_numpy()
    if k_pool.size == 0:
        print("ERROR: no fast vowels in the frame band", FAST_FRAMES)
        return 1
    print(f"{CORPUS}: N={len(d)}  long(>=p75, dur>={p75:.3f}s)={len(long_v)}  "
          f"fast(num_valid {FAST_FRAMES[0]}-{FAST_FRAMES[1]})={len(fast_v)}", flush=True)

    root = pathlib.Path(CFG["paths"]["raw"][CORPUS_KEY])
    pseudo = []           # thinned-long pseudo-range (ST)
    n_files = long_v["FileID"].nunique()
    used_long = 0
    for fi, (fid, grp) in enumerate(long_v.groupby("FileID"), 1):
        stem = str(fid)[:-4] if str(fid).endswith(".wav") else str(fid)
        wav = root / f"{stem}.wav"
        if not wav.exists():
            print(f"  skip {stem}: wav missing", flush=True); continue
        try:
            snd = pm.Sound(str(wav)); times, freqs = make_pitch(snd)
        except Exception as e:
            print(f"  skip {stem}: {type(e).__name__}: {e}", flush=True); continue
        for _, r in grp.iterrows():
            v = freqs[(times >= r["Tmin"]) & (times <= r["Tmax"])]
            v = v[v > 0]
            if v.size < FAST_FRAMES[1] + 1:      # need enough frames to thin
                continue
            used_long += 1
            ks = RNG.choice(k_pool, size=N_DRAWS)
            for k in ks:
                k = int(min(k, v.size))
                start = int(RNG.integers(0, v.size - k + 1))
                pseudo.append(st_range(v[start:start + k]))
        if fi % 5 == 0:
            print(f"  {fi}/{n_files} files, {used_long} long vowels used", flush=True)

    pseudo = np.asarray([x for x in pseudo if np.isfinite(x)])
    obs_fast = fast_v["F0_range_ST"].to_numpy()
    obs_long = long_v["F0_range_ST"].to_numpy()

    def q(a):
        return dict(n=int(a.size), mean=float(np.mean(a)), median=float(np.median(a)),
                    p25=float(np.percentile(a, 25)), p75=float(np.percentile(a, 75)))
    Q = {"long_observed_full": q(obs_long), "long_thinned_pseudo": q(pseudo),
         "fast_observed": q(obs_fast)}

    m_long, m_pseudo, m_fast = Q["long_observed_full"]["median"], \
        Q["long_thinned_pseudo"]["median"], Q["fast_observed"]["median"]
    total_drop = m_long - m_fast
    artifact_frac = (m_long - m_pseudo) / total_drop if total_drop != 0 else np.nan
    residual_frac = (m_pseudo - m_fast) / total_drop if total_drop != 0 else np.nan

    # manual KS statistic (no scipy): max |ECDF_pseudo - ECDF_fast|
    grid = np.linspace(min(pseudo.min(), obs_fast.min()),
                       max(pseudo.max(), obs_fast.max()), 400)
    ecdf = lambda a: np.searchsorted(np.sort(a), grid, side="right") / a.size
    ks_stat = float(np.max(np.abs(ecdf(pseudo) - ecdf(obs_fast))))

    rows = []
    for name, s in Q.items():
        rows.append({"distribution": name, **{k: round(v, 4) if isinstance(v, float) else v
                                              for k, v in s.items()}})
    out = pd.DataFrame(rows)
    out.to_csv(REPO / CFG["paths"]["supplement"] / "artifact_resample.csv", index=False)

    print("\n== distributions (F0range, semitones) ==")
    print(out.to_string(index=False))
    print(f"\nmedian: long_full={m_long:.3f}  thinned_pseudo={m_pseudo:.3f}  fast_obs={m_fast:.3f} st")
    print(f"artifact_fraction (long->fast drop reproduced by thinning) = {artifact_frac:.2f}")
    print(f"residual_real_fraction (thinned still above fast)          = {residual_frac:.2f}")
    print(f"KS(pseudo, fast) = {ks_stat:.3f}  (0=identical distributions)")

    verdict = ("MOSTLY ARTIFACT" if artifact_frac >= 0.8 else
               "MOSTLY REAL" if artifact_frac <= 0.4 else "MIXED")
    concl = {
        "MOSTLY ARTIFACT": ("thinning long vowels to fast frame-counts reproduces the "
            "small fast-vowel range: the rate->range effect is largely a sampling artifact."),
        "MIXED": ("thinning reproduces PART of the long->fast range drop; a residual real "
            "component survives (thinned-long range stays above real fast range)."),
        "MOSTLY REAL": ("even thinned to fast frame-counts, long vowels keep a LARGER range "
            "than real fast vowels: fast vowels are genuinely flatter -> real rate effect, "
            "not a frame-count artifact."),
    }[verdict]

    # append to the R report
    rep_path = REPO / CFG["paths"]["supplement"] / "artifact_check_report.md"
    extra = [
        "", "## Part 3 — DECISIVE resampling test (CSJ Monologue)", "",
        f"Long vowels (Duration>=p75, {Q['long_observed_full']['n']} tokens) thinned to fast "
        f"frame-counts ({FAST_FRAMES[0]}-{FAST_FRAMES[1]}, {N_DRAWS} contiguous draws each) vs "
        f"real fast vowels ({Q['fast_observed']['n']} tokens).",
        "",
        f"- median F0range: long_full={m_long:.2f} | thinned_pseudo={m_pseudo:.2f} | fast_obs={m_fast:.2f} st",
        f"- artifact_fraction = {artifact_frac:.2f} (share of the long->fast range drop reproduced by thinning alone)",
        f"- residual_real_fraction = {residual_frac:.2f}; KS(pseudo,fast) = {ks_stat:.3f}",
        "",
        f"## VERDICT: {verdict} — {concl}",
    ]
    with open(rep_path, "a") as f:
        f.write("\n".join(extra) + "\n")
    print(f"\nVERDICT: {verdict}\nappended to {rep_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
