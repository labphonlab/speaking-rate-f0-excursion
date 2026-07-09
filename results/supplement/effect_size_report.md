# Effect-size report (effect size vs significance)

F0 JND bands (config.jnd): static 0.5-1 st / movement 1-1.5 st.
Static = level-discrimination JND; movement = pitch-movement relevance
threshold ('t Hart 1981, ~1.5 st) — the stricter yardstick for an excursion DV.
Judge on the robust 5-95% effective range.

- CSJ Monologue max: 実効幅(5-95)=0.68 st, 傾き=-0.586 st/100ms [速い側でレンジ拡大], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=未 1.5=未
- CSJ Monologue range: 実効幅(5-95)=2.16 st, 傾き=0.452 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=超
- CSJ Monologue landmark: 実効幅(5-95)=1.76 st, 傾き=0.250 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=超
- Buckeye max: 実効幅(5-95)=0.34 st, 傾き=0.121 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=未 1.0=未 1.5=未
- Buckeye range: 実効幅(5-95)=1.98 st, 傾き=0.557 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=超
- Buckeye landmark: 実効幅(5-95)=1.48 st, 傾き=0.385 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=未
- CSJ Dialogue max: 実効幅(5-95)=0.60 st, 傾き=-0.082 st/100ms [速い側でレンジ拡大], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=未 1.5=未
- CSJ Dialogue range: 実効幅(5-95)=1.90 st, 傾き=0.440 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=超
- CSJ Dialogue landmark: 実効幅(5-95)=1.44 st, 傾き=0.237 st/100ms [速い側でレンジ縮小], JND(JND0.5/JND1.0/JND1.5) 0.5=超 1.0=超 1.5=未

## 解釈フラグ（案A/案B分岐用）
- flag_max_flat: FALSE (全コーパスで F0max の 5-95 実効幅 < 0.5 st か)
- flag_range_shrinks: CSJ Monologue: sign(p5-p95)=-2.19 st -> fast側でレンジ縮小(shrinks_when_fast) | Buckeye: sign(p5-p95)=-2.01 st -> fast側でレンジ縮小(shrinks_when_fast) | CSJ Dialogue: sign(p5-p95)=-1.93 st -> fast側でレンジ縮小(shrinks_when_fast)
- flag_max_range_diverge: CSJ Monologue: slope max=-0.586 vs range=0.452 st/100ms [符号が逆] | Buckeye: slope max=0.121 vs range=0.557 st/100ms | CSJ Dialogue: slope max=-0.082 vs range=0.440 st/100ms [符号が逆]

## N-audit / log
    effect-size run | nthreads=1 | JND static=0.5-1 / movement=1-1.5 st | thresholds=0.5,1,1.5
    loaded master_csv: 392163 rows, cols = Dataset,Language,FileID,Speaker,Session,Channel,Vowel,Duration,Tmin,Tmax,f0_max,f0_min,f0_mean,f0_range,f0_p5,f0_p95,f0_sd,num_valid,has_jump,f0_lm_min,f0_lm_max,n_lm,Intensity_Max,Intensity_Mean,Intensity_Range,PrevSeg,NextSeg,PrevIsPause,NextIsPause,HasTone,AccentDist,AccentNucleus,AccentNear,Flag_Dur,Flag_Unvoiced,Flag_Sparse,Flag_Jump,Exclude,F0_ST,F0_range_ST,F0_excursion_LM_ST,F0_LMmax_ST,F0_LMmin_ST,F0_rangeP_ST,F0_Min_Winsor,F0_rangeW_ST,Flag_MinSuspect,F0_Max_Winsor,F0_ST_Winsor,Duration_Between,Duration_Within
    [N-audit] CSJ Monologue / max          n_input=93156 n_used=93156 n_dropped=0 n_speakers=31
    [N-audit] CSJ Monologue / range        n_input=93156 n_used=93156 n_dropped=0 n_speakers=31
    [N-audit] CSJ Monologue / landmark     n_input=93156 n_used=93151 n_dropped=5 n_speakers=31
    [N-audit] Buckeye / max                n_input=274273 n_used=274273 n_dropped=0 n_speakers=40
    [N-audit] Buckeye / range              n_input=274273 n_used=274271 n_dropped=2 n_speakers=40
    [N-audit] Buckeye / landmark           n_input=274273 n_used=274239 n_dropped=34 n_speakers=40
    [N-audit] CSJ Dialogue / max           n_input=24734 n_used=24734 n_dropped=0 n_speakers=18
    [N-audit] CSJ Dialogue / range         n_input=24734 n_used=24734 n_dropped=0 n_speakers=18
    [N-audit] CSJ Dialogue / landmark      n_input=24734 n_used=24732 n_dropped=2 n_speakers=18
    wrote TableS_effect_size.csv (9 rows)
    wrote effect_size_partial.png
    axis: CSJ Monologue/max: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: CSJ Monologue/range: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: CSJ Monologue/landmark: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: Buckeye/max: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: Buckeye/range: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: Buckeye/landmark: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: CSJ Dialogue/max: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: CSJ Dialogue/range: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
    axis: CSJ Dialogue/landmark: partial effect dips below 0 (centered smooth; 0 = corpus mean level)
