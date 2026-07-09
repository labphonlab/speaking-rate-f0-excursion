## 02_effect_size.R — the effect-size-vs-significance question +
## F0_max vs F0_range divergence (Editor: "max is not excursion").
##
## For each of {CSJ Monologue, Buckeye, CSJ Dialogue} x each DV {max, range}
## (6 models) fit the same bam() and read the POPULATION-level s(Duration)
## smooth as an effect size in SEMITONES, compared against the F0 JND (~0.5-1 st).
##
## Inputs : master_csv (see REQUIRED COLUMNS below)
## Outputs: results/supplement/TableS_effect_size.csv
##          results/figures/effect_size_partial.png
##          results/supplement/effect_size_report.md
##          results/supplement/fit_<key>_<dv>.rds   (x6, to rebuild figs)
##
## Run: Rscript src/analysis/02_effect_size.R

suppressWarnings(suppressMessages({
  library(mgcv)
  library(dplyr)
}))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))

NTHREADS <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NTHREADS) != 1L || is.na(NTHREADS) || NTHREADS < 1L) NTHREADS <- 1L

JND <- JND_STATIC               # static-F0 JND band (config.jnd.static); figure bands
GRID_N <- 200

## REQUIRED COLUMNS in master_csv (contract with build_dataset.py):
##   Dataset  : corpus label (matched case-insensitively, see TARGETS$match)
##   Speaker  : speaker ID
##   Vowel    : vowel label
##   Duration : vowel duration, seconds
##   f0_max, f0_min : Hz (used for range and, if absent, F0_ST)
##   F0_ST        : optional precomputed semitones of f0_max
##   F0_range_ST  : optional precomputed semitone range
TARGETS <- list(
  list(name = "CSJ Monologue", key = "csj_mono",
       match = c("csj monologue", "csj_mono", "csj-mono", "csj mono", "mono")),
  list(name = "Buckeye",       key = "buckeye",
       match = c("buckeye")),
  list(name = "CSJ Dialogue",  key = "csj_dial",
       match = c("csj dialogue", "csj_dial", "csj-dial", "csj dial", "dialogue"))
)
## DVs: F0max (level), raw F0range (max-min; frame-count INFLATED, kept for the
## contrast), and the PRIMARY frame-count-robust landmark excursion (09_artifact_check).
DVS <- list(
  list(id = "max",      col = "F0_ST",             label = "F0max (ST)"),
  list(id = "range",    col = "F0_range_ST",       label = "F0range raw (ST)"),
  list(id = "landmark", col = "F0_excursion_LM_ST", label = "F0excursion LM (ST)")
)

sup_dir <- repo_path(CONFIG$paths$supplement)
fig_dir <- repo_path(CONFIG$paths$figures)
dir.create(sup_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

log_lines <- c(sprintf("effect-size run | nthreads=%d | JND static=%s / movement=%s st | thresholds=%s",
                       NTHREADS, paste(JND_STATIC, collapse = "-"),
                       paste(JND_MOVEMENT, collapse = "-"),
                       paste(JND_THRESHOLDS, collapse = ",")))
say <- function(...) { m <- sprintf(...); message(m); log_lines[[length(log_lines) + 1L]] <<- m }

## ---------------------------------------------------------------- load ----
master_path <- repo_path(CONFIG$paths$master_csv)
if (!file.exists(master_path)) stop("master_csv not found: ", master_path,
                                    "\nRun src/build_dataset.py first.")
dat <- read.csv(master_path, stringsAsFactors = FALSE)
say("loaded master_csv: %d rows, cols = %s", nrow(dat),
    paste(names(dat), collapse = ","))

## Ensure the two DV columns exist; derive in ST if missing (ref-invariant).
if (!"F0_ST" %in% names(dat)) {
  if (!"f0_max" %in% names(dat)) stop("need F0_ST or f0_max in master_csv")
  dat$F0_ST <- hz_to_st(dat$f0_max)
  say("derived F0_ST = 12*log2(f0_max) (reference-invariant for range/slope)")
}
if (!"F0_range_ST" %in% names(dat)) {
  if (!all(c("f0_max", "f0_min") %in% names(dat)))
    stop("need F0_range_ST or (f0_max & f0_min) in master_csv")
  n_before <- nrow(dat)
  bad <- with(dat, is.na(f0_min) | is.na(f0_max) | f0_min <= 0 | f0_max <= f0_min)
  dat$F0_range_ST <- NA_real_
  dat$F0_range_ST[!bad] <- hz_to_st(dat$f0_max[!bad] / dat$f0_min[!bad])
  say("derived F0_range_ST = 12*log2(f0_max/f0_min); dropped %d tokens with f0_min<=0 or f0_max<=f0_min",
      sum(bad))
}

## ---------------------------------------------------- model + effects ----
fit_one <- function(df) {
  df <- df %>%
    filter(!is.na(Duration), !is.na(Vowel), !is.na(Speaker)) %>%
    mutate(Speaker = factor(Speaker), Vowel = factor(Vowel))
  bam(DV ~ s(Duration, k = 20) +
        s(Duration, Speaker, bs = "fs", m = 1, k = 5) +
        s(Vowel, bs = "re"),
      data = df, method = "fREML", discrete = TRUE, nthreads = NTHREADS)
}

## Extract the population smooth s(Duration) on a grid, with pointwise 95% CI.
effect_of <- function(model, dur) {
  grid <- seq(min(dur), max(dur), length.out = GRID_N)
  nd <- data.frame(
    Duration = grid,
    Speaker  = factor(levels(model$model$Speaker)[1], levels = levels(model$model$Speaker)),
    Vowel    = factor(levels(model$model$Vowel)[1],   levels = levels(model$model$Vowel))
  )
  pr <- predict(model, newdata = nd, type = "terms", se.fit = TRUE)
  cn <- colnames(pr$fit)
  col <- which(cn == "s(Duration)")
  if (!length(col)) col <- grep("^s\\(Duration\\)$", cn)          # exact pop term
  if (!length(col)) stop("could not locate population s(Duration) term; cols: ",
                         paste(cn, collapse = ", "))
  fit <- pr$fit[, col]; se <- pr$se.fit[, col]
  q <- as.numeric(quantile(dur, c(0.05, 0.95)))
  in95 <- grid >= q[1] & grid <= q[2]
  # partial effect evaluated EXACTLY at the 5th (fast/short) and 95th (slow/long)
  # duration percentiles, by linear interpolation on the grid. q[1]=p5, q[2]=p95.
  fit_at_p5  <- approx(grid, fit, xout = q[1])$y   # short duration = FAST speech
  fit_at_p95 <- approx(grid, fit, xout = q[2])$y   # long  duration = SLOW speech
  list(grid = grid, fit = fit, se = se,
       lower = fit - 1.96 * se, upper = fit + 1.96 * se,
       q = q, in95 = in95,
       eff_full = max(fit) - min(fit),
       eff_595  = max(fit[in95]) - min(fit[in95]),
       slope_100ms = unname(coef(lm(fit ~ grid))[2]) * 0.1,
       fit_at_p5 = unname(fit_at_p5), fit_at_p95 = unname(fit_at_p95),
       # signed p5(fast) - p95(slow). NEGATIVE => partial effect LOWER at short
       # duration => F0(range) SMALLER when fast => shrinks_when_fast.
       sign_p5_minus_p95 = unname(fit_at_p5 - fit_at_p95))
}

results <- list()
table_rows <- list()
for (tg in TARGETS) {
  sub_all <- dat[tolower(trimws(dat$Dataset)) %in% tg$match, , drop = FALSE]
  if (!nrow(sub_all)) { say("WARNING: no rows for %s (Dataset match failed)", tg$name); next }
  for (dv in DVS) {
    d <- sub_all
    d$DV <- d[[dv$col]]
    d <- d[!is.na(d$DV), , drop = FALSE]
    n_used <- nrow(d); n_spk <- length(unique(d$Speaker))
    say(audit_line(sprintf("%s / %s", tg$name, dv$id), nrow(sub_all), n_used, n_spk))
    m <- fit_one(d)
    saveRDS(m, file.path(sup_dir, sprintf("fit_%s_%s.rds", tg$key, dv$id)))
    eff <- effect_of(m, m$model$Duration)
    results[[tg$name]][[dv$id]] <- list(eff = eff, n_used = n_used, n_spk = n_spk,
                                        dv = dv, tg = tg)
    # explicit DIRECTION from the sign of p5(fast) - p95(slow):
    #   sign < 0 => partial effect lower at short duration => shrinks when fast
    #   sign > 0 => partial effect higher at short duration => grows when fast
    s_pp <- eff$sign_p5_minus_p95
    direction_label <- if (s_pp < -0.05) "shrinks_when_fast"
                       else if (s_pp > 0.05) "grows_when_fast" else "flat"
    row <- data.frame(
      Dataset = tg$name, DV = dv$id, N = n_used, n_speakers = n_spk,
      eff_range_full_st = round(eff$eff_full, 3),
      eff_range_5_95_st = round(eff$eff_595, 3),
      slope_per_100ms_st = round(eff$slope_100ms, 4),
      # partial effect at p5 (fast/short) and p95 (slow/long) duration, signed diff
      fit_at_p5_st = round(eff$fit_at_p5, 3),
      fit_at_p95_st = round(eff$fit_at_p95, 3),
      sign_p5_minus_p95_st = round(s_pp, 3),
      direction_label = direction_label,
      check.names = FALSE, stringsAsFactors = FALSE)
    # one exceeds_JND_<t> column per configured threshold (0.5 / 1.0 / 1.5)
    row <- add_jnd_flags(row)
    table_rows[[length(table_rows) + 1L]] <- row
  }
}

TableS <- do.call(rbind, table_rows)
write.csv(TableS, file.path(sup_dir, "TableS_effect_size.csv"), row.names = FALSE)
say("wrote TableS_effect_size.csv (%d rows)", nrow(TableS))

## ------------------------------------------------------------- figure ----
## 3 rows (corpora) x 2 cols (max,range). y shared WITHIN a DV column.
ylim_for <- function(dv_id) {
  lo <- hi <- NULL
  for (tg in TARGETS) {
    e <- results[[tg$name]][[dv_id]]$eff
    if (is.null(e)) next
    lo <- min(lo, e$lower); hi <- max(hi, e$upper)
  }
  pad <- 0.08 * (hi - lo)
  c(min(lo, -JND[2]) - pad, max(hi, JND[2]) + pad)
}
yl <- setNames(lapply(vapply(DVS, function(d) d$id, ""), ylim_for),
               vapply(DVS, function(d) d$id, ""))

png(file.path(fig_dir, "effect_size_partial.png"), width = 750 * length(DVS), height = 1650, res = 170)
op <- par(mfrow = c(length(TARGETS), length(DVS)), mar = c(4.2, 4.4, 3, 1), oma = c(0, 0, 2.2, 0))
axis_note <- c()
for (tg in TARGETS) {
  for (dv in DVS) {
    r <- results[[tg$name]][[dv$id]]
    if (is.null(r)) { plot.new(); title(sprintf("%s / %s (no data)", tg$name, dv$id)); next }
    e <- r$eff; ylim <- yl[[dv$id]]
    plot(NA, xlim = range(e$grid), ylim = ylim,
         xlab = "Duration (s)", ylab = sprintf("partial effect, %s", dv$label),
         main = sprintf("%s — %s\n(N=%d, spk=%d, 5-95%% eff=%.2f st)",
                        tg$name, dv$label, r$n_used, r$n_spk, e$eff_595))
    # JND guide bands (+/-0.5, +/-1.0 st)
    rect(par("usr")[1], -JND[1], par("usr")[2], JND[1], col = "#00000010", border = NA)
    rect(par("usr")[1], -JND[2], par("usr")[2], JND[2], col = "#00000008", border = NA)
    abline(h = 0, col = "grey40", lty = 2)
    # pointwise 95% CI band
    polygon(c(e$grid, rev(e$grid)), c(e$lower, rev(e$upper)),
            col = "#4C78A833", border = NA)
    # highlight regions where CI excludes 0 (significantly != mean)
    sig <- (e$lower > 0) | (e$upper < 0)
    if (any(sig)) {
      rr <- rle(sig); ends <- cumsum(rr$lengths); starts <- ends - rr$lengths + 1
      for (i in which(rr$values)) {
        xs <- e$grid[starts[i]:ends[i]]
        polygon(c(xs, rev(xs)),
                c(e$lower[starts[i]:ends[i]], rev(e$upper[starts[i]:ends[i]])),
                col = "#E4572E44", border = NA)
      }
    }
    lines(e$grid, e$fit, lwd = 2.4, col = "#1F3B63")
    # 5-95 window guides
    abline(v = e$q, col = "grey55", lty = 3)
    # explicit direction annotation: sign of the partial effect fast vs slow
    dvtag <- if (dv$id == "range") "F0range" else "F0max"
    dir_txt <- if (e$slope_100ms > 0) sprintf("fast → %s ↓ (slope +%.2f st/100ms)", dvtag, e$slope_100ms)
               else if (e$slope_100ms < 0) sprintf("fast → %s ↑ (slope %.2f st/100ms)", dvtag, e$slope_100ms)
               else "flat"
    mtext(dir_txt, side = 1, line = -1.2, adj = 0.03, cex = 0.62, col = "#7A2E1E")
    if (min(e$fit) < 0)
      axis_note <- c(axis_note, sprintf("%s/%s: partial effect dips below 0 (centered smooth; 0 = corpus mean level)", tg$name, dv$id))
  }
}
title(main = "Population s(Duration) partial effects — F0max / F0range(raw) / F0excursion(LM), semitones (grey = JND +/-0.5,1.0; orange = CI excludes 0)",
      outer = TRUE, cex.main = 0.9)
par(op); dev.off()
say("wrote effect_size_partial.png")
for (a in unique(axis_note)) say("axis: %s", a)

## ------------------------------------------------------------- report ----
rep <- c("# Effect-size report (effect size vs significance)", "",
         sprintf("F0 JND bands (config.jnd): static %s st / movement %s st.",
                 paste(JND_STATIC, collapse = "-"), paste(JND_MOVEMENT, collapse = "-")),
         "Static = level-discrimination JND; movement = pitch-movement relevance",
         "threshold ('t Hart 1981, ~1.5 st) — the stricter yardstick for an excursion DV.",
         "Judge on the robust 5-95% effective range.", "")
thr_lab <- paste(sprintf("JND%.1f", JND_THRESHOLDS), collapse = "/")
for (tg in TARGETS) for (dv in DVS) {
  r <- results[[tg$name]][[dv$id]]; if (is.null(r)) next
  e <- r$eff
  flags <- paste(sprintf("%.1f=%s", JND_THRESHOLDS,
                         ifelse(e$eff_595 > JND_THRESHOLDS, "超", "未")), collapse = " ")
  dir_lab <- if (e$slope_100ms > 0) "速い側でレンジ縮小" else if (e$slope_100ms < 0) "速い側でレンジ拡大" else "平坦"
  rep <- c(rep, sprintf(
    "- %s %s: 実効幅(5-95)=%.2f st, 傾き=%.3f st/100ms [%s], JND(%s) %s",
    tg$name, dv$id, e$eff_595, e$slope_100ms, dir_lab, thr_lab, flags))
}

## interpretation flags
maxeffs <- sapply(TARGETS, function(tg) {
  r <- results[[tg$name]][["max"]]; if (is.null(r)) NA else r$eff$eff_595 })
flag_max_flat <- all(maxeffs[!is.na(maxeffs)] < JND[1])

range_desc <- sapply(TARGETS, function(tg) {
  r <- results[[tg$name]][["range"]]; if (is.null(r)) return(NA_character_)
  s <- r$eff$sign_p5_minus_p95   # fit(p5/fast) - fit(p95/slow); <0 => smaller at fast
  dir <- if (s < 0) "fast側でレンジ縮小(shrinks_when_fast)" else "fast側でレンジ拡大(grows_when_fast)"
  sprintf("%s: sign(p5-p95)=%.2f st -> %s", tg$name, s, dir)
})
flag_range_shrinks <- paste(range_desc[!is.na(range_desc)], collapse = " | ")

diverge <- sapply(TARGETS, function(tg) {
  rm <- results[[tg$name]][["max"]]; rr <- results[[tg$name]][["range"]]
  if (is.null(rm) || is.null(rr)) return(NA_character_)
  sm <- rm$eff$slope_100ms; sr <- rr$eff$slope_100ms
  diff_sign <- sign(sm) != sign(sr)
  sprintf("%s: slope max=%.3f vs range=%.3f st/100ms%s",
          tg$name, sm, sr, ifelse(diff_sign, " [符号が逆]", ""))
})
flag_max_range_diverge <- paste(diverge[!is.na(diverge)], collapse = " | ")

rep <- c(rep, "", "## 解釈フラグ（案A/案B分岐用）",
         sprintf("- flag_max_flat: %s (全コーパスで F0max の 5-95 実効幅 < %.1f st か)",
                 flag_max_flat, JND[1]),
         sprintf("- flag_range_shrinks: %s", flag_range_shrinks),
         sprintf("- flag_max_range_diverge: %s", flag_max_range_diverge),
         "", "## N-audit / log", paste0("    ", log_lines))
writeLines(rep, file.path(sup_dir, "effect_size_report.md"))
say("wrote effect_size_report.md")

## ----------------------------------- axis-orientation verification (F0range) ---
## The x-axis is Duration in SECONDS, plotted ascending: SHORT (fast speech) is on
## the LEFT, LONG (slow speech) on the RIGHT. Read "fast" = left edge. We prove the
## direction numerically from the smooth itself (not the plot) so an axis flip
## cannot mislead: compare the partial effect at p5 (short/fast) vs p95 (long/slow).
cat("\n===== AXIS-ORIENTATION CHECK (F0range panels) =====\n")
cat("x-axis = Duration (s), ascending: LEFT = short = FAST speech; RIGHT = long = SLOW.\n")
cat("Numeric proof (independent of the plot): partial effect at p5(fast) vs p95(slow).\n")
for (tg in TARGETS) {
  r <- results[[tg$name]][["range"]]; if (is.null(r)) next
  e <- r$eff
  concl <- if (e$sign_p5_minus_p95 < 0) "F0range SMALLER at fast -> shrinks_when_fast (matches Fougeron & Jun 1998)"
           else "F0range LARGER at fast -> grows_when_fast"
  cat(sprintf("  %-14s p5(short/fast, d=%.3fs)=%.3f st  vs  p95(long/slow, d=%.3fs)=%.3f st  | p5-p95=%.3f st => %s\n",
              tg$name, e$q[1], e$fit_at_p5, e$q[2], e$fit_at_p95, e$sign_p5_minus_p95, concl))
}

## echo the table
cat("\n===== TableS_effect_size =====\n")
print(TableS, row.names = FALSE)
cat("\nflags: max_flat =", flag_max_flat, "\n")
