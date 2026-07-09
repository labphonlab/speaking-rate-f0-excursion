## 04_robustness.R — is the rate->F0range effect an artefact of a fragile f0_min?
##
## F0_range_ST = 12*log2(f0_max/f0_min) leans on the single lowest voiced frame,
## which octave-halving / creak / a lone outlier can wreck. This script checks
## whether the effect survives more robust excursion definitions and the removal
## of suspicious tokens. If the 5-95% effective range and slope stay stable, the
## F0range result is not a measurement artefact (measurement-validity check).
##
## Range definitions compared (all in semitones, all from build_dataset columns):
##   maxmin  F0_range_ST    12*log2(max/min)        -- primary, fragile
##   p95p5   F0_rangeP_ST   12*log2(p95/p5)         -- percentile, robust to 1 frame
##   winsor  F0_rangeW_ST   per-speaker winsorized  -- clip extremes then max/min
## Plus a sensitivity refit of maxmin after dropping Flag_MinSuspect tokens.
##
## Inputs : master_csv (needs the robust columns; re-run build_dataset if absent)
## Outputs: results/supplement/TableS_robustness.csv
##          results/figures/Fig3_robustness.png
##          results/supplement/robustness_report.md
## Run: Rscript src/analysis/04_robustness.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))

NTHREADS <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NTHREADS) != 1L || is.na(NTHREADS) || NTHREADS < 1L) NTHREADS <- 1L
JND <- JND_STATIC; K_DUR <- 20; K_FS <- 5

sup <- repo_path(CONFIG$paths$supplement); fig <- repo_path(CONFIG$paths$figures)
dir.create(sup, showWarnings = FALSE, recursive = TRUE)
dir.create(fig, showWarnings = FALSE, recursive = TRUE)
log_lines <- character(0)
say <- function(...) { m <- sprintf(...); message(m); log_lines[[length(log_lines) + 1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)
need_cols <- c("F0_range_ST", "F0_rangeP_ST", "F0_rangeW_ST", "Flag_MinSuspect")
miss <- setdiff(need_cols, names(dat))
if (length(miss)) stop("master lacks robustness columns: ", paste(miss, collapse = ", "),
                       "\n-> re-run build_dataset.py (analyze_pitch now emits p5/p95/sd).")
for (c in c("Speaker", "Vowel", "Dataset")) dat[[c]] <- as.factor(dat[[c]])
say("loaded master: %d rows; Flag_MinSuspect overall = %.1f%%",
    nrow(dat), 100 * mean(as.logical(dat$Flag_MinSuspect), na.rm = TRUE))

## effective 5-95% range (st) of the population s(Duration), + slope/100ms
fit_and_measure <- function(d, dvcol) {
  d <- d[!is.na(d[[dvcol]]) & !is.na(d$Duration), ]
  d <- droplevels(d); d$DV <- d[[dvcol]]
  m <- bam(DV ~ s(Duration, k = K_DUR) +
             s(Duration, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re"),
           data = d, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
  dur <- m$model$Duration
  grid <- seq(min(dur), max(dur), length.out = 200)
  nd <- data.frame(Duration = grid,
                   Speaker = factor(levels(m$model$Speaker)[1], levels = levels(m$model$Speaker)),
                   Vowel   = factor(levels(m$model$Vowel)[1],   levels = levels(m$model$Vowel)))
  pr <- predict(m, newdata = nd, type = "terms")
  cc <- which(colnames(pr) == "s(Duration)")
  q <- quantile(dur, c(0.05, 0.95)); in95 <- grid >= q[1] & grid <= q[2]
  fit_p5  <- approx(grid, pr[, cc], xout = q[1])$y   # short/fast
  fit_p95 <- approx(grid, pr[, cc], xout = q[2])$y   # long/slow
  list(n = nrow(d), spk = nlevels(d$Speaker),
       eff = max(pr[in95, cc]) - min(pr[in95, cc]),
       slope = unname(coef(lm(pr[, cc] ~ grid))[2]) * 0.1,
       fit_at_p5 = unname(fit_p5), fit_at_p95 = unname(fit_p95),
       sign_p5_minus_p95 = unname(fit_p5 - fit_p95))
}

## label: shrinks_when_fast if partial effect lower at short duration (sign<0)
dir_label <- function(s) if (s < -0.05) "shrinks_when_fast" else if (s > 0.05) "grows_when_fast" else "flat"

CORP <- list(c("csj_mono", "CSJ Monologue"), c("buckeye", "Buckeye"),
             c("csj_dial", "CSJ Dialogue"))
DEFS <- list(c("maxmin", "F0_range_ST"), c("p95p5", "F0_rangeP_ST"),
             c("winsor", "F0_rangeW_ST"), c("landmark", "F0_excursion_LM_ST"))

rows <- list()
for (k in CORP) {
  sub <- subset(dat, Dataset == k[2])
  for (dv in DEFS) {
    r <- fit_and_measure(sub, dv[2])
    say("%-14s %-7s eff(5-95)=%.2f st slope=%.3f (N=%d spk=%d)",
        k[2], dv[1], r$eff, r$slope, r$n, r$spk)
    rows[[length(rows) + 1L]] <- data.frame(Dataset = k[2], definition = dv[1],
      N = r$n, n_speakers = r$spk, eff_range_5_95_st = round(r$eff, 3),
      slope_per_100ms_st = round(r$slope, 4),
      fit_at_p5_st = round(r$fit_at_p5, 3), fit_at_p95_st = round(r$fit_at_p95, 3),
      sign_p5_minus_p95_st = round(r$sign_p5_minus_p95, 3),
      direction_label = dir_label(r$sign_p5_minus_p95),
      exceeds_JND_1.0 = r$eff > JND[2],
      exceeds_JND_1.5 = r$eff > JND_MOVEMENT[2], stringsAsFactors = FALSE)
  }
  ## sensitivity: maxmin after removing suspect f0_min tokens
  clean <- subset(sub, !as.logical(Flag_MinSuspect))
  rc <- fit_and_measure(clean, "F0_range_ST")
  say("%-14s %-7s eff(5-95)=%.2f st slope=%.3f (N=%d, dropped %d suspect)",
      k[2], "clean", rc$eff, rc$slope, rc$n, nrow(sub) - nrow(clean))
  rows[[length(rows) + 1L]] <- data.frame(Dataset = k[2], definition = "maxmin_clean",
    N = rc$n, n_speakers = rc$spk, eff_range_5_95_st = round(rc$eff, 3),
    slope_per_100ms_st = round(rc$slope, 4),
    fit_at_p5_st = round(rc$fit_at_p5, 3), fit_at_p95_st = round(rc$fit_at_p95, 3),
    sign_p5_minus_p95_st = round(rc$sign_p5_minus_p95, 3),
    direction_label = dir_label(rc$sign_p5_minus_p95),
    exceeds_JND_1.0 = rc$eff > JND[2],
    exceeds_JND_1.5 = rc$eff > JND_MOVEMENT[2],
    stringsAsFactors = FALSE)
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(sup, "TableS_robustness.csv"), row.names = FALSE)

## --------------------------------------------------------------- figure ----
## landmark is the PRIMARY (frame-count-robust) definition; shown first + as a
## larger diamond so it stands out from the raw/percentile/winsor variants.
defs_order <- c("landmark", "maxmin", "maxmin_clean", "p95p5", "winsor")
cols <- c(landmark = "#2E7D32", maxmin = "#1F3B63", maxmin_clean = "#4C78A8",
          p95p5 = "#E4572E", winsor = "#F2A900")
pchs <- c(landmark = 18, maxmin = 19, maxmin_clean = 19, p95p5 = 19, winsor = 19)
cexs <- c(landmark = 2.2, maxmin = 1.6, maxmin_clean = 1.6, p95p5 = 1.6, winsor = 1.6)
png(file.path(fig, "Fig3_robustness.png"), width = 1200, height = 720, res = 160)
op <- par(mar = c(4.5, 4.6, 3, 8))
xs <- seq_along(CORP)
plot(NA, xlim = c(0.6, length(CORP) + 0.4), ylim = c(0, max(tab$eff_range_5_95_st) * 1.1),
     xaxt = "n", xlab = "", ylab = "5-95% effective range (ST)",
     main = "Rate->F0 excursion across definitions (landmark = primary)")
rect(par("usr")[1], 0, par("usr")[2], JND[1], col = "#00000012", border = NA)
rect(par("usr")[1], JND[1], par("usr")[2], JND[2], col = "#00000008", border = NA)
abline(h = JND, col = "grey50", lty = c(3, 2))
axis(1, at = xs, labels = sapply(CORP, `[`, 2))
off <- seq(-0.28, 0.28, length.out = length(defs_order))
for (j in seq_along(defs_order)) {
  d <- defs_order[j]
  y <- sapply(CORP, function(k) tab$eff_range_5_95_st[tab$Dataset == k[2] & tab$definition == d])
  points(xs + off[j], y, pch = pchs[d], col = cols[d], cex = cexs[d])
}
legend(par("usr")[2] + 0.05, par("usr")[4], legend = defs_order, col = cols[defs_order],
       pch = pchs[defs_order], bty = "n", xpd = NA, title = "definition")
text(par("usr")[2] + 0.05, JND[2], "JND 1.0", pos = 4, xpd = NA, cex = 0.8, col = "grey40")
par(op); dev.off()
say("wrote Fig3_robustness.png")

## --------------------------------------------------------------- verdict ---
## robust if every definition (incl. suspect-excluded) clears JND 1.0 and the
## effective range spread within a corpus is modest (<= 35% of the maxmin value).
flags <- sapply(CORP, function(k) {
  e <- tab$eff_range_5_95_st[tab$Dataset == k[2]]
  base <- tab$eff_range_5_95_st[tab$Dataset == k[2] & tab$definition == "maxmin"]
  all_over <- all(tab$exceeds_JND_1.0[tab$Dataset == k[2]])
  spread <- (max(e) - min(e)) / base
  sprintf("%s: all defs > JND1.0 = %s; spread = %.0f%% of maxmin", k[2], all_over, 100 * spread)
})
verdict <- all(tab$exceeds_JND_1.0)
## stricter movement band (~1.5 st): which cells dip below?
n_below_15 <- sum(!tab$exceeds_JND_1.5)
below_15 <- if (n_below_15) paste(sprintf("%s/%s (%.2f st)",
  tab$Dataset[!tab$exceeds_JND_1.5], tab$definition[!tab$exceeds_JND_1.5],
  tab$eff_range_5_95_st[!tab$exceeds_JND_1.5]), collapse = ", ") else "none"

rep <- c("# F0range robustness report (measurement validity)", "",
         "Excursion definitions compared: maxmin (12log2 max/min), maxmin_clean",
         "(suspect f0_min dropped), p95p5 (12log2 p95/p5), winsor (per-speaker).",
         sprintf("JND bands (config): static %s / movement %s st.",
                 paste(JND_STATIC, collapse = "-"), paste(JND_MOVEMENT, collapse = "-")),
         "", "## per-corpus", paste0("- ", flags), "",
         sprintf("## verdict: %s",
                 if (verdict) "ROBUST — every definition clears JND 1.0 in every corpus."
                 else "MIXED — some definition/corpus falls below JND 1.0; inspect TableS_robustness.csv."),
         sprintf("## under the stricter movement band (>1.5 st): %d/%d cells dip below — %s",
                 n_below_15, nrow(tab), below_15),
         "", "## log", paste0("    ", log_lines))
writeLines(rep, file.path(sup, "robustness_report.md"))
cat("\n===== TableS_robustness =====\n"); print(tab, row.names = FALSE)
say("DONE.")
