## 01_fit_models.R — GAMM fits for the rate -> F0 covariation study.
## Ported from the old Colab Cells 4-5, with the resubmission changes applied.
##
## DV CHANGE: primary DV is now F0_excursion_LM_ST (fixed-landmark excursion),
##   NOT F0max or raw max-min. Rationale: raw max-min F0range is a frame-count
##   artifact (09_artifact_check.R); the landmark excursion (5 fixed proportional
##   points, time-scale invariant) is robust and still clears the JND (1.38-1.52 st).
##   Addresses "max is not excursion" and the effect-size question.
##
## Design change from #4 (see diagnostics_summary.md): CSJ Dialogue speaker =
##   session (18 speakers, one talker per file). The OLD Task C "session variance
##   component" is therefore moot (session == speaker, no nesting) and is replaced
##   by the Japanese style gradient (Task C', 案A: Monologue vs Dialogue).
##
## Method choice on this OpenMP-less machine: everything uses fREML + discrete=TRUE
##   (nthreads from config). Model comparisons that differ ONLY in random-effects
##   structure use REML/fREML AIC (valid: identical fixed effects). Comparisons
##   that ADD a fixed effect (NextVoiceless, Style) are judged by that term's
##   significance from a single fit, not by REML-AIC.
##
## Inputs : master_csv
## Outputs: results/supplement/  (N-audit, AIC tables, k-check log, term tests)
##          results/supplement/fit_models_*.rds
## Run: Rscript src/analysis/01_fit_models.R

suppressWarnings(suppressMessages({ library(mgcv); library(dplyr) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))

NTHREADS <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NTHREADS) != 1L || is.na(NTHREADS) || NTHREADS < 1L) NTHREADS <- 1L

DV <- "F0_excursion_LM_ST"                # <-- frame-count-robust landmark excursion
                                          #     (was F0_range_ST; see 09_artifact_check)
K_DUR <- 20; K_FS <- 5

sup <- repo_path(CONFIG$paths$supplement)
dir.create(sup, showWarnings = FALSE, recursive = TRUE)
AUDIT <- file.path(sup, "TableS_N_audit_models.csv")
if (file.exists(AUDIT)) file.remove(AUDIT)

log_lines <- character(0)
say <- function(...) { m <- sprintf(...); message(m); log_lines[[length(log_lines) + 1L]] <<- m }
say("01_fit_models | DV=%s | nthreads=%d | fREML+discrete", DV, NTHREADS)

## --------------------------------------------------------------- helpers ----
record_audit <- function(model, model_id, study, input_df) {
  row <- data.frame(model_id = model_id, study = study,
                    n_input = nrow(input_df), n_used = as.integer(nobs(model)),
                    n_dropped = nrow(input_df) - as.integer(nobs(model)),
                    n_speakers = length(unique(input_df$Speaker)))
  write.table(row, AUDIT, sep = ",", append = file.exists(AUDIT),
              col.names = !file.exists(AUDIT), row.names = FALSE)
  say("[N-audit] %-16s (study %s) n_input=%d n_used=%d n_spk=%d",
      model_id, study, nrow(input_df), as.integer(nobs(model)), row$n_speakers)
}

fit_bam <- function(formula, data, mod_id, study) {
  say("fitting %s ...", mod_id)
  m <- bam(formula, data = data, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
  record_audit(m, mod_id, study, data)
  m
}

## Effective 5-95% range (st) of the population s(Duration), reused from concept
## in 02. Returns the robust effect size for a fitted model.
eff_range_595 <- function(model, dur) {
  grid <- seq(min(dur), max(dur), length.out = 200)
  mf <- model$model
  resp <- names(mf)[1]
  ## build newdata covering EVERY predictor: Duration = grid, factors -> first
  ## level, ordered -> first level, other numerics -> median. This keeps
  ## predict() happy regardless of which control terms a model carries.
  nd <- data.frame(Duration = grid)
  for (v in setdiff(names(mf), c(resp, "Duration"))) {
    col <- mf[[v]]
    nd[[v]] <- if (is.ordered(col)) ordered(levels(col)[1], levels = levels(col))
      else if (is.factor(col)) factor(levels(col)[1], levels = levels(col))
      else stats::median(col, na.rm = TRUE)
  }
  pr <- predict(model, newdata = nd, type = "terms")
  cc <- which(colnames(pr) == "s(Duration)")
  if (!length(cc)) return(NA_real_)
  q <- quantile(dur, c(0.05, 0.95)); in95 <- grid >= q[1] & grid <= q[2]
  max(pr[in95, cc]) - min(pr[in95, cc])
}

## ----------------------------------------------------------------- data ----
master_path <- repo_path(CONFIG$paths$master_csv)
if (!file.exists(master_path)) stop("master_csv not found; run build_dataset.py")
dat <- read.csv(master_path, stringsAsFactors = FALSE)
say("loaded master: %d rows", nrow(dat))

for (c in c("Speaker", "Vowel", "Language", "Dataset")) dat[[c]] <- as.factor(dat[[c]])
dat <- dat[!is.na(dat[[DV]]) & !is.na(dat$Duration), ]
dat$DV <- dat[[DV]]

need <- function(d, cols) d[complete.cases(d[, cols]), ] %>% droplevels()

study1 <- need(subset(dat, Dataset %in% c("CSJ Monologue", "Buckeye")),
               c("DV", "Duration", "Speaker", "Vowel", "Language"))   # cross-language (案B)
study2 <- need(subset(dat, Dataset == "CSJ Dialogue"),
               c("DV", "Duration", "Speaker", "Vowel"))               # dialogue alone
jpgrad <- subset(dat, Dataset %in% c("CSJ Monologue", "CSJ Dialogue"))# 案A gradient
jpgrad$Style  <- factor(ifelse(jpgrad$Dataset == "CSJ Monologue", "Monologue", "Dialogue"),
                        levels = c("Monologue", "Dialogue"))
jpgrad$StyleO <- ordered(jpgrad$Style, levels = c("Monologue", "Dialogue"))
jpgrad <- need(jpgrad, c("DV", "Duration", "Speaker", "Vowel", "Style"))
say("subsets: study1(cross-lang)=%d  study2(dialogue)=%d  jpgrad(mono+dial)=%d",
    nrow(study1), nrow(study2), nrow(jpgrad))

## ====================================================== Task A: RE struct ==
## full (by-speaker rate curves, fs) vs base (speaker intercept only, re).
## Fixed effects identical -> REML/fREML AIC valid.
say("\n== Task A: random-effects structure (full fs vs base re), fREML-AIC ==")

f1_full <- DV ~ Language + s(Duration, by = Language, k = K_DUR) +
  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re")
f1_base <- DV ~ Language + s(Duration, by = Language, k = K_DUR) +
  s(Speaker, bs = "re") + s(Vowel, bs = "re")
m1_full <- fit_bam(f1_full, study1, "s1_full", "1")
m1_base <- fit_bam(f1_base, study1, "s1_base", "1")
aic1 <- AIC(m1_full, m1_base); aic1$model <- rownames(aic1)
write.csv(aic1, file.path(sup, "TableS_AIC_study1.csv"), row.names = FALSE)
say("study1 AIC: full=%.1f base=%.1f (Δ=%.1f, %s favored)",
    AIC(m1_full), AIC(m1_base), AIC(m1_full) - AIC(m1_base),
    ifelse(AIC(m1_full) < AIC(m1_base), "full", "base"))

f2_full <- DV ~ s(Duration, k = K_DUR) +
  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re")
f2_base <- DV ~ s(Duration, k = K_DUR) + s(Speaker, bs = "re") + s(Vowel, bs = "re")
m2_full <- fit_bam(f2_full, study2, "s2_full", "2")
m2_base <- fit_bam(f2_base, study2, "s2_base", "2")
aic2 <- AIC(m2_full, m2_base); aic2$model <- rownames(aic2)
write.csv(aic2, file.path(sup, "TableS_AIC_study2.csv"), row.names = FALSE)
say("study2 AIC: full=%.1f base=%.1f (Δ=%.1f, %s favored)",
    AIC(m2_full), AIC(m2_base), AIC(m2_full) - AIC(m2_base),
    ifelse(AIC(m2_full) < AIC(m2_base), "full", "base"))

saveRDS(m1_full, file.path(sup, "fit_models_s1_full.rds"))
saveRDS(m2_full, file.path(sup, "fit_models_s2_full.rds"))

## ====================================================== Task B: k-check ====
say("\n== Task B: gam.check (k adequacy) on full models ==")
sink(file.path(sup, "TableS_kcheck_log.txt"))
cat("### study1 full ###\n"); print(k.check(m1_full))
cat("\n### study2 full ###\n"); print(k.check(m2_full))
sink()
say("k-check -> TableS_kcheck_log.txt")

## ============================= Task C' (案A): Japanese style gradient =======
## Replaces old session-variance task (moot after #4). Ordered-factor difference
## smooth tests whether the rate->range curve differs Monologue vs Dialogue.
say("\n== Task C': Japanese gradient Monologue vs Dialogue (difference smooth) ==")
fC <- DV ~ Style + s(Duration, k = K_DUR) + s(Duration, by = StyleO, k = K_DUR) +
  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re")
mC <- fit_bam(fC, jpgrad, "jp_gradient", "C")
saveRDS(mC, file.path(sup, "fit_models_jp_gradient.rds"))
sC <- summary(mC)
## parametric Style term (level shift) + difference smooth (shape change)
diff_row <- grep("StyleO", rownames(sC$s.table))
ptab <- as.data.frame(sC$p.table); ptab$term <- rownames(ptab)
stab <- as.data.frame(sC$s.table); stab$term <- rownames(stab)
write.csv(ptab, file.path(sup, "TableS_jpgradient_ptable.csv"), row.names = FALSE)
write.csv(stab, file.path(sup, "TableS_jpgradient_stable.csv"), row.names = FALSE)
say("jp-gradient: Style level term p=%.3g ; difference-smooth s(Duration):StyleO p=%.3g",
    ptab[grep("Style", ptab$term)[1], "Pr(>|t|)"],
    if (length(diff_row)) sC$s.table[diff_row, "p-value"] else NA_real_)

## per-style effective range (fit separate simple models for a clean number)
for (st in c("Monologue", "Dialogue")) {
  d <- droplevels(subset(jpgrad, Style == st))
  ms <- fit_bam(DV ~ s(Duration, k = K_DUR) +
                  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re"),
                d, sprintf("jp_%s", tolower(st)), "C")
  say("  %s: 5-95%% effective range = %.2f st (N=%d, spk=%d)",
      st, eff_range_595(ms, ms$model$Duration), nrow(d), length(unique(d$Speaker)))
}

## ===================================== Task D: Buckeye segmental control ====
## Pre-fortis clipping: does following-consonant voicing confound the effect?
## Judge by the NextVoiceless term significance (adds a fixed effect -> not AIC).
say("\n== Task D: Buckeye segmental control (NextVoiceless) ==")
vl <- c("p", "t", "k", "f", "th", "s", "sh", "ch", "hh")
bk <- droplevels(subset(dat, Dataset == "Buckeye"))
bk$NextVoiceless <- factor(ifelse(trimws(as.character(bk$NextSeg)) %in% vl,
                                  "Voiceless", "Voiced"), levels = c("Voiced", "Voiceless"))
bk <- need(bk, c("DV", "Duration", "Speaker", "Vowel", "NextVoiceless"))

f_bk_base <- DV ~ s(Duration, k = K_DUR) +
  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re")
f_bk_ctrl <- DV ~ NextVoiceless + s(Duration, k = K_DUR) +
  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re")
m_bk_base <- fit_bam(f_bk_base, bk, "buck_base", "D")
m_bk_ctrl <- fit_bam(f_bk_ctrl, bk, "buck_ctrl", "D")
sbk <- summary(m_bk_ctrl)
coef_vl <- sbk$p.table[grep("Voiceless", rownames(sbk$p.table)), , drop = FALSE]
eff_base <- eff_range_595(m_bk_base, m_bk_base$model$Duration)
eff_ctrl <- eff_range_595(m_bk_ctrl, m_bk_ctrl$model$Duration)
res_bk <- data.frame(
  coef_Voiceless_st = round(coef_vl[1, "Estimate"], 3),
  p_Voiceless = signif(coef_vl[1, "Pr(>|t|)"], 3),
  eff_range_no_ctrl_st = round(eff_base, 3),
  eff_range_with_ctrl_st = round(eff_ctrl, 3),
  eff_range_shift_st = round(eff_ctrl - eff_base, 3))
write.csv(res_bk, file.path(sup, "TableS_buckeye_control.csv"), row.names = FALSE)
say("Buckeye: NextVoiceless coef=%.3f st (p=%.3g); Duration eff-range %.2f -> %.2f st (shift %.2f)",
    res_bk$coef_Voiceless_st, res_bk$p_Voiceless,
    eff_base, eff_ctrl, res_bk$eff_range_shift_st)

## ---------------------------------------------------------------- report ----
writeLines(c("# 01_fit_models report", "",
             sprintf("DV = %s (semitone excursion). Method: fREML + discrete.", DV),
             "", "## log", paste0("    ", log_lines)),
           file.path(sup, "fit_models_report.md"))
say("\nDONE. outputs in %s", sup)
