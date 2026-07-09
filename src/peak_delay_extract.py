#!/usr/bin/env python3
"""peak_delay_extract.py — ososagari check, Analysis 3 support (frame-level).

Ishihara, T. (2003). A phonological effect on tonal alignment in Tokyo Japanese.
Proc. 15th ICPhS, Barcelona, 615-619. — CV+CV/CVCV word-initial accented
sequences: the F0 peak aligns at the ONSET OF THE SECOND-SYLLABLE VOWEL in nearly
all cases (peak "skips" the accented mora); CVN sequences: no delay, peak near end
of the first mora; CVR/CVV: peak realised within the long vowel/diphthong
(F(2,90)=31.417, p<.0001).

Consequence: for CVCV ososagari, the accent's F0 peak is realised OUTSIDE the
accented vowel — so the landmark excursion (10-90% inside that vowel) may measure a
span that never contains the true peak. We quantify this using the X-JToBI
accentual-fall points 'A'/'Ax' already used for AccentDist: for each vowel we ask
whether the A point sits inside it (AccentDist==0), inside the *immediately
following* vowel (= next_vowel_peak, the ososagari signature), or neither.

This script does the frame-level part (Analysis 3): for next_vowel_peak vowels it
re-extracts the file F0 and compares the landmark excursion of the vowel ALONE
[Tmin_i, Tmax_i] vs the CONCATENATED interval [Tmin_i, Tmax_next] (vowel + the
following vowel where the peak actually lands), in semitones. It also writes the
group label for EVERY CSJ vowel so 12_peak_delay_check.R uses one classification.

Output: results/supplement/peak_delay_tokens.csv
Run: uv run python src/peak_delay_extract.py
"""
from __future__ import annotations
import sys, pathlib
import numpy as np
import pandas as pd
import parselmouth as pm

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from build_dataset import make_pitch, landmark_f0, CFG

REPO = pathlib.Path(__file__).resolve().parents[1]
ADJ_GAP = 0.15          # s: max gap (next vowel onset - current offset) to count as the adjacent mora
CORPORA = {"CSJ Monologue": "csj_mono", "CSJ Dialogue": "csj_dial"}


def lm_exc_st(times, freqs, s, e):
    mn, mx, n = landmark_f0(times, freqs, s, e)
    return float(12 * np.log2(mx / mn)) if n >= 2 and mn > 0 and mx > mn else np.nan


def wav_path(dataset, speaker, channel):
    if dataset == "CSJ Monologue":
        return pathlib.Path(CFG["paths"]["raw"]["csj_mono"]) / f"{speaker}.wav"
    ch = str(channel) if channel not in (None, "", "NA") else "R"
    return pathlib.Path(CFG["paths"]["raw"]["csj_dial"]) / f"{speaker}-{ch}.wav"


def main() -> int:
    m = pd.read_csv(REPO / CFG["paths"]["master_csv"], low_memory=False)
    m = m[m["Dataset"].isin(CORPORA) & m["AccentDist"].notna()].copy()
    m["Tmin"] = m["Tmin"].astype(float); m["Tmax"] = m["Tmax"].astype(float)

    out_rows = []
    for (dataset, speaker), g in m.groupby(["Dataset", "Speaker"]):
        g = g.sort_values("Tmin").reset_index(drop=True)
        ad = g["AccentDist"].to_numpy()
        tmin = g["Tmin"].to_numpy(); tmax = g["Tmax"].to_numpy()
        n = len(g)
        # classify every vowel
        group = np.full(n, "neither", dtype=object)
        nxt_tmin = np.full(n, np.nan); nxt_tmax = np.full(n, np.nan)
        for i in range(n):
            if ad[i] == 0:
                group[i] = "A_in_current"; continue
            if i + 1 < n and (tmin[i + 1] - tmax[i]) <= ADJ_GAP and (tmin[i + 1] - tmax[i]) >= -1e-6:
                if ad[i + 1] == 0:
                    group[i] = "A_in_next_vowel"; nxt_tmin[i] = tmin[i + 1]; nxt_tmax[i] = tmax[i + 1]
        # frame-level concat excursion for the g2 (next_vowel_peak) tokens
        lm_cur = np.full(n, np.nan); lm_cat = np.full(n, np.nan)
        if (group == "A_in_next_vowel").any():
            ch = g["Channel"].iloc[0] if "Channel" in g else None
            wav = wav_path(dataset, speaker, ch)
            if wav.exists():
                try:
                    times, freqs = make_pitch(pm.Sound(str(wav)))
                    for i in np.where(group == "A_in_next_vowel")[0]:
                        lm_cur[i] = lm_exc_st(times, freqs, tmin[i], tmax[i])
                        lm_cat[i] = lm_exc_st(times, freqs, tmin[i], nxt_tmax[i])
                except Exception as e:
                    print(f"  skip {speaker}: {type(e).__name__}: {e}", flush=True)
            else:
                print(f"  missing wav: {wav}", flush=True)
        sub = g[["Dataset", "Speaker", "Tmin", "Tmax", "Duration", "NextSeg",
                 "AccentDist", "F0_excursion_LM_ST"]].copy()
        sub["group"] = group; sub["next_tmax"] = nxt_tmax
        sub["lm_exc_current"] = lm_cur; sub["lm_exc_concat"] = lm_cat
        out_rows.append(sub)

    out = pd.concat(out_rows, ignore_index=True)
    out.to_csv(REPO / CFG["paths"]["supplement"] / "peak_delay_tokens.csv", index=False)

    # console summary
    print(f"ADJ_GAP = {ADJ_GAP}s; classified {len(out)} CSJ vowels")
    for ds in CORPORA:
        d = out[out["Dataset"] == ds]
        vc = d["group"].value_counts(normalize=True)
        g2 = d[d["group"] == "A_in_next_vowel"]
        gap = (g2["lm_exc_concat"] - g2["lm_exc_current"]).dropna()
        print(f"\n{ds} (N={len(d)}):")
        for k in ("A_in_current", "A_in_next_vowel", "neither"):
            print(f"  {k:16s}: {100*vc.get(k,0):.1f}%")
        if len(gap):
            print(f"  Analysis 3 (next_vowel_peak, N={len(gap)}): landmark excursion "
                  f"current {g2['lm_exc_current'].median():.2f} -> concat "
                  f"{g2['lm_exc_concat'].median():.2f} st (median under-capture "
                  f"{gap.median():.2f} st)")
    print(f"\nwrote {REPO / CFG['paths']['supplement'] / 'peak_delay_tokens.csv'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
