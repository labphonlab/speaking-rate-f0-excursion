## 09_artifact_check.R — is the rate -> F0range effect a FRAME-COUNT artifact?
##
## Key concern: F0range = max - min over the VOICED frames of a
## vowel. Short vowels (fast speech) have fewer frames (num_valid), and with fewer
## samples of the underlying F0 trajectory the observed max-min is downward-biased
## by simple order-statistics. So the rate->range effect COULD be a sampling
## artifact rather than a real speech-rate effect. This script attacks that.
##
## (Named 09_ to avoid colliding with the existing 03_figures.R; the user referred
##  to it as "03_artifact_check.R".)
##
## Parts (this file = 1,2; the DECISIVE part 3 is src/artifact_resample.py):
##   1. per-corpus correlation Duration ~ num_valid (+ scatter). r>0.9 expected.
##   2a. add s(num_valid) as covariate to the main F0_range~s(Duration) model;
##       how much does the Duration effective range shrink? (report concurvity —
##       the two are near-collinear, so this is suggestive, not decisive.)
##   2b. FIX num_valid to a narrow band (5-7 frames): within that band, does
##       Duration still predict F0_range? If the effect vanishes when frame count
##       is held ~constant, the main effect is frame-count-driven.
##
## Outputs: results/supplement/TableS_artifact_check.csv
##          results/figures/Fig8_artifact_framecount.png
##          results/supplement/artifact_check_report.md  (part 3 appends to this)
## Run: Rscript src/analysis/09_artifact_check.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))

NTHREADS <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NTHREADS) != 1L || is.na(NTHREADS) || NTHREADS < 1L) NTHREADS <- 1L
K_DUR <- 20; K_FS <- 5; K_NV <- 10
sup <- repo_path(CONFIG$paths$supplement); fig <- repo_path(CONFIG$paths$figures)
dir.create(sup, showWarnings = FALSE, recursive = TRUE); dir.create(fig, showWarnings = FALSE, recursive = TRUE)
log_lines <- character(0)
say <- function(...) { m <- sprintf(...); message(m); log_lines[[length(log_lines) + 1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)
dat <- dat[!is.na(dat$F0_range_ST) & !is.na(dat$Duration) & !is.na(dat$num_valid), ]
CORP <- c("CSJ Monologue", "Buckeye", "CSJ Dialogue")

## 5-95% effective range of a fitted s(Duration) smooth + slope + endpoints.
eff_dur <- function(m, dur, term = "s(Duration)") {
  grid <- seq(min(dur), max(dur), length.out = 200)
  nv <- if (!is.null(m$model$num_valid)) median(m$model$num_valid) else 5
  nd <- data.frame(Duration = grid, num_valid = nv,
                   Speaker = factor(levels(m$model$Speaker)[1], levels = levels(m$model$Speaker)),
                   Vowel   = factor(levels(m$model$Vowel)[1],   levels = levels(m$model$Vowel)))
  pr <- predict(m, nd, type = "terms")
  cc <- which(colnames(pr) == term); q <- quantile(dur, c(0.05, 0.95))
  in95 <- grid >= q[1] & grid <= q[2]
  list(eff = max(pr[in95, cc]) - min(pr[in95, cc]),
       slope = unname(coef(lm(pr[, cc] ~ grid))[2]) * 0.1)
}

part1 <- list(); part2 <- list()
for (cp in CORP) {
  d <- droplevels(subset(dat, Dataset == cp))
  d$Speaker <- factor(d$Speaker); d$Vowel <- factor(d$Vowel)

  ## ---- Part 1: Duration vs num_valid correlation ----
  r_p <- cor(d$Duration, d$num_valid, method = "pearson")
  r_s <- cor(d$Duration, d$num_valid, method = "spearman")
  say("%-14s cor(Duration,num_valid): pearson=%.3f spearman=%.3f (N=%d)", cp, r_p, r_s, nrow(d))
  part1[[cp]] <- data.frame(Dataset = cp, N = nrow(d),
    pearson_r = round(r_p, 3), spearman_r = round(r_s, 3),
    num_valid_min = min(d$num_valid), num_valid_med = median(d$num_valid),
    num_valid_max = max(d$num_valid))

  ## ---- Part 2a: add s(num_valid) covariate; Duration effect shrinkage ----
  m_base <- bam(F0_range_ST ~ s(Duration, k = K_DUR) +
                  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re"),
                data = d, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
  m_ctrl <- bam(F0_range_ST ~ s(Duration, k = K_DUR) + s(num_valid, k = K_NV) +
                  s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re"),
                data = d, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
  eb <- eff_dur(m_base, d$Duration); ec <- eff_dur(m_ctrl, d$Duration)
  ## concurvity of the two 1-D smooths (0=none, 1=total collinearity)
  cc <- tryCatch({
    cm <- concurvity(m_ctrl, full = FALSE)$estimate
    rn <- rownames(cm); cn <- colnames(cm)
    ri <- grep("s\\(Duration\\)$", rn); ci <- grep("s\\(num_valid\\)", cn)
    if (length(ri) && length(ci)) cm[ri[1], ci[1]] else NA_real_
  }, error = function(e) NA_real_)
  shrink <- (eb$eff - ec$eff) / eb$eff
  say("%-14s Duration eff: base=%.2f -> +s(num_valid)=%.2f st (shrink %.0f%%); concurvity=%.2f",
      cp, eb$eff, ec$eff, 100 * shrink, cc)

  ## ---- Part 2b: fix num_valid to a narrow band [5,7]; Duration effect within ----
  band <- droplevels(subset(d, num_valid >= 5 & num_valid <= 7))
  dur_q <- quantile(band$Duration, c(0.05, 0.95))
  dur_spread <- unname(dur_q[2] - dur_q[1])
  m_band <- bam(F0_range_ST ~ s(Duration, k = 10) + s(Speaker, bs = "re") + s(Vowel, bs = "re"),
                data = band, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
  ## Duration eff over the band's own 5-95% duration window
  gb <- seq(min(band$Duration), max(band$Duration), length.out = 200)
  ndb <- data.frame(Duration = gb,
                    Speaker = factor(levels(band$Speaker)[1], levels = levels(band$Speaker)),
                    Vowel   = factor(levels(band$Vowel)[1],   levels = levels(band$Vowel)))
  prb <- predict(m_band, ndb, type = "terms"); ccb <- which(colnames(prb) == "s(Duration)")
  inb <- gb >= dur_q[1] & gb <= dur_q[2]
  eff_band <- max(prb[inb, ccb]) - min(prb[inb, ccb])
  sdur_p <- summary(m_band)$s.table[grep("s\\(Duration\\)", rownames(summary(m_band)$s.table))[1], "p-value"]
  say("%-14s band[num_valid 5-7]: N=%d, Duration spread(5-95)=%.0fms, within-band Duration eff=%.2f st (s(Duration) p=%.2g)",
      cp, nrow(band), 1000 * dur_spread, eff_band, sdur_p)

  part2[[cp]] <- data.frame(Dataset = cp,
    dur_eff_base_st = round(eb$eff, 3), dur_eff_ctrl_numvalid_st = round(ec$eff, 3),
    shrink_pct = round(100 * shrink, 1), concurvity_dur_numvalid = round(cc, 3),
    band_N = nrow(band), band_dur_spread_ms = round(1000 * dur_spread, 0),
    band_within_dur_eff_st = round(eff_band, 3), band_dur_p = signif(sdur_p, 3))
}

t1 <- do.call(rbind, part1); t2 <- do.call(rbind, part2)
tab <- merge(t1, t2, by = "Dataset")
write.csv(tab, file.path(sup, "TableS_artifact_check.csv"), row.names = FALSE)

## ---- scatter figure: Duration vs num_valid, per corpus ----
png(file.path(fig, "Fig8_artifact_framecount.png"), width = 1500, height = 560, res = 150)
op <- par(mfrow = c(1, 3), mar = c(4.3, 4.3, 3, 1))
set.seed(1)
for (cp in CORP) {
  d <- subset(dat, Dataset == cp)
  idx <- sample(nrow(d), min(4000, nrow(d)))
  plot(d$Duration[idx], d$num_valid[idx], pch = 16, col = "#1F3B6322", cex = 0.5,
       xlab = "Duration (s)", ylab = "num_valid (voiced frames)",
       main = sprintf("%s\nr=%.3f", cp, t1$pearson_r[t1$Dataset == cp]))
  abline(lm(num_valid ~ Duration, data = d), col = "#C1440E", lwd = 2)
  abline(h = c(5, 7), col = "grey50", lty = 3)  # the part-2b band
}
par(op); dev.off()
say("wrote Fig8_artifact_framecount.png")

## ---- report (part 3 appends) ----
verdict2 <- all(t2$band_within_dur_eff_st > JND_STATIC[2])
rep <- c("# F0range frame-count artifact check", "",
  "Q: is rate->F0range just a sampling artifact (fewer frames in short vowels =>",
  "downward-biased max-min)? Parts 1-2 below; the DECISIVE resampling test is",
  "part 3 (src/artifact_resample.py, appended).", "",
  "## Part 1 — Duration vs num_valid correlation")
for (i in seq_len(nrow(t1))) rep <- c(rep, sprintf(
  "- %-14s pearson r=%.3f, spearman=%.3f (num_valid median=%d, range %d-%d)",
  t1$Dataset[i], t1$pearson_r[i], t1$spearman_r[i], t1$num_valid_med[i],
  t1$num_valid_min[i], t1$num_valid_max[i]))
rep <- c(rep, "",
  "## Part 2a — add s(num_valid) covariate (NOTE: near-collinear => concurvity high;",
  "shrinkage is an UPPER bound on the artifact, not proof)")
for (i in seq_len(nrow(t2))) rep <- c(rep, sprintf(
  "- %-14s Duration eff %.2f -> %.2f st (shrink %.0f%%), concurvity(Dur,num_valid)=%.2f",
  t2$Dataset[i], t2$dur_eff_base_st[i], t2$dur_eff_ctrl_numvalid_st[i],
  t2$shrink_pct[i], t2$concurvity_dur_numvalid[i]))
rep <- c(rep, "",
  "## Part 2b — within a fixed num_valid band [5-7 frames], does Duration still predict F0range?")
for (i in seq_len(nrow(t2))) rep <- c(rep, sprintf(
  "- %-14s N=%d, Duration spread(5-95)=%dms, within-band Duration eff=%.2f st (p=%.2g)",
  t2$Dataset[i], t2$band_N[i], t2$band_dur_spread_ms[i],
  t2$band_within_dur_eff_st[i], t2$band_dur_p[i]))
rep <- c(rep, "",
  sprintf("## interim verdict (parts 1-2): within a fixed frame-count band, Duration %s predict F0range (eff %s JND1.0 in all corpora).",
          if (verdict2) "STILL DOES" else "does NOT clearly",
          if (verdict2) "still clears" else "falls below"),
  "Concurvity makes part-2a shrinkage only suggestive; part 3 (resampling) is decisive.",
  "", "## log", paste0("    ", log_lines))
writeLines(rep, file.path(sup, "artifact_check_report.md"))
cat("\n===== TableS_artifact_check =====\n"); print(tab, row.names = FALSE)
say("DONE (parts 1-2). Run src/artifact_resample.py for the decisive part 3.")
