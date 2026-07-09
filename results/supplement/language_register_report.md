# Cross-linguistic test under tighter register matching (Dialogue vs Buckeye)

Register-closer study = CSJ Dialogue (JP, dialogic) + Buckeye (EN, conversational). DV = F0_excursion_LM_ST (frame-count-robust). N=298971.
This is the within-data substitute for a register-matched cross-linguistic
comparison; CEJC (conversational Japanese) would provide the ideal third point.

## results
- Japanese (CSJ Dialogue): 5-95% eff = 1.44 st, slope = 0.237 st/100ms
- English (Buckeye):       5-95% eff = 1.48 st, slope = 0.385 st/100ms
- difference smooth s(Duration):LanguageO p = 0.0107
- language level (intercept) term p = 0.312
- JP-EN eff gap: register-closer = 0.04 st (register-mismatched Mono-vs-Buckeye = 0.27 st)

## verdict: GENERALISES IN MAGNITUDE UNDER TIGHTER REGISTER MATCHING — with the register-closer pair (CSJ Dialogue vs conversational Buckeye) the effect is JND-exceeding in BOTH languages (JP 1.44 vs EN 1.48 st, gap 0.04 st). (register-mismatched Mono-vs-Buckeye gap was 0.27 st.) The difference smooth is 'significant' (p=0.01) but at N=298971 this reflects power, not a perceptually meaningful language difference (cf. the effect-size concern). The point of the register-closer pair is that language cannot be confounded with style here as it is in the monologue-vs-Buckeye contrast, yet the effect still holds in both languages. CEJC would add a third register point but is not required.

## log
    register-closer study (CSJ Dialogue + Buckeye): N=298971  English=274239  Japanese=24732
    Language level term p=0.312 ; difference smooth s(Duration):LanguageO p=0.0107
    Japanese: 5-95% eff = 1.44 st, slope = 0.237 st/100ms (N=24732, spk=18)
    English: 5-95% eff = 1.48 st, slope = 0.385 st/100ms (N=274239, spk=40)
    wrote Fig6_language_register.png
