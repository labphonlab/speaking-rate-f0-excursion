#!/usr/bin/env python3
"""channel_naive_check.py — how many CSJ-Dialogue tokens does the NAIVE
two-channel treatment add as a phantom second speaker?

Background: the manuscript states that the naive two-channel
treatment admitted "~4,316 invalid cross-channel tokens as a spurious second
speaker". That 4,316 is actually just (old-manuscript CSJ-D count 25,874) minus
(current count 21,558) — a net difference between two different pipelines, NOT a
measured phantom-speaker count. This script measures the real thing: it applies the
SAME vowel intervals + SAME filters to BOTH channels of every session and compares
the naive total (L+R) with the current dominant-channel-only total.

  naive_total     = tokens(L) + tokens(R)   (both channels as 'two speakers')
  dominant_total  = tokens(dominant channel)   (current design; ~= master's 21,558)
  phantom (added) = naive_total - dominant_total = tokens(non-dominant channel)

Output: results/supplement/TableS_channel_naive_check.csv + console summary.
Run: uv run python src/channel_naive_check.py
"""
from __future__ import annotations
import sys, pathlib
import numpy as np
import pandas as pd

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import parselmouth as pm
from build_dataset import (make_pitch, analyze_pitch, norm_csj, _dominant_channel,
                           CFG)
from diagnose_data import parse_textgrid, nth_interval_tier

REPO = pathlib.Path(__file__).resolve().parents[1]
ROOT = pathlib.Path(CFG["paths"]["raw"]["csj_dial"])
VJP = set(CFG["vowels"]["jp"])
PAUSE = {p.lower() for p in CFG["pause_labels"]}
F = CFG["filtering"]


def count_channel(wav, seg_ivs):
    """vowel tokens surviving the standard filters on one channel wav."""
    snd = pm.Sound(str(wav)); times, freqs = make_pitch(snd)
    kept = 0
    for s, e, raw in seg_ivs:
        if norm_csj(raw) not in VJP:
            continue
        dur = e - s
        st = analyze_pitch(times, freqs, s, e)
        # same exclusion rule as build_dataset.apply_filters
        bad = (not (F["dur_min"] <= dur <= F["dur_max"])) or st["num_valid"] == 0 \
            or (0 < st["num_valid"] < F["min_valid_frames"]) or bool(st["has_jump"])
        if not bad:
            kept += 1
    return kept


def main() -> int:
    stems = sorted(p.stem for p in ROOT.glob("*.TextGrid"))
    rows = []
    for i, stem in enumerate(stems, 1):
        tiers = parse_textgrid(ROOT / f"{stem}.TextGrid")
        hit = nth_interval_tier(tiers, 2)
        if hit is None:
            continue
        seg = hit[1]
        dom_ch, res = _dominant_channel(ROOT, stem, seg, PAUSE)
        if dom_ch is None:
            continue
        nL = count_channel(ROOT / f"{stem}-L.wav", seg.intervals)
        nR = count_channel(ROOT / f"{stem}-R.wav", seg.intervals)
        dom = nL if dom_ch == "L" else nR
        rows.append({"session": stem, "dominant_channel": dom_ch,
                     "tokens_L": nL, "tokens_R": nR,
                     "tokens_dominant": dom, "tokens_nondominant": (nL + nR) - dom})
        print(f"  {i}/{len(stems)} {stem}: L={nL} R={nR} dom={dom_ch}({dom})", flush=True)

    df = pd.DataFrame(rows)
    df.to_csv(REPO / CFG["paths"]["supplement"] / "TableS_channel_naive_check.csv", index=False)
    naive = int(df["tokens_L"].sum() + df["tokens_R"].sum())
    dom = int(df["tokens_dominant"].sum())
    phantom = naive - dom
    print("\n===== CSJ Dialogue channel comparison (post-filter tokens) =====")
    print(f"  sessions:            {len(df)}")
    print(f"  naive (L+R) total:   {naive}")
    print(f"  dominant-only total: {dom}   (master CSJ-D final = 21,558)")
    print(f"  phantom (non-dominant channel) = naive - dominant = {phantom}")
    print(f"  phantom as % of naive: {100*phantom/naive:.1f}%")
    print(f"\n  For reference, the docs' '4,316' = 25,874 (old-manuscript N) - 21,558 (current).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
