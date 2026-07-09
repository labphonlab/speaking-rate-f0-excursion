#!/usr/bin/env python3
"""build_dataset.py — extract -> combine -> filter -> features -> master_csv.

Ported from the old Colab notebook (Cells 1-3) with the CLAUDE.md mandatory
fixes applied:
  * No Google Drive mount / sync_data_to_local — read raw locally from config.
  * Octave-jump detection follows config.jump_method (Hz-based per the paper),
    not the old ratio-only heuristic.
  * analyze_pitch returns f0_max/min/mean/range (not just max).
  * No silent `except: continue` — every failure is logged to a failures file
    so extraction gaps are auditable afterwards.
  * Full N-audit (per-corpus tokens, speakers, exclusion breakdown) written to
    results/supplement/.

Diagnostic-driven decisions (see results/supplement/diagnostics_summary.md):
  #1 Buckeye labels normalized: strip ';...' annotation, lowercase.
  #2 Pause / vowel matching is case-insensitive.
  #3 Buckeye nasalized vowels (own/ehn/ihn...) are EXCLUDED (counted separately).
  #4 CSJ Dialogue: one seg tier annotates ONE talker -> pick the dominant channel
     per file, speaker = session (18 speakers), not L/R as two speakers.

Run: uv run python src/build_dataset.py [--dummy]
"""
from __future__ import annotations

import sys
import json
import pathlib
import datetime as dt
from collections import Counter, defaultdict

import numpy as np
import pandas as pd
import yaml
import parselmouth
from joblib import Parallel, delayed

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from diagnose_data import (parse_textgrid, parse_phones,  # noqa: E402
                           nth_interval_tier, tier_by_name)

REPO = pathlib.Path(__file__).resolve().parents[1]
CFG = yaml.safe_load((REPO / "config" / "config.yaml").read_text())

DATASET_LABELS = {"csj_mono": "CSJ Monologue", "buckeye": "Buckeye",
                  "csj_dial": "CSJ Dialogue"}

# failures collected across the run (never silently swallowed)
_FAILURES: list[dict] = []


def log_fail(corpus: str, path: str, stage: str, err: str):
    _FAILURES.append({"corpus": corpus, "path": path, "stage": stage, "error": err})


# --------------------------------------------------------------------------- #
# label normalization
# --------------------------------------------------------------------------- #
def norm_buckeye(label: str) -> str:
    """#1/#2: drop ';...' annotation, strip, lowercase. 'ih; *' -> 'ih'."""
    return label.split(";")[0].strip().lower()


def norm_csj(label: str) -> str:
    """CSJ seg label cleanup (short vowels appear as their own 1-char interval)."""
    if not label:
        return ""
    if label.startswith("<"):
        return label.lower()
    return label.split("+")[0].split("_")[0].lower()


def is_pause(label: str, pause_set: set[str]) -> bool:
    return str(label).strip().lower() in pause_set


def is_nasalized_vowel(label: str, vowels: set[str]) -> bool:
    """#3: e.g. 'ehn','ahn','own','iyn' — base vowel + trailing n, not in set."""
    l = label.lower()
    return (l not in vowels and l.endswith("n")
            and any(l.startswith(v) and l[:-1] == v for v in vowels))


# --------------------------------------------------------------------------- #
# pitch analysis (vectorised over the extracted track)
# --------------------------------------------------------------------------- #
def make_pitch(snd: parselmouth.Sound):
    p = snd.to_pitch(time_step=CFG["pitch"]["time_step"],
                     pitch_floor=CFG["pitch"]["floor"],
                     pitch_ceiling=CFG["pitch"]["ceiling"])
    freqs = p.selected_array["frequency"].astype(float)
    times = np.asarray(p.xs(), dtype=float)
    return times, freqs


def make_intensity(snd: parselmouth.Sound):
    """Intensity (dB) track over the whole sound (frame times + values).

    Used by the intensity-confound check (11_intensity_check.R): is the
    rate->F0range effect explained away by an overall increase in vocal effort /
    loudness? Same time_step as F0; minimum_pitch sets Praat's analysis window
    (config.intensity, defaults to the pitch floor).
    """
    icfg = CFG.get("intensity", {})
    it = snd.to_intensity(minimum_pitch=float(icfg.get("minimum_pitch",
                                                       CFG["pitch"]["floor"])),
                          time_step=float(icfg.get("time_step",
                                                   CFG["pitch"]["time_step"])),
                          subtract_mean=False)
    vals = np.asarray(it.values[0], dtype=float)
    times = np.asarray(it.xs(), dtype=float)
    return times, vals


def analyze_intensity(times, vals, start, end):
    """Intensity max/mean/range (dB) over [start,end]. NaN if no frames."""
    if end <= start or times.size == 0:
        return {"Intensity_Max": np.nan, "Intensity_Mean": np.nan,
                "Intensity_Range": np.nan}
    v = vals[(times >= start) & (times <= end)]
    v = v[np.isfinite(v)]
    if v.size == 0:
        return {"Intensity_Max": np.nan, "Intensity_Mean": np.nan,
                "Intensity_Range": np.nan}
    return {"Intensity_Max": float(v.max()), "Intensity_Mean": float(v.mean()),
            "Intensity_Range": float(v.max() - v.min())}


_PITCH_KEYS = ("f0_max", "f0_min", "f0_mean", "f0_range",
               "f0_p5", "f0_p95", "f0_sd", "num_valid", "has_jump",
               "f0_lm_min", "f0_lm_max", "n_lm")

_LANDMARK_PROPS = tuple(CFG.get("landmark", {}).get("props",
                                                    [0.1, 0.3, 0.5, 0.7, 0.9]))


def landmark_f0(times, freqs, start, end):
    """F0 (Hz) at fixed proportional time points inside [start,end].

    Frame-count-artifact fix: raw max-min uses ALL voiced frames, so longer
    (slower) vowels get a larger max-min purely from more samples. Here we
    linearly interpolate the voiced F0 track at k = len(props) FIXED proportional
    positions (edges clamped to the nearest voiced frame via np.interp). The
    number of points is independent of duration, so the estimator's bias does not
    scale with vowel length. Returns (lm_min, lm_max, n_valid_landmarks).
    """
    m = (times >= start) & (times <= end)
    tv = times[m]; fv = freqs[m]
    ok = fv > 0
    tv = tv[ok]; fv = fv[ok]
    if tv.size < 2 or end <= start:
        return 0.0, 0.0, 0
    targets = start + np.asarray(_LANDMARK_PROPS) * (end - start)
    lm = np.interp(targets, tv, fv)          # clamps out-of-range to endpoints
    return float(lm.min()), float(lm.max()), int(lm.size)


def analyze_pitch(times, freqs, start, end):
    """Dict of F0 stats over [start,end], voiced frames only.

    Beyond max/min/mean/range, returns robust stats for the F0range robustness
    checks (04_robustness.R): f0_p5, f0_p95 (percentiles, resistant to a single
    octave-halving/creak frame that would wreck max/min), and f0_sd.

    Octave-jump flag follows config.jump_method:
      'hz'    -> abs adjacent Δf0 > jump_hz_threshold  (paper's Hz criterion)
      'ratio' -> adjacent ratio outside [jump_ratio_low, jump_ratio_high]
    """
    empty = dict(zip(_PITCH_KEYS,
                     (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, False, 0.0, 0.0, 0)))
    if end <= start:
        return empty
    v = freqs[(times >= start) & (times <= end)]
    v = v[v > 0]                       # voiced frames only
    if v.size == 0:
        return empty
    lm_min, lm_max, n_lm = landmark_f0(times, freqs, start, end)
    f0_max = float(v.max()); f0_min = float(v.min())
    p5, p95 = (float(x) for x in np.percentile(v, [5, 95]))
    has_jump = False
    if v.size >= 2:
        method = CFG["filtering"]["jump_method"]
        if method == "hz":
            has_jump = bool(np.any(np.abs(np.diff(v)) > CFG["filtering"]["jump_hz_threshold"]))
        else:
            r = v[:-1] / v[1:]
            has_jump = bool(np.any((r > CFG["filtering"]["jump_ratio_high"]) |
                                   (r < CFG["filtering"]["jump_ratio_low"])))
    return {"f0_max": f0_max, "f0_min": f0_min, "f0_mean": float(v.mean()),
            "f0_range": f0_max - f0_min, "f0_p5": p5, "f0_p95": p95,
            "f0_sd": float(v.std(ddof=0)), "num_valid": int(v.size),
            "has_jump": has_jump,
            "f0_lm_min": lm_min, "f0_lm_max": lm_max, "n_lm": n_lm}


# --------------------------------------------------------------------------- #
# accent-nucleus tagging (CSJ X-JToBI tone tier)
# --------------------------------------------------------------------------- #
def accent_times(tiers) -> list[float] | None:
    """Sorted times of accentual-fall points ('A'/'Ax') on the tone tier.

    Returns None if the file has no tone tier at all (so downstream can record
    'accent info unavailable' rather than 'no accent'). Returns [] if the tier
    exists but carries no nucleus marks.
    """
    tier = tier_by_name(tiers, CFG["accent"]["tone_tier"])
    if tier is None:
        return None
    marks = {m.lower() for m in CFG["accent"]["nucleus_marks"]}
    return sorted(t for t, m in tier.points if m.strip().lower() in marks)


def accent_dist(s: float, e: float, atimes: list[float]) -> float:
    """Time gap (s) from vowel interval [s,e] to the nearest accentual point.

    0.0 if an 'A' point falls inside the vowel; otherwise the distance from the
    nearer interval edge to the nearest point. NaN if no points are available.
    """
    if not atimes:
        return float("nan")
    a = np.asarray(atimes)
    if np.any((a >= s) & (a < e)):
        return 0.0
    return float(np.min(np.where(a < s, s - a, a - e)))


# --------------------------------------------------------------------------- #
# per-file extractors (return list[dict])
# --------------------------------------------------------------------------- #
def extract_buckeye(wav: pathlib.Path, vowels_en, pause_set):
    rows = []
    counts = Counter()
    ph = wav.with_suffix(".phones")
    if not ph.exists():
        log_fail("buckeye", str(wav), "label", "no .phones beside wav")
        return rows, counts
    try:
        snd = parselmouth.Sound(str(wav))
        times, freqs = make_pitch(snd)
        itimes, ivals = make_intensity(snd)
        segs = parse_phones(ph)
    except Exception as e:
        log_fail("buckeye", str(wav), "load", f"{type(e).__name__}: {e}")
        return rows, counts
    labs = [norm_buckeye(l) for _, _, l in segs]
    for i, (s, e, raw) in enumerate(segs):
        lab = labs[i]
        if lab in vowels_en:
            counts["vowel_token"] += 1
        elif is_nasalized_vowel(lab, vowels_en):
            counts["nasalized_excluded"] += 1     # #3
            continue
        else:
            continue
        st = analyze_pitch(times, freqs, s, e)
        prev_l = labs[i - 1] if i > 0 else "START"
        next_l = labs[i + 1] if i < len(segs) - 1 else "END"
        rows.append({
            "Dataset": DATASET_LABELS["buckeye"], "Language": "English",
            "FileID": wav.name, "Speaker": wav.stem[:3], "Session": pd.NA,
            "Channel": pd.NA, "Vowel": lab, "Duration": e - s,
            "Tmin": s, "Tmax": e, **st,
            **analyze_intensity(itimes, ivals, s, e),
            "PrevSeg": prev_l, "NextSeg": next_l,
            "PrevIsPause": is_pause(prev_l, pause_set),
            "NextIsPause": is_pause(next_l, pause_set),
            # accent tagging is CSJ/X-JToBI only; English has no tone tier
            "HasTone": False, "AccentDist": float("nan"),
            "AccentNucleus": False, "AccentNear": False,
        })
    return rows, counts


def _dominant_channel(tg_root: pathlib.Path, stem: str, seg, pause_set):
    """#4: choose the channel whose RMS dominates the labeled speech segments."""
    speech = [(a, b) for a, b, t in seg.intervals
              if t.strip() and t.strip() != "#" and not is_pause(t, pause_set)
              and (b - a) >= 0.03]
    if not speech:
        return None, None
    sub = speech[:: max(1, len(speech) // 300)]   # sample for speed
    energy = {}
    snds = {}
    for ch in ("L", "R"):
        snd = parselmouth.Sound(str(tg_root / f"{stem}-{ch}.wav"))
        snds[ch] = snd
        tot = 0.0
        for a, b in sub:
            try:
                part = snd.extract_part(from_time=a, to_time=b, preserve_times=False)
                x = part.values[0]
                tot += float(np.sum(x * x))
            except Exception:
                pass
        energy[ch] = tot
    chosen = "L" if energy["L"] >= energy["R"] else "R"
    denom = energy["L"] + energy["R"] + 1e-12
    dominance = energy[chosen] / denom            # ~0.5 ambiguous .. ~1.0 clean
    return chosen, (snds[chosen], dominance)


def extract_csj(wav_or_stem, corpus_key, vowels_jp, pause_set):
    rows = []
    counts = Counter()
    root = pathlib.Path(CFG["paths"]["raw"][corpus_key])
    is_dial = corpus_key == "csj_dial"
    stem = wav_or_stem
    tg_path = root / f"{stem}.TextGrid"
    if not tg_path.exists():
        log_fail(corpus_key, str(tg_path), "label", "TextGrid missing")
        return rows, counts, None
    try:
        tiers = parse_textgrid(tg_path)
    except Exception as e:
        log_fail(corpus_key, str(tg_path), "parse", f"{type(e).__name__}: {e}")
        return rows, counts, None
    hit = nth_interval_tier(tiers, 2)               # phoneme = 2nd interval tier
    if hit is None:
        log_fail(corpus_key, str(tg_path), "tier", "<2 interval tiers")
        return rows, counts, None
    _, seg = hit

    atimes = accent_times(tiers)                    # None if no tone tier
    has_tone = atimes is not None
    if not has_tone:
        log_fail(corpus_key, str(tg_path), "tone", "no tone tier for accent tag")

    channel = None
    dominance = None
    if is_dial:
        channel, res = _dominant_channel(root, stem, seg, pause_set)
        if res is None:
            log_fail(corpus_key, str(tg_path), "channel", "no speech segments")
            return rows, counts, None
        snd, dominance = res
        speaker = stem            # #4: session-level speaker (18 speakers)
    else:
        try:
            snd = parselmouth.Sound(str(root / f"{stem}.wav"))
        except Exception as e:
            log_fail(corpus_key, str(root / f"{stem}.wav"), "load", f"{type(e).__name__}: {e}")
            return rows, counts, None
        speaker = stem

    try:
        times, freqs = make_pitch(snd)
        itimes, ivals = make_intensity(snd)
    except Exception as e:
        log_fail(corpus_key, str(tg_path), "pitch", f"{type(e).__name__}: {e}")
        return rows, counts, None

    tol = float(CFG["accent"]["near_tol_s"])
    ivs = seg.intervals
    labs = [norm_csj(t) for _, _, t in ivs]
    for i, (s, e, _) in enumerate(ivs):
        lab = labs[i]
        if lab not in vowels_jp:
            continue
        counts["vowel_token"] += 1
        st = analyze_pitch(times, freqs, s, e)
        prev_l = labs[i - 1] if i > 0 else "START"
        next_l = labs[i + 1] if i < len(ivs) - 1 else "END"
        adist = accent_dist(s, e, atimes) if has_tone else float("nan")
        rows.append({
            "Dataset": DATASET_LABELS[corpus_key], "Language": "Japanese",
            "FileID": f"{stem}.wav", "Speaker": speaker,
            "Session": stem if is_dial else pd.NA, "Channel": channel,
            "Vowel": lab, "Duration": e - s, "Tmin": s, "Tmax": e, **st,
            **analyze_intensity(itimes, ivals, s, e),
            "PrevSeg": prev_l, "NextSeg": next_l,
            "PrevIsPause": is_pause(prev_l, pause_set),
            "NextIsPause": is_pause(next_l, pause_set),
            "HasTone": has_tone, "AccentDist": adist,
            "AccentNucleus": bool(has_tone and adist == 0.0),
            "AccentNear": bool(has_tone and adist <= tol),
        })
    return rows, counts, (channel, dominance)


# --------------------------------------------------------------------------- #
# driver
# --------------------------------------------------------------------------- #
def gather_files():
    b_root = pathlib.Path(CFG["paths"]["raw"]["buckeye"])
    excl = set(CFG.get("buckeye_exclude_subdirs", []))
    buck = [p for p in b_root.rglob("*.wav")
            if not any(part in excl for part in p.relative_to(b_root).parts)]
    mono = [p.stem for p in pathlib.Path(CFG["paths"]["raw"]["csj_mono"]).glob("*.TextGrid")]
    dial = [p.stem for p in pathlib.Path(CFG["paths"]["raw"]["csj_dial"]).glob("*.TextGrid")]
    return sorted(buck), sorted(mono), sorted(dial)


def run_extraction(n_jobs: int):
    vjp = set(CFG["vowels"]["jp"]); ven = set(CFG["vowels"]["en"])
    pause = {p.lower() for p in CFG["pause_labels"]}
    buck, mono, dial = gather_files()
    print(f"files: buckeye={len(buck)} csj_mono={len(mono)} csj_dial={len(dial)}", flush=True)

    par = Parallel(n_jobs=n_jobs, backend="loky")

    print("extracting Buckeye ...", flush=True)
    b_out = par(delayed(extract_buckeye)(w, ven, pause) for w in buck)
    print("extracting CSJ Monologue ...", flush=True)
    m_out = par(delayed(extract_csj)(s, "csj_mono", vjp, pause) for s in mono)
    print("extracting CSJ Dialogue ...", flush=True)
    d_out = par(delayed(extract_csj)(s, "csj_dial", vjp, pause) for s in dial)

    rows = []
    counts = Counter()
    chan_log = []
    for r, c in b_out:
        rows += r; counts.update(c)
    for r, c, _ in m_out:
        rows += r; counts.update(c)
    for (r, c, ch), stem in zip(d_out, dial):
        rows += r; counts.update(c)
        if ch is not None:
            chan_log.append({"session": stem, "channel": ch[0],
                             "dominance": None if ch[1] is None else round(ch[1], 3)})
    return pd.DataFrame(rows), counts, chan_log


def apply_filters(df: pd.DataFrame):
    f = CFG["filtering"]
    df = df.copy()
    df["Flag_Dur"] = ~df["Duration"].between(f["dur_min"], f["dur_max"])
    df["Flag_Unvoiced"] = df["num_valid"] == 0
    df["Flag_Sparse"] = (df["num_valid"] > 0) & (df["num_valid"] < f["min_valid_frames"])
    df["Flag_Jump"] = df["has_jump"].astype(bool)
    df["Exclude"] = df[["Flag_Dur", "Flag_Unvoiced", "Flag_Sparse", "Flag_Jump"]].any(axis=1)
    return df


def exclusive_breakdown(df: pd.DataFrame):
    out = []
    for ds, g in df.groupby("Dataset"):
        total = len(g)
        d = g[g["Flag_Dur"]]; r1 = g[~g["Flag_Dur"]]
        u = r1[r1["Flag_Unvoiced"]]; r2 = r1[~r1["Flag_Unvoiced"]]
        sp = r2[r2["Flag_Sparse"]]; r3 = r2[~r2["Flag_Sparse"]]
        jp = r3[r3["Flag_Jump"]]; kept = r3[~r3["Flag_Jump"]]
        out.append({"Dataset": ds, "Total": total, "Drop_Duration": len(d),
                    "Drop_Unvoiced": len(u), "Drop_Sparse": len(sp),
                    "Drop_Jump": len(jp), "Final_Kept": len(kept)})
    return pd.DataFrame(out)


def engineer(df: pd.DataFrame):
    df = df.copy()
    df["F0_ST"] = 12 * np.log2(df["f0_max"] / 1.0)          # ref 1 Hz
    ok = (df["f0_min"] > 0) & (df["f0_max"] > df["f0_min"])
    df["F0_range_ST"] = np.nan
    df.loc[ok, "F0_range_ST"] = 12 * np.log2(df.loc[ok, "f0_max"] / df.loc[ok, "f0_min"])
    # --- frame-count-robust excursion (fixed-landmark) : PRIMARY robust DV ---
    # 09_artifact_check showed raw max-min is largely a frame-count artifact. These
    # landmark F0s are sampled at k FIXED proportional positions (build: landmark_f0),
    # so the excursion estimator is not duration-biased. ST = ref-invariant.
    oklm = (df["n_lm"] >= 2) & (df["f0_lm_min"] > 0) & (df["f0_lm_max"] > df["f0_lm_min"])
    df["F0_excursion_LM_ST"] = np.nan
    df.loc[oklm, "F0_excursion_LM_ST"] = 12 * np.log2(df.loc[oklm, "f0_lm_max"] / df.loc[oklm, "f0_lm_min"])
    # landmark max / min in ST (ref 1 Hz) for the min/max mechanism (Mundlak)
    okmx = df["f0_lm_max"] > 0; okmn = df["f0_lm_min"] > 0
    df["F0_LMmax_ST"] = np.nan; df.loc[okmx, "F0_LMmax_ST"] = 12 * np.log2(df.loc[okmx, "f0_lm_max"])
    df["F0_LMmin_ST"] = np.nan; df.loc[okmn, "F0_LMmin_ST"] = 12 * np.log2(df.loc[okmn, "f0_lm_min"])
    # --- robustness DVs for 04_robustness.R ---
    # (a) percentile excursion: p95/p5, resistant to a single halving/creak frame
    okp = (df["f0_p5"] > 0) & (df["f0_p95"] > df["f0_p5"])
    df["F0_rangeP_ST"] = np.nan
    df.loc[okp, "F0_rangeP_ST"] = 12 * np.log2(df.loc[okp, "f0_p95"] / df.loc[okp, "f0_p5"])
    # (b) per-speaker winsorized excursion: clip max/min to per-speaker 0.5/99.5%
    gmin = df.groupby("Speaker")["f0_min"].transform(lambda g: g.clip(lower=g.quantile(0.005)))
    gmax = df.groupby("Speaker")["f0_max"].transform(lambda g: g.clip(upper=g.quantile(0.995)))
    okw = (gmin > 0) & (gmax > gmin)
    df["F0_Min_Winsor"] = gmin
    df["F0_rangeW_ST"] = np.nan
    df.loc[okw, "F0_rangeW_ST"] = 12 * np.log2(gmax[okw] / gmin[okw])
    # (c) halving/creak suspicion: absolute min sits well below the 5th pct, or near
    #     the pitch floor -> flag so 04 can test sensitivity by excluding them.
    floor = float(CFG["pitch"]["floor"])
    df["Flag_MinSuspect"] = ((df["f0_p5"] > 0) & (df["f0_min"] < 0.85 * df["f0_p5"])) | \
                            (df["f0_min"] <= floor * 1.05)
    # per-speaker winsorization of F0_max (upper 0.5%)
    df["F0_Max_Winsor"] = gmax
    df["F0_ST_Winsor"] = 12 * np.log2(df["F0_Max_Winsor"] / 1.0)
    # Mundlak within/between decomposition of Duration
    spk_mean = df.groupby("Speaker")["Duration"].transform("mean")
    df["Duration_Between"] = spk_mean
    df["Duration_Within"] = df["Duration"] - spk_mean
    for c in ["Speaker", "Language", "Dataset", "Session", "NextSeg", "PrevSeg", "Channel"]:
        if c in df.columns:
            df[c] = df[c].astype("object").where(df[c].notna(), "NA").astype(str)
    return df


def write_supplement(counts, excl, chan_log, master, raw):
    sup = REPO / CFG["paths"]["supplement"]
    sup.mkdir(parents=True, exist_ok=True)
    excl.to_csv(sup / "TableS_filtering_summary_exclusive.csv", index=False)

    audit = []
    for ds, g in master.groupby("Dataset"):
        audit.append({"Dataset": ds, "n_tokens_final": len(g),
                      "n_speakers": g["Speaker"].nunique()})
    audit_df = pd.DataFrame(audit)
    audit_df.to_csv(sup / "TableS_N_audit_build.csv", index=False)

    pd.DataFrame(chan_log).to_csv(sup / "csj_dial_channel_selection.csv", index=False)

    if _FAILURES:
        pd.DataFrame(_FAILURES).to_csv(sup / "extraction_failures.csv", index=False)

    report = {
        "timestamp": dt.datetime.now().isoformat(timespec="seconds"),
        "vowel_tokens_extracted": counts.get("vowel_token", 0),
        "buckeye_nasalized_excluded": counts.get("nasalized_excluded", 0),
        "raw_tokens": len(raw),
        "final_tokens": len(master),
        "n_failures": len(_FAILURES),
        "by_dataset_final": audit,
        "csj_dial_channel_pick": chan_log,
        "manuscript_targets": {"CSJ Monologue": 82494, "Buckeye": 259019,
                               "CSJ Dialogue": 25874},
        "config": {"jump_method": CFG["filtering"]["jump_method"],
                   "speaker_specific_range": CFG["pitch"]["speaker_specific_range"],
                   "csj_dial": CFG.get("csj_dial")},
    }
    (sup / "build_dataset_report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))
    return audit_df


def make_dummy():
    """Tiny synthetic run to exercise the pipeline without touching raw data."""
    rng = np.random.default_rng(0)
    rows = []
    for ds, lang, key, vw, nspk in [
        ("CSJ Monologue", "Japanese", "csj_mono", list("aiueo"), 4),
        ("Buckeye", "English", "buckeye", ["ih", "eh", "ah", "iy", "ae"], 4),
        ("CSJ Dialogue", "Japanese", "csj_dial", list("aiueo"), 4)]:
        has_tone = lang == "Japanese"
        t = 0.0
        for si in range(nspk):
            spk = f"{key}_s{si}"
            for _ in range(200):
                d = float(np.clip(rng.gamma(2.2, 0.05), 0.03, 0.5))
                mx = 150 + rng.normal(0, 20) - 8 * (d - 0.15)
                mn = mx - abs(rng.normal(25, 8))
                t += d + 0.05
                is_nuc = has_tone and rng.random() < 0.13
                adist = (0.0 if is_nuc else float(rng.gamma(2.0, 0.06))) if has_tone else float("nan")
                rows.append({
                    "Dataset": ds, "Language": lang, "FileID": spk + ".wav",
                    "Speaker": spk, "Session": spk if key == "csj_dial" else pd.NA,
                    "Channel": "R" if key == "csj_dial" else pd.NA,
                    "Vowel": rng.choice(vw), "Duration": d,
                    "Tmin": t, "Tmax": t + d,
                    "f0_max": mx, "f0_min": mn, "f0_mean": (mx + mn) / 2,
                    "f0_range": mx - mn, "f0_p5": mn + 2, "f0_p95": mx - 2,
                    "f0_sd": abs(rng.normal(8, 2)), "num_valid": int(rng.integers(3, 12)),
                    "has_jump": bool(rng.random() < 0.02),
                    "f0_lm_min": mn + 3, "f0_lm_max": mx - 3, "n_lm": 5,
                    "Intensity_Max": 70 + rng.normal(0, 4) - 12 * (d - 0.15),
                    "Intensity_Mean": 64 + rng.normal(0, 4) - 10 * (d - 0.15),
                    "Intensity_Range": abs(rng.normal(10, 3)),
                    "PrevSeg": "x", "NextSeg": rng.choice(["t", "n", "s", "k"]),
                    "PrevIsPause": False, "NextIsPause": False,
                    "HasTone": has_tone, "AccentDist": adist,
                    "AccentNucleus": bool(is_nuc),
                    "AccentNear": bool(has_tone and adist <= 0.10)})
    return pd.DataFrame(rows), Counter({"vowel_token": len(rows)}), []


def main(argv):
    dummy = "--dummy" in argv
    if dummy:
        print("== DUMMY run ==", flush=True)
        raw, counts, chan_log = make_dummy()
    else:
        raw, counts, chan_log = run_extraction(int(CFG["compute"]["n_jobs"]))

    if raw.empty:
        print("ERROR: no tokens extracted; see extraction_failures.csv", flush=True)
        return 1

    print(f"raw tokens: {len(raw):,}", flush=True)
    filt = apply_filters(raw)
    excl = exclusive_breakdown(filt)
    master = engineer(filt[~filt["Exclude"]])

    (REPO / CFG["paths"]["interim"]).mkdir(parents=True, exist_ok=True)
    (REPO / CFG["paths"]["processed"]).mkdir(parents=True, exist_ok=True)
    raw.to_csv(REPO / CFG["paths"]["interim"] / "rate_f0_raw.csv", index=False)
    master.to_csv(REPO / CFG["paths"]["master_csv"], index=False)

    audit_df = write_supplement(counts, excl, chan_log, master, raw)

    print("\n== filtering (exclusive) ==")
    print(excl.to_string(index=False))
    print("\n== N-audit (final) ==")
    print(audit_df.to_string(index=False))
    print(f"\nnasalized excluded (Buckeye): {counts.get('nasalized_excluded', 0):,}")
    print(f"extraction failures: {len(_FAILURES)}")
    if chan_log:
        picks = Counter(c["channel"] for c in chan_log)
        print(f"CSJ-D channel picks: {dict(picks)}")
    print(f"\nmaster_csv -> {REPO / CFG['paths']['master_csv']} ({len(master):,} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
