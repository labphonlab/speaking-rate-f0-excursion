#!/usr/bin/env python3
"""artifact_gate_lm.py — does the LANDMARK excursion remove the order-statistic
(frame-count) bias that inflates raw max-min?

Clean isolation of the COUNT effect from the SPAN effect: take well-sampled LONG
vowels and DOWNSAMPLE them to k frames while PRESERVING THE SPAN (k indices evenly
spaced across the whole vowel, not a contiguous slice). Recompute both measures.

  - raw max-min: with fewer samples, more likely to miss the true extremes -> drops.
  - landmark excursion (5 fixed proportional positions, interpolated): should be
    STABLE, because it does not rely on sample count, only on the contour spanned.

If raw drops a lot but landmark stays ~constant, the landmark DV removes the pure
count/order-statistic artifact (the residual landmark rate effect is then span-
driven = real undershoot, not undersampling). CSJ Monologue.

Output: results/supplement/artifact_gate_lm.csv  + console verdict.
Run: uv run python src/artifact_gate_lm.py
"""
from __future__ import annotations
import sys, pathlib
import numpy as np
import pandas as pd
import parselmouth as pm

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_dataset import make_pitch, CFG, _LANDMARK_PROPS

REPO = pathlib.Path(__file__).resolve().parents[1]
CORPUS, KEY, K_DS = "CSJ Monologue", "csj_mono", 4
RNG = np.random.default_rng(0)


def st_exc(vals):
    v = np.asarray(vals, float); v = v[v > 0]
    return float(12 * np.log2(v.max() / v.min())) if v.size >= 2 else np.nan


def lm_exc(tv, fv, t0, t1):
    """landmark excursion (ST) over [t0,t1] from voiced (tv,fv), clamped interp."""
    if tv.size < 2:
        return np.nan
    targ = t0 + np.asarray(_LANDMARK_PROPS) * (t1 - t0)
    return st_exc(np.interp(targ, tv, fv))


def main() -> int:
    m = pd.read_csv(REPO / CFG["paths"]["master_csv"], low_memory=False)
    d = m[(m["Dataset"] == CORPUS) & m["Duration"].notna() & m["num_valid"].notna()]
    p75 = d["Duration"].quantile(0.75)
    long_v = d[d["Duration"] >= p75]
    root = pathlib.Path(CFG["paths"]["raw"][KEY])
    raw_full, raw_ds, lm_full, lm_ds = [], [], [], []
    n_files = long_v["FileID"].nunique()
    for fi, (fid, grp) in enumerate(long_v.groupby("FileID"), 1):
        stem = str(fid)[:-4] if str(fid).endswith(".wav") else str(fid)
        wav = root / f"{stem}.wav"
        if not wav.exists():
            continue
        try:
            times, freqs = make_pitch(pm.Sound(str(wav)))
        except Exception:
            continue
        for _, r in grp.iterrows():
            mk = (times >= r["Tmin"]) & (times <= r["Tmax"])
            tv, fv = times[mk], freqs[mk]
            ok = fv > 0; tv, fv = tv[ok], fv[ok]
            if tv.size < 8:                    # need enough to downsample meaningfully
                continue
            # span-preserving downsample to K_DS evenly-spaced frames
            idx = np.linspace(0, tv.size - 1, K_DS).round().astype(int)
            tvd, fvd = tv[idx], fv[idx]
            raw_full.append(st_exc(fv));  raw_ds.append(st_exc(fvd))
            lm_full.append(lm_exc(tv, fv, r["Tmin"], r["Tmax"]))
            lm_ds.append(lm_exc(tvd, fvd, r["Tmin"], r["Tmax"]))
        if fi % 10 == 0:
            print(f"  {fi}/{n_files} files", flush=True)

    def med(a):
        a = np.asarray(a); return float(np.nanmedian(a))
    rf, rd, lf, ld = med(raw_full), med(raw_ds), med(lm_full), med(lm_ds)
    raw_drop = 100 * (rf - rd) / rf
    lm_drop = 100 * (lf - ld) / lf
    n = int(np.sum(np.isfinite(raw_full)))

    out = pd.DataFrame([
        {"measure": "raw_maxmin", "median_full": round(rf, 3), "median_downsampled_k4": round(rd, 3),
         "drop_pct": round(raw_drop, 1)},
        {"measure": "landmark_5pt", "median_full": round(lf, 3), "median_downsampled_k4": round(ld, 3),
         "drop_pct": round(lm_drop, 1)},
    ])
    out.to_csv(REPO / CFG["paths"]["supplement"] / "artifact_gate_lm.csv", index=False)
    print(f"\n{CORPUS}: {n} long vowels, span-preserving downsample to k={K_DS} frames")
    print(out.to_string(index=False))
    print(f"\nraw max-min drops {raw_drop:.0f}% when downsampled (order-statistic artifact).")
    print(f"landmark excursion drops {lm_drop:.0f}% (span preserved).")
    verdict = ("PASS — landmark removes most of the pure count bias"
               if lm_drop < 0.5 * raw_drop else
               "PARTIAL — landmark reduces but does not remove the count bias")
    print(f"GATE: {verdict}  (raw_drop={raw_drop:.0f}% vs lm_drop={lm_drop:.0f}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
