## 08_mundlak.R — within/between (Mundlak / REWB) decomposition of the rate effect,
## on the frame-count-robust landmark DVs.
##
## The population smooths in 02/04-07 mix two things: WITHIN-speaker rate changes
## (a speaker slows/speeds relative to their own average) and BETWEEN-speaker
## differences (slow speakers differ from fast speakers). Only the WITHIN part is
## the mechanistic "when THIS talker speeds up, excursion shrinks" claim. We
## decompose Duration into its speaker mean (Duration_Between) and within-speaker
## deviation (Duration_Within, built in build_dataset) and fit, per corpus and DV:
##
##   DV ~ Duration_Between + s(Duration_Within) + s(Duration_Within,Speaker,fs) + s(Vowel,re)
##
## The linear Duration_Between term is identifiable alongside the fs random
## intercepts (standard REWB device). DVs: landmark excursion (F0_excursion_LM_ST)
## and the landmark max / min (F0_LMmax_ST / F0_LMmin_ST) to test the mechanism
## (Caspers & van Heuven 1993; Ladd et al. 1999): does fast speech raise the
## register with F0min rising MORE than F0max, compressing the excursion?
##
## Outputs: results/supplement/TableS_mundlak.csv
##          results/figures/Fig7_mundlak.png  (within max vs min, CSJ Monologue+Buckeye)
##          results/supplement/mundlak_report.md
## Run: Rscript src/analysis/08_mundlak.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))
NT <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NT) != 1L || is.na(NT) || NT < 1L) NT <- 1L
K_DUR <- 20; K_FS <- 5
sup <- repo_path(CONFIG$paths$supplement); fig <- repo_path(CONFIG$paths$figures)
dir.create(sup, showWarnings = FALSE, recursive = TRUE); dir.create(fig, showWarnings = FALSE, recursive = TRUE)
log <- character(0); say <- function(...) { m <- sprintf(...); message(m); log[[length(log)+1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)
CORP <- c("CSJ Monologue", "Buckeye", "CSJ Dialogue")
DVS  <- list(c("landmark_exc", "F0_excursion_LM_ST"),
             c("landmark_max", "F0_LMmax_ST"),
             c("landmark_min", "F0_LMmin_ST"))

fit_mundlak <- function(d, dvcol) {
  d <- d[!is.na(d[[dvcol]]) & !is.na(d$Duration_Within) & !is.na(d$Duration_Between), ]
  d <- droplevels(d); d$DV <- d[[dvcol]]
  d$Speaker <- factor(d$Speaker); d$Vowel <- factor(d$Vowel)
  m <- bam(DV ~ Duration_Between + s(Duration_Within, k = K_DUR) +
             s(Duration_Within, Speaker, bs = "fs", m = 1, k = K_FS) + s(Vowel, bs = "re"),
           data = d, method = "fREML", discrete = TRUE, nthreads = NT)
  s <- summary(m)
  bcoef <- s$p.table["Duration_Between", "Estimate"]
  bp    <- s$p.table["Duration_Between", "Pr(>|t|)"]
  w <- d$Duration_Within; g <- seq(min(w), max(w), length.out = 200)
  nd <- data.frame(Duration_Within = g, Duration_Between = mean(d$Duration_Between),
                   Speaker = factor(levels(d$Speaker)[1], levels = levels(d$Speaker)),
                   Vowel   = factor(levels(d$Vowel)[1],   levels = levels(d$Vowel)))
  pr <- predict(m, nd, type = "terms"); cc <- which(colnames(pr) == "s(Duration_Within)")
  q <- quantile(w, c(0.05, 0.95)); in95 <- g >= q[1] & g <= q[2]
  f5 <- approx(g, pr[, cc], q[1])$y; f95 <- approx(g, pr[, cc], q[2])$y   # p5=fastest(short)
  list(n = nrow(d), spk = nlevels(d$Speaker), grid = g, fit = pr[, cc], in95 = in95,
       within_eff = max(pr[in95, cc]) - min(pr[in95, cc]),
       within_slope = unname(coef(lm(pr[, cc] ~ g))[2]) * 0.1,
       within_sign = f5 - f95,                       # <0 => DV lower at fast
       between_slope100 = bcoef * 0.1, between_p = bp)
}

rows <- list(); curves <- list()
for (cp in CORP) {
  sub <- subset(dat, Dataset == cp)
  for (dv in DVS) {
    r <- fit_mundlak(sub, dv[2]); curves[[paste(cp, dv[1])]] <- r
    dir <- if (r$within_sign < -0.02) "down_when_fast" else if (r$within_sign > 0.02) "up_when_fast" else "flat"
    say("%-14s %-13s within eff=%.2f slope=%.3f sign=%.2f [%s] | between slope=%.3f (p=%.2g) N=%d",
        cp, dv[1], r$within_eff, r$within_slope, r$within_sign, dir, r$between_slope100, r$between_p, r$n)
    rows[[paste(cp, dv[1])]] <- data.frame(Corpus = cp, DV = dv[1], N = r$n, n_speakers = r$spk,
      within_eff_5_95_st = round(r$within_eff, 3), within_slope_per_100ms = round(r$within_slope, 4),
      within_sign_p5_minus_p95 = round(r$within_sign, 3), within_direction = dir,
      within_exceeds_JND_1.0 = (dv[1] == "landmark_exc") & (r$within_eff > JND_STATIC[2]),
      between_slope_per_100ms = round(r$between_slope100, 4), between_p = signif(r$between_p, 3))
  }
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(sup, "TableS_mundlak.csv"), row.names = FALSE)

## figure: WITHIN max vs min centred smooths (mechanism), all 3 corpora
png(file.path(fig, "Fig7_mundlak.png"), width = 1650, height = 600, res = 150)
op <- par(mfrow = c(1, 3), mar = c(4.4, 4.4, 3, 1))
for (cp in CORP) {
  gmax <- curves[[paste(cp, "landmark_max")]]; gmin <- curves[[paste(cp, "landmark_min")]]
  xm <- gmax$grid[gmax$in95]; ymx <- gmax$fit[gmax$in95]; ymn <- gmin$fit[gmin$in95]
  ylim <- range(c(ymx, ymn)); ylim <- ylim + c(-0.15, 0.15) * diff(ylim)
  plot(NA, xlim = range(xm), ylim = ylim, xlab = "Duration_Within (s): left=faster",
       ylab = "within partial effect (ST)",
       main = sprintf("%s — within-speaker: F0 max vs min", cp))
  abline(h = 0, col = "grey50", lty = 2); abline(v = 0, col = "grey80", lty = 3)
  lines(xm, ymx, lwd = 2.8, col = "#C1440E"); lines(xm, ymn, lwd = 2.8, col = "#1F3B63")
  legend("topright", c(sprintf("F0max (sign %.2f)", gmax$within_sign),
                       sprintf("F0min (sign %.2f)", gmin$within_sign)),
         col = c("#C1440E", "#1F3B63"), lwd = 2.8, bty = "n", cex = 0.9)
}
par(op); dev.off()
say("wrote Fig7_mundlak.png")

## verdict
exc <- tab[tab$DV == "landmark_exc", ]
within_ok <- all(exc$within_direction == "down_when_fast")
jnd_ok <- exc$within_exceeds_JND_1.0
mech <- sapply(CORP, function(cp) {
  smax <- tab$within_sign_p5_minus_p95[tab$Corpus == cp & tab$DV == "landmark_max"]
  smin <- tab$within_sign_p5_minus_p95[tab$Corpus == cp & tab$DV == "landmark_min"]
  sprintf("%s: within max-sign=%.2f, min-sign=%.2f (%s)", cp, smax, smin,
          if (smin > smax) "min rises MORE than max => register-raising compression" else "max moves >= min")
})
rep <- c("# Within/between (Mundlak) decomposition on landmark DVs", "",
  "DV ~ Duration_Between + s(Duration_Within) + fs(Within,Speaker) + re(Vowel).",
  "WITHIN = same speaker speeding up; BETWEEN = slow vs fast speakers.", "",
  "## landmark excursion")
for (i in which(tab$DV == "landmark_exc")) rep <- c(rep, sprintf(
  "- %-14s within eff=%.2f st (%s JND1.0), dir=%s, within-slope=%.3f | between-slope=%.3f (p=%.2g)",
  tab$Corpus[i], tab$within_eff_5_95_st[i], ifelse(tab$within_exceeds_JND_1.0[i], "clears", "below"),
  tab$within_direction[i], tab$within_slope_per_100ms[i], tab$between_slope_per_100ms[i], tab$between_p[i]))
rep <- c(rep, "", "## mechanism (F0 max vs min, within-speaker; sign>0 => rises when fast)", paste0("- ", mech),
  "", sprintf("## verdict: %s",
    if (within_ok && all(jnd_ok)) "WITHIN-SPEAKER rate effect on excursion is REAL and clears JND in every corpus — not a between-speaker confound."
    else if (within_ok) "WITHIN-speaker effect present (down_when_fast) in every corpus; JND border varies — see table."
    else "MIXED — inspect TableS_mundlak.csv."),
  "", "## log", paste0("    ", log))
writeLines(rep, file.path(sup, "mundlak_report.md"))
cat("\n===== TableS_mundlak =====\n"); print(tab, row.names = FALSE)
say("DONE.")
