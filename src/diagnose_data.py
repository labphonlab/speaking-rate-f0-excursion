#!/usr/bin/env python3
"""diagnose_data.py — pre-extraction sanity checks (pipeline step 0).

Opens only a few files per corpus and validates the structural assumptions in
CLAUDE.md BEFORE any full extraction is attempted. Nothing here writes to the
Dropbox raw data; output goes to results/supplement/ inside the repo.

Checks (per CLAUDE.md B):
  - CSJ TextGrid: is the phoneme layer really the 2nd *interval* tier? dump tiers.
  - Buckeye .phones: label format; do vowel labels actually hit?
  - CSJ Dial: do L/R 2 wav + shared TextGrid line up? (+ speaker-attribution risk)
  - speaker-ID extraction: does it break on ANY file across all 3 corpora?
  - are the wav files real (not placeholders)?

Run:  uv run python src/diagnose_data.py
"""
from __future__ import annotations

import re
import sys
import json
import pathlib
from collections import Counter
from dataclasses import dataclass, field

import yaml
import parselmouth

REPO = pathlib.Path(__file__).resolve().parents[1]
CONFIG_PATH = REPO / "config" / "config.yaml"

# how many files to actually open per corpus for the deep structural checks
N_SAMPLE = 3


# --------------------------------------------------------------------------- #
# minimal long-format ("ooTextFile") TextGrid parser
# --------------------------------------------------------------------------- #
@dataclass
class Tier:
    name: str
    tier_class: str            # "IntervalTier" | "TextTier"
    intervals: list = field(default_factory=list)  # list[(xmin, xmax, text)]
    points: list = field(default_factory=list)     # list[(time, mark)] for TextTier


def parse_textgrid(path: pathlib.Path) -> list[Tier]:
    """Parse a Praat long-format TextGrid into a list of Tier objects.

    Interval tiers get their `intervals` populated; point tiers (TextTier, e.g.
    the CSJ X-JToBI 'tone' tier) get their `points` populated. Point-tier files
    use either `time =` (CSJ mono) or `number =` (some CSJ sessions) for the
    point location — both are accepted.
    Kept deliberately simple and dependency-free so build_dataset can reuse it.
    Raises on malformed input rather than silently returning junk.
    """
    text = path.read_text(encoding="utf-8", errors="replace")
    if 'Object class = "TextGrid"' not in text:
        raise ValueError(f"not a TextGrid: {path}")

    tiers: list[Tier] = []
    # Split on each "item [n]:" block. The first split chunk is the file header.
    blocks = re.split(r"item\s*\[\d+\]\s*:", text)[1:]
    for blk in blocks:
        cls_m = re.search(r'class\s*=\s*"([^"]+)"', blk)
        name_m = re.search(r'name\s*=\s*"([^"]*)"', blk)
        if not cls_m or not name_m:
            continue
        tier = Tier(name=name_m.group(1), tier_class=cls_m.group(1))
        if tier.tier_class == "IntervalTier":
            for iv in re.finditer(
                r"intervals\s*\[\d+\]\s*:\s*"
                r"xmin\s*=\s*([\d.eE+-]+)\s*"
                r"xmax\s*=\s*([\d.eE+-]+)\s*"
                r'text\s*=\s*"((?:[^"]|"")*)"',
                blk,
            ):
                xmin = float(iv.group(1))
                xmax = float(iv.group(2))
                txt = iv.group(3).replace('""', '"')
                tier.intervals.append((xmin, xmax, txt))
        else:  # TextTier / point tier
            for pt in re.finditer(
                r"points\s*\[\d+\]\s*:\s*"
                r"(?:time|number)\s*=\s*([\d.eE+-]+)\s*"
                r'mark\s*=\s*"((?:[^"]|"")*)"',
                blk,
            ):
                tier.points.append((float(pt.group(1)),
                                    pt.group(2).replace('""', '"')))
        tiers.append(tier)
    if not tiers:
        raise ValueError(f"no tiers parsed from {path}")
    return tiers


def tier_by_name(tiers: list[Tier], name: str) -> Tier | None:
    """Return the first tier whose name matches (case-insensitive), or None."""
    for t in tiers:
        if t.name.lower() == name.lower():
            return t
    return None


def nth_interval_tier(tiers: list[Tier], n: int) -> tuple[int, Tier] | None:
    """Return (1-based tier index, Tier) of the n-th IntervalTier, or None."""
    seen = 0
    for idx, t in enumerate(tiers, start=1):
        if t.tier_class == "IntervalTier":
            seen += 1
            if seen == n:
                return idx, t
    return None


# --------------------------------------------------------------------------- #
# Buckeye .phones parser
# --------------------------------------------------------------------------- #
def parse_phones(path: pathlib.Path) -> list[tuple[float, float, str]]:
    """Parse a Buckeye .phones label file into (start, end, label) intervals.

    Format: a header terminated by a line '#', then rows '<end>  <color> <label>'.
    Intervals are end-time coded; start = previous end (first start = 0).
    """
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    try:
        hdr_end = next(i for i, ln in enumerate(lines) if ln.strip() == "#")
    except StopIteration:
        raise ValueError(f"no '#' header terminator in {path}")

    out: list[tuple[float, float, str]] = []
    prev = 0.0
    for ln in lines[hdr_end + 1:]:
        s = ln.strip()
        if not s:
            continue
        parts = s.split(None, 2)  # end, color, label(rest)
        if len(parts) < 3:
            # some rows may lack an explicit label; keep as empty but log-visible
            if len(parts) == 2:
                end = float(parts[0])
                out.append((prev, end, ""))
                prev = end
            continue
        end = float(parts[0])
        label = parts[2].strip()
        out.append((prev, end, label))
        prev = end
    return out


# --------------------------------------------------------------------------- #
# wav reality check
# --------------------------------------------------------------------------- #
def probe_wav(path: pathlib.Path) -> dict:
    """Load a wav and return basic facts; detect placeholder/empty files."""
    size = path.stat().st_size
    try:
        snd = parselmouth.Sound(str(path))
        return {
            "path": path.name,
            "size_bytes": size,
            "duration_s": round(snd.duration, 4),
            "sr": int(snd.sampling_frequency),
            "n_channels": snd.n_channels,
            "placeholder": size < 1024 or snd.duration < 0.05,
            "error": None,
        }
    except Exception as e:  # log, never swallow
        return {"path": path.name, "size_bytes": size, "duration_s": None,
                "sr": None, "n_channels": None, "placeholder": True,
                "error": f"{type(e).__name__}: {e}"}


# --------------------------------------------------------------------------- #
# per-corpus diagnostics
# --------------------------------------------------------------------------- #
def diag_csj(cfg, corpus_key: str, report: dict):
    root = pathlib.Path(cfg["paths"]["raw"][corpus_key])
    tgs = sorted(root.glob("*.TextGrid"))
    sec = {"root": str(root), "n_textgrids": len(tgs), "samples": [],
           "issues": []}
    if not tgs:
        sec["issues"].append("no TextGrid files found")
        report[corpus_key] = sec
        return

    seg_vowels = set(cfg["vowels"]["jp"])
    for tg in tgs[:N_SAMPLE]:
        tiers = parse_textgrid(tg)
        tier_desc = [
            {"idx": i, "name": t.name, "class": t.tier_class,
             "n_intervals": len(t.intervals)}
            for i, t in enumerate(tiers, start=1)
        ]
        hit = nth_interval_tier(tiers, 2)
        smp = {"file": tg.name, "n_tiers": len(tiers), "tiers": tier_desc}
        if hit is None:
            smp["second_interval_tier"] = None
            sec["issues"].append(f"{tg.name}: <2 interval tiers")
        else:
            idx, seg = hit
            smp["second_interval_tier"] = {"idx": idx, "name": seg.name}
            if seg.name != "seg":
                sec["issues"].append(
                    f"{tg.name}: 2nd interval tier is '{seg.name}', not 'seg'")
            # do JP vowels actually appear on the seg tier?
            # CSJ seg labels can be compound like 'Q,py' / 'oH'; count base-vowel hits
            labels = [t for _, _, t in seg.intervals]
            vhits = Counter()
            for lab in labels:
                for v in seg_vowels:
                    if v in lab:            # substring: CSJ vowels embed in labels
                        vhits[v] += 1
            smp["seg_label_sample"] = labels[1:11]
            smp["seg_vowel_hits"] = dict(vhits)
            smp["seg_total_intervals"] = len(labels)
            if sum(vhits.values()) == 0:
                sec["issues"].append(f"{tg.name}: no JP vowels hit on seg tier")
        sec["samples"].append(smp)
    report[corpus_key] = sec


def diag_csj_dial_pairing(cfg, report: dict):
    """L/R wav + shared TextGrid alignment, and speaker-attribution risk."""
    root = pathlib.Path(cfg["paths"]["raw"]["csj_dial"])
    tgs = sorted(root.glob("*.TextGrid"))
    sec = {"root": str(root), "n_textgrids": len(tgs), "pairs": [],
           "issues": []}
    for tg in tgs[:N_SAMPLE]:
        stem = tg.stem
        rec = {"stem": stem}
        tiers = parse_textgrid(tg)
        tg_xmax = max((iv[1] for t in tiers for iv in t.intervals), default=0.0)
        rec["tg_xmax"] = round(tg_xmax, 4)
        for ch in ("-L", "-R"):
            w = root / f"{stem}{ch}.wav"
            if not w.exists():
                sec["issues"].append(f"{stem}: missing {ch}.wav")
                rec[ch] = "MISSING"
                continue
            p = probe_wav(w)
            rec[ch] = p
            if p["duration_s"] and abs(p["duration_s"] - tg_xmax) > 0.05:
                sec["issues"].append(
                    f"{stem}{ch}: wav dur {p['duration_s']} != TextGrid xmax "
                    f"{round(tg_xmax,4)}")
        # speech-coverage on the single seg tier: one speaker or both?
        hit = nth_interval_tier(tiers, 2)
        if hit:
            _, seg = hit
            pause = set(cfg["pause_labels"])
            speech = sum(
                (b - a) for a, b, t in seg.intervals
                if t.strip() and t.strip() not in pause and t.strip() != "#")
            rec["seg_speech_coverage_frac"] = round(speech / tg_xmax, 3) if tg_xmax else None
        sec["pairs"].append(rec)

    # design-level note: 1 seg tier vs 2 channel "speakers"
    sec["attribution_note"] = (
        "Each session has ONE TextGrid (one seg tier) but TWO channel wavs "
        "(-L,-R) mapped to two speaker IDs. A single seg tier can only annotate "
        "ONE talker's segments. Applying those segment times to BOTH channels "
        "would measure the real talker on one channel and cross-channel bleed / "
        "silence on the other -> invalid speaker attribution. Coverage frac (<<0.5 "
        "= sparse, consistent with a single-talker turn structure) is reported "
        "per pair above. NEEDS a decision before extraction.")
    report["csj_dial_pairing"] = sec


def diag_buckeye(cfg, report: dict):
    root = pathlib.Path(cfg["paths"]["raw"]["buckeye"])
    excl = set(cfg.get("buckeye_exclude_subdirs", []))
    phones = [p for p in root.rglob("*.phones")
              if not any(part in excl for part in p.relative_to(root).parts)]
    sec = {"root": str(root), "n_phones": len(phones), "samples": [],
           "issues": []}
    en_vowels = set(cfg["vowels"]["en"])
    pause = set(cfg["pause_labels"])

    global_labels = Counter()
    for ph in phones[:N_SAMPLE]:
        # .phones must sit beside its wav (CLAUDE.md: .phones only within wav dir)
        wav = ph.with_suffix(".wav")
        intervals = parse_phones(ph)
        labels = [lab for _, _, lab in intervals if lab]
        labset = Counter(labels)
        global_labels.update(labset)
        # exact-match vowel hits (config lists base forms, lowercase)
        exact_hits = {v: labset.get(v, 0) for v in en_vowels if labset.get(v, 0)}
        # nasalized / variant vowels that EXACT match would miss (e.g. 'ehn','iyn')
        variant_vowels = {
            lab: c for lab, c in labset.items()
            if lab.lower() not in en_vowels
            and any(lab.lower().startswith(v) for v in en_vowels)
            and lab.lower() not in {p.lower() for p in pause}
        }
        # case check: are non-speech labels uppercase (SIL) vs config lowercase?
        upper_pause_like = sorted({lab for lab in labset
                                   if lab.isupper() and lab.lower() in
                                   {p.lower() for p in pause}})
        sec["samples"].append({
            "file": ph.name,
            "wav_beside": wav.exists(),
            "n_intervals": len(intervals),
            "label_inventory_sample": dict(labset.most_common(15)),
            "exact_vowel_hits": exact_hits,
            "n_exact_vowel_tokens": sum(exact_hits.values()),
            "variant_vowels_missed_by_exact": variant_vowels,
            "uppercase_pause_labels_present": upper_pause_like,
        })
        if sum(exact_hits.values()) == 0:
            sec["issues"].append(f"{ph.name}: no EN vowels hit (exact match)")
        if not wav.exists():
            sec["issues"].append(f"{ph.name}: no wav beside .phones")

    # aggregate case/nasalization warnings
    if any(s["variant_vowels_missed_by_exact"] for s in sec["samples"]):
        sec["issues"].append(
            "nasalized/variant vowels (e.g. 'ehn','ahn','iyn') present; exact "
            "match against config.vowels.en would DROP them — decide policy")
    if any(s["uppercase_pause_labels_present"] for s in sec["samples"]):
        sec["issues"].append(
            "pause/non-speech labels are UPPERCASE (SIL/NOISE/VOCNOISE) but "
            "config.pause_labels are lowercase — matching must be case-insensitive")
    report["buckeye"] = sec


def diag_speaker_ids(cfg, report: dict):
    """Apply each corpus's speaker-ID rule to EVERY file; report breakages."""
    out = {}

    # CSJ mono: speaker = TextGrid stem
    root = pathlib.Path(cfg["paths"]["raw"]["csj_mono"])
    stems = [p.stem for p in root.glob("*.TextGrid")]
    out["csj_mono"] = {"n_files": len(stems), "n_speakers": len(set(stems)),
                       "bad": [s for s in stems if not re.fullmatch(r"[AS]\d{2}[FM]\d{4}", s)]}

    # CSJ dial: speaker = {stem}-{L|R}
    root = pathlib.Path(cfg["paths"]["raw"]["csj_dial"])
    dstems = [p.stem for p in root.glob("*.TextGrid")]
    dspk = [f"{s}-{ch}" for s in dstems for ch in ("L", "R")]
    out["csj_dial"] = {"n_files": len(dstems), "n_speakers": len(set(dspk)),
                       "bad": [s for s in dstems if not re.fullmatch(r"D\d{2}[FM]\d{4}", s)]}

    # Buckeye: speaker = first 3 chars of wav filename
    root = pathlib.Path(cfg["paths"]["raw"]["buckeye"])
    excl = set(cfg.get("buckeye_exclude_subdirs", []))
    wavs = [p for p in root.rglob("*.wav")
            if not any(part in excl for part in p.relative_to(root).parts)]
    spk = [w.stem[:3] for w in wavs]
    out["buckeye"] = {"n_files": len(wavs), "n_speakers": len(set(spk)),
                      "bad": [w.name for w in wavs if not re.fullmatch(r"s\d\d", w.stem[:3])]}

    report["speaker_ids"] = out


def main() -> int:
    cfg = yaml.safe_load(CONFIG_PATH.read_text())
    report: dict = {}

    print("== diagnose_data.py ==", flush=True)
    diag_csj(cfg, "csj_mono", report)
    diag_csj(cfg, "csj_dial", report)
    diag_csj_dial_pairing(cfg, report)
    diag_buckeye(cfg, report)
    diag_speaker_ids(cfg, report)

    # collect all issues
    all_issues = []
    for k, sec in report.items():
        for iss in sec.get("issues", []) if isinstance(sec, dict) else []:
            all_issues.append(f"[{k}] {iss}")
    report["_all_issues"] = all_issues

    out_dir = REPO / cfg["paths"]["supplement"]
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "diagnostics.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))

    # human summary
    print(json.dumps({k: (report[k] if not isinstance(report[k], dict)
                          else {kk: vv for kk, vv in report[k].items() if kk != "samples"})
                      for k in report}, indent=2, ensure_ascii=False))
    print("\n== ISSUES ==")
    if all_issues:
        for i in all_issues:
            print("  -", i)
    else:
        print("  (none)")
    print(f"\nfull report -> {out_dir / 'diagnostics.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
