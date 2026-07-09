# Paper outline — Rate–F0 covariation (Journal of Phonetics)

作成: パイプライン結果（commit 履歴 4f432ba→76989e8）に基づく。すべての数値は
`results/supplement/` の TableS_* と `results/figures/` の Fig1–6 から。CEJC は未取得
のため本稿には含めない（将来の強化として限界節に明記）。

---

## Working title
**"Speech rate compresses F0 *excursion*, not F0 maximum: an effect-size–first,
cross-linguistic corpus study (Japanese and English)."**

## One-paragraph thesis
発話速度と F0 の共変は実在するが、**測り方を誤ると見えず/誇張される**。DV を
F0max（各母音の最大値）にすると効果は F0 の弁別閾（JND ≈ 0.5–1 半音）級かそれ以下。
一方、素朴な max−min レンジは**フレーム数アーティファクト**（短母音＝有声フレーム少→
max−min 下方バイアス）で ~20% 水増しされる。これを**固定ランドマーク excursion**
（時間比率固定5点・時間スケール不変）で除去してもなお、効果は **1.4–1.5 半音で JND1.0
超**＝知覚的に意味がある。効果は (i) 測定定義に頑健、(ii) **話者内**現象（Mundlak:
between非有意）、(iii) 日本語スタイル非依存、(iv) 英語でも同程度（両JND超, 差は微小）。
機構は **register 底上げ**：速話では話者内で **F0min（床）が上昇し F0max（天井）はほぼ不変**
→ excursion が縮む（Caspers & van Heuven 1993; Ladd et al. 1999 の undershoot）。

---

## Structure & figure/table placement

### 1. Introduction
- 発話速度–F0 共変の先行研究と、"fast speech → F0 range 縮小" の予測。
- **問題1: 有意性 vs 効果量.** 大規模コーパス（本研究 total **377,518** vowel tokens）
  では p 値はほぼ必ず有意。効果量を**知覚単位（半音）で JND と比較**する必要。
- **問題2: 測定妥当性.** 「各母音に単一ピッチターゲット」は現代 ToBI/X-JToBI と不整合。
  母音ごとの F0max は excursion ではない（Editor 指摘）。→ DV を excursion へ。さらに
  **X-JToBI tone 層でアクセント核（下降 'A'）を持つ母音＝ターゲットが実際に付与される
  母音**に限定しても効果が残ることを示す（下記 3.6）。
- **問題3: 設計交絡.** 言語×スタイル交絡（英語=会話 / 日本語=モノローグ）を、日本語を
  2スタイル（monologue, dialogue）でサンプルして分離する。
- 目的/仮説: H1 range 効果 > JND、H2 定義頑健、H3 日本語内スタイル不変、H4 言語一般性。

### 2. Method
- **Corpora** → **Table 1**（下記）。CSJ Monologue(JP), CSJ Dialogue(JP), Buckeye(EN)。
- 抽出: Praat/parselmouth ピッチ（floor 75, ceiling 600 Hz, step 10 ms）。
- **DV（主）**: `F0_excursion_LM_ST` = 固定ランドマーク excursion（母音の時間比率
  10/30/50/70/90% の5固定点でF0を線形補間→max-min, 半音, フレーム数非依存）。
  対比用に raw `F0_range_ST`（全有声フレームの max-min; アーティファクト水増し）と F0max(ST)。
- フィルタ: 母音長 0.03–0.50 s、有声フレーム ≥3、**Hz 基準のオクターブ跳躍除去(>50 Hz)**。
- **CSJ Dialogue の話者帰属**（測定妥当性の要）: 1 TextGrid=1話者注釈であることを
  チャンネル RMS で実証（注釈区間で片ch が約10倍優勢）。→ 優勢チャンネルを自動選択し
  **話者=セッション（18話者）**。旧解析の両ch二重計上（幻の第2話者・クロストーク）を排除。
- GAMM（mgcv::bam, fREML, discrete）:
  `DV ~ s(Duration,k=20) + s(Duration,Speaker,bs="fs",m=1,k=5) + s(Vowel,bs="re")`
  （言語比較時は `+ Language + s(Duration,by=Language)`）。
- **アクセント核タグ付け（X-JToBI）**: CSJ の tone 層の下降ラベル 'A'/'Ax' の時刻を各母音
  区間に対応づけ、区間内なら核（AccentDist=0, strict）、近傍 ≤0.10 s なら near と定義。
  母音への割当感度は距離閾値スイープで検証（3.6）。
- **完全な N 監査**（TableS_N_audit_build.csv / _models.csv）と除外内訳（exclusive）。

### 3. Results
- **3.1 効果量: F0max vs raw range vs landmark** → **Fig 1**, effect_size_partial(3×3), **Table 2**。
  F0max 0.34–0.67 st（Buckeye は JND0.5 未満）; raw range 1.74–1.98 st（ただしアーティファクト水増し, 3.1b）;
  **landmark excursion（主DV）1.52/1.48/1.38 st, 全て JND1.0 超**（movement JND1.5 は Mono のみ）, shrinks_when_fast。
- **3.1b フレーム数アーティファクト診断** → **Fig 8**, 09_artifact_check/resample/gate。
  Duration⇔num_valid r≈0.9。素朴 max−min は短母音で下方バイアス。span固定で標本数だけ削ると raw −6%/LM −2%
  ＝純粋な count artifact は小。part3(連続スライス)の「MOSTLY ARTIFACT」は平坦中央部由来で過大評価。
  時間スケール不変の **landmark を主DVに採用**。num_valid≥5 でも 1.25–1.39 st 生存。
- **3.2 測定頑健性** → **Fig 3**, TableS_robustness.csv。maxmin/p95p5/winsor/疑義除外＋**landmark** で再解析。
  landmark 1.38–1.52 st, 全 JND1.0 超, shrinks_when_fast。
- **3.3 日本語内スタイル不変（案A）** → **Fig 2**。landmark で差分スムーズ n.s.（**p=0.678**）,
  スタイル水準 p=0.072、per-style Monologue 1.52 / Dialogue 1.38 st → スタイル不変。
- **3.4 言語一般性** → **Fig 4**, TableS_language_test.csv。**JP 1.52 vs EN 1.48（両JND1.0超）**;
  差分スムーズ有意(p=7e-7)だが gap 0.035 st＝検出力の産物（本稿主題の実例）。
- **3.4b register を近づけた言語比較** → **Fig 6**, TableS_language_register.csv。
  会話体に近い **CSJ Dialogue vs Buckeye**：両JND1.0超（JP 1.38 / EN 1.48）。堅牢DVでは差分スムーズも
  有意(p=0.02, gap 0.11 st)。**「register一致で非有意化」は landmark では成立しない**と正直に明記。
  効果量では一般性成立（gap 0.04–0.11 st は知覚的に無視可能）。
- **3.5 統制・within/between（Mundlak）** → **Fig 7**, TableS_mundlak.csv。
  効果は**話者内**現象（within excursion 1.25–1.47 st, 全JND1.0超, down_when_fast; between 非有意）。
  **機構**: 話者内で **F0min が +1.2〜+1.7 st 上昇・F0max はほぼ不変** → 床が上がり excursion 圧縮
  ＝register 底上げ（Caspers & van Heuven 1993; Ladd et al. 1999）。
  話者別勾配は landmark でも必要（AIC Δ −6048/−381）; 後続子音無声性統制も交絡なし（1.48→1.49, coef 0.13 st）。
  **intensity（声量）交絡も否定**（11_intensity_check.R, Fig_intensity_control）: Duration⇔Intensity r=0.04–0.14、
  s(Intensity_Max)統制で実効幅 1.52→1.47/1.48→1.42/1.38→1.31（3–5%減、核でも≤7%）→ピッチターゲット特有、声量ではない。
- **3.6 アクセント核限定（ターゲット批判への回答）** → **Fig 5**, TableS_accent_nucleus/sweep。
  landmark でも核限定で効果生存：Monologue strict 1.27 st・near 1.78（Dialogue strict 1.03/near 1.39）で
  **全て JND1.0 超**。核母音では傾きが全母音の約 4.9 倍（0.94 vs 0.19 st/100ms）。
  スイープ Mono 1.27–1.78 / Dial 1.03–1.39 も全 JND1.0 超。→ ターゲット未指定母音のプール産物ではない。

### 4. Discussion
- **機構: 時間圧縮下のピッチ目標 undershoot.** 母音が短くなるほど、目標に向かう F0 運動を
  完遂する時間が不足し、到達 F0（および出発 F0）が目標から不足側にずれる → 実現 excursion が
  縮小する。この枠組みは3つの観測を統一的に説明する: (i) 効果が **F0max ではなく excursion**
  に現れる（undershoot はレンジの縮小として現れ、単一到達点の水準としては弱い; 3.1）;
  (ii) **アクセント核母音で傾きが最急**（3.6）— 核は実現すべき下降幅が最大の座なので、
  同じ時間短縮がより大きな未達を生む; (iii) 効果が**言語・スタイルに非依存**（3.3/3.4）—
  調音-音調協調の時間的制約は言語普遍的な運動制約だから。excursion がターゲット批判に対する
  妥当な観測量である理由（movement を測り、単一ターゲットを前提しない）もここで述べる。
- **有意性 vs 効果量**の一般教訓（言語差の 3.4 が自己例示）。方法論的含意。
- **限界**: (a) 英語(Buckeye)と日本語(CSJ)の register 完全一致は未達 → 言語比較は探索的。
  (b) **CEJC 未取得**: 得られ次第 monologue→dialogue→conversational の3点勾配で案A強化。
  (c) speaker-specific pitch range は未適用（config 明示、フルレンジ固定で抽出）。

### 5. Conclusion
測り方を excursion に正すと、rate→F0 共変は知覚的に意味があり、測定・スタイル・言語に
頑健。有意性ではなく効果量で語るべき現象。

---

## Table 1 — Corpora (final, post-filter)
| Corpus | Language | Register | Speakers | Vowel tokens |
|---|---|---|---|---|
| CSJ Monologue | Japanese | spontaneous monologue | 31 | 81,687 |
| CSJ Dialogue  | Japanese | dialogue (1 talker/ch) | 18 | 21,558 |
| Buckeye       | English  | conversational | 40 | 274,273 |
| **Total** | | | **89** | **377,518** |

## Table 2 — Effect size vs JND (5–95% effective range, semitones)
主DV = landmark excursion。raw range はアーティファクト水増しのため対比用。
| Corpus | F0max | >0.5 | raw range | landmark | >JND1.0 | >JND1.5 | LM slope /100ms |
|---|---|---|---|---|---|---|---|
| CSJ Monologue | 0.67 | yes | 1.86 | **1.52** | yes | yes | 0.19 |
| Buckeye | 0.34 | **no** | 1.98 | **1.48** | yes | no | 0.38 |
| CSJ Dialogue | 0.55 | yes | 1.74 | **1.38** | yes | no | 0.20 |

## Figures (all in results/figures/)
- **Fig 1** `Fig1_max_vs_range.png` — DV argument, 3行: F0max（平坦/JND級）/ raw max-min（水増し）/ landmark excursion（JND1.0超）。
- **Fig 2** `Fig2_japanese_gradient.png` — Japanese style-invariance (Mono vs Dial + diff smooth).
- **Fig 3** `Fig3_robustness.png` — effect stable across excursion definitions.
- **Fig 4** `Fig4_language.png` — Japanese vs English generality.
- **Fig 5** `Fig5_accent_nucleus.png` — effect holds (steeper) on X-JToBI accent-nucleus vowels.
- **Fig 6** `Fig6_language_register.png` — register-closer (Dialogue vs Buckeye): parallel curves, difference smooth n.s.

## Supplementary
TableS_effect_size, TableS_robustness, TableS_language_test, TableS_AIC_study1/2,
TableS_kcheck_log, TableS_buckeye_control, TableS_jpgradient_*,
TableS_accent_nucleus, TableS_accent_threshold_sweep, accent_nucleus_report,
TableS_language_register, language_register_report,
TableS_N_audit_build/_models, csj_dial_channel_selection, diagnostics_summary,
build_dataset_report. Full pipeline reproducible via `scripts/run_all.sh`.
