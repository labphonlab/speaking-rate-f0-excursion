# 01_fit_models report

DV = F0_excursion_LM_ST (semitone excursion). Method: fREML + discrete.

## log
    01_fit_models | DV=F0_excursion_LM_ST | nthreads=1 | fREML+discrete
    loaded master: 392163 rows
    subsets: study1(cross-lang)=367390  study2(dialogue)=24732  jpgrad(mono+dial)=117883
    
== Task A: random-effects structure (full fs vs base re), fREML-AIC ==
    fitting s1_full ...
    [N-audit] s1_full          (study 1) n_input=367390 n_used=367390 n_spk=71
    fitting s1_base ...
    [N-audit] s1_base          (study 1) n_input=367390 n_used=367390 n_spk=71
    study1 AIC: full=1212824.1 base=1219259.5 (Δ=-6435.4, full favored)
    fitting s2_full ...
    [N-audit] s2_full          (study 2) n_input=24732 n_used=24732 n_spk=18
    fitting s2_base ...
    [N-audit] s2_base          (study 2) n_input=24732 n_used=24732 n_spk=18
    study2 AIC: full=80803.9 base=81277.3 (Δ=-473.4, full favored)
    
== Task B: gam.check (k adequacy) on full models ==
    k-check -> TableS_kcheck_log.txt
    
== Task C': Japanese gradient Monologue vs Dialogue (difference smooth) ==
    fitting jp_gradient ...
    [N-audit] jp_gradient      (study C) n_input=117883 n_used=117883 n_spk=49
    jp-gradient: Style level term p=0.35 ; difference-smooth s(Duration):StyleO p=0.536
    fitting jp_monologue ...
    [N-audit] jp_monologue     (study C) n_input=93151 n_used=93151 n_spk=31
      Monologue: 5-95% effective range = 1.76 st (N=93151, spk=31)
    fitting jp_dialogue ...
    [N-audit] jp_dialogue      (study C) n_input=24732 n_used=24732 n_spk=18
      Dialogue: 5-95% effective range = 1.44 st (N=24732, spk=18)
    
== Task D: Buckeye segmental control (NextVoiceless) ==
    fitting buck_base ...
    [N-audit] buck_base        (study D) n_input=274239 n_used=274239 n_spk=40
    fitting buck_ctrl ...
    [N-audit] buck_ctrl        (study D) n_input=274239 n_used=274239 n_spk=40
    Buckeye: NextVoiceless coef=0.126 st (p=7.45e-112); Duration eff-range 1.48 -> 1.49 st (shift 0.01)
