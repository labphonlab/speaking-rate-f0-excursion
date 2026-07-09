#!/usr/bin/env python3
"""check_docs_numbers.py — cross-check docs numbers against the TableS_*.csv.

Motivation: a transcription error slipped into the data pack (a Mundlak
between-speaker p reported as 0.21 instead of 0.28). This script reads each key
metric LIVE from its source CSV and verifies the correct value appears in the docs
that should cite it, flagging any doc that is missing it (a transcription error
leaves the WRONG value in place and the CORRECT value absent -> FAIL).

It is a curated-key checker (not a blind full scan): each check pulls its value
from the CSV so it stays correct as the data changes; only the doc-membership is
asserted. Prints a PASS/FAIL table and writes results/supplement/docs_number_check.md.

Run: uv run python src/check_docs_numbers.py
"""
from __future__ import annotations
import sys, pathlib, re
import pandas as pd

REPO = pathlib.Path(__file__).resolve().parents[1]
SUP = REPO / "results" / "supplement"
DOCS = REPO / "docs"
def _norm(t):  # normalise unicode minus / dashes so sign chars match
    return t.replace("−", "-").replace("–", "-").replace("—", "-")


DOCFILES = {f: _norm((DOCS / f"{f}.md").read_text()) for f in
            ["paper_data_pack", "results_landmark_consolidated", "manuscript",
             "paper_outline", "dv_change_raw_vs_landmark"]}


def csv(name):
    return pd.read_csv(SUP / name)


def val(df, col, **flt):
    d = df
    for k, v in flt.items():
        d = d[d[k] == v]
    return float(d[col].iloc[0])


def variants(x, decs=(2, 3)):
    """plausible string renderings of a number as it may appear in prose.

    Includes both signed and unsigned (magnitude) forms, and comma / no-comma for
    large numbers, because prose often writes the sign separately ('ΔAIC -6,048').
    """
    out = set()
    for signed in ({x, abs(x)} if x < 0 else {x}):
        for d in decs:
            s = f"{signed:.{d}f}"
            out.add(s)
            out.add(s.lstrip("0") if s.startswith("0.") else s)     # .28 form
            if s.startswith("-0."):
                out.add("-" + s[2:])                                # -.28 form
        if abs(signed) >= 1000:
            out.add(f"{signed:,.0f}"); out.add(f"{signed:.0f}")
    return {v for v in out if v and v not in ("-", "-0")}


# ---- build checks live from the CSVs -------------------------------------- #
eff = csv("TableS_effect_size.csv")
lang = csv("TableS_language_test.csv")
reg = csv("TableS_language_register.csv")
acc = csv("TableS_accent_nucleus.csv")
mun = csv("TableS_mundlak.csv")
naud = csv("TableS_N_audit_build.csv")
buck = csv("TableS_buckeye_control.csv")
a1 = csv("TableS_AIC_study1.csv"); a2 = csv("TableS_AIC_study2.csv")
aic1 = val(a1, "AIC", model="m1_full") - val(a1, "AIC", model="m1_base")
aic2 = val(a2, "AIC", model="m2_full") - val(a2, "AIC", model="m2_base")

ALL = ["paper_data_pack", "results_landmark_consolidated", "manuscript"]
CHECKS = []
for ds in ["CSJ Monologue", "Buckeye", "CSJ Dialogue"]:
    CHECKS.append((f"landmark eff {ds}", val(eff, "eff_range_5_95_st", Dataset=ds, DV="landmark"), (2, 3), ALL))
    CHECKS.append((f"N {ds}", val(naud, "n_tokens_final", Dataset=ds), (0,), ALL))
    CHECKS.append((f"mundlak within {ds}", val(mun, "within_eff_5_95_st", Corpus=ds, DV="landmark_exc"), (2,), ["paper_data_pack", "results_landmark_consolidated"]))
CHECKS += [
    ("lang JP eff", val(lang, "eff_range_5_95_st", Language="Japanese"), (2, 3), ALL),
    ("lang EN eff", val(lang, "eff_range_5_95_st", Language="English"), (2, 3), ALL),
    ("register JP eff", val(reg, "eff_range_5_95_st", Language="Japanese"), (2, 3), ALL),
    ("accent strict Mono", val(acc, "eff_range_5_95_st", Corpus="CSJ Monologue", Subset="strict"), (2, 3), ALL),
    ("accent strict Dial", val(acc, "eff_range_5_95_st", Corpus="CSJ Dialogue", Subset="strict"), (2, 3), ALL),
    ("buckeye ctrl coef", val(buck, "coef_Voiceless_st"), (2, 3), ["paper_data_pack"]),
    ("buckeye eff with ctrl", val(buck, "eff_range_with_ctrl_st"), (2, 3), ["paper_data_pack"]),
    ("mundlak between_p Buckeye", val(mun, "between_p", Corpus="Buckeye", DV="landmark_exc"), (2,), ["paper_data_pack", "results_landmark_consolidated"]),
    ("mundlak F0min sign Mono", val(mun, "within_sign_p5_minus_p95", Corpus="CSJ Monologue", DV="landmark_min"), (2, 3), ["paper_data_pack", "results_landmark_consolidated"]),
    ("AIC delta study1", aic1, (0,), ["paper_data_pack", "results_landmark_consolidated"]),
    ("AIC delta study2", aic2, (0,), ["paper_data_pack", "results_landmark_consolidated"]),
]


def main() -> int:
    rows, n_fail = [], 0
    for name, value, decs, docs in CHECKS:
        vs = variants(value, decs)
        per = {}
        for d in docs:
            per[d] = any(v in DOCFILES[d] for v in vs)
        ok = all(per.values())
        if not ok:
            n_fail += 1
        rows.append((name, value, sorted(vs), per, ok))

    lines = ["# Docs number cross-check (vs TableS_*.csv)", ""]
    print(f"{'CHECK':32s} {'VALUE':>12s}  RESULT  (missing docs)")
    for name, value, vs, per, ok in rows:
        miss = [d for d, p in per.items() if not p]
        status = "PASS" if ok else "FAIL"
        print(f"{name:32s} {value:12.3f}  {status:5s}  {','.join(miss)}")
        lines.append(f"- **{status}** {name} = {value:.3f} (variants {vs})"
                     + (f" — MISSING in: {', '.join(miss)}" if miss else ""))
    lines += ["", f"## {len(rows)-n_fail}/{len(rows)} checks passed, {n_fail} failed."]
    (SUP / "docs_number_check.md").write_text("\n".join(lines))
    print(f"\n{len(rows)-n_fail}/{len(rows)} passed, {n_fail} failed -> {SUP/'docs_number_check.md'}")
    return 1 if n_fail else 0


if __name__ == "__main__":
    sys.exit(main())
