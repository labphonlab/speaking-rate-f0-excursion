## 10_landmark_validate.R — does the fixed-landmark excursion (a) survive as a
## real rate effect and (b) reduce the frame-count artifact vs raw max-min?
##
## For each corpus, fit the SAME GAMM on the raw range and on the landmark
## excursion, and report the 5-95% effective range, sign/direction, JND flags,
## the within-fixed-frame-band effect, and cor(num_valid, DV). The Python
## companion (artifact_resample.py --lm) gives the decisive resampling number.
##
## Outputs: results/supplement/TableS_landmark_validate.csv
##          results/supplement/landmark_validate_report.md
## Run: Rscript src/analysis/10_landmark_validate.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))
NT <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NT) != 1L || is.na(NT) || NT < 1L) NT <- 1L
sup <- repo_path(CONFIG$paths$supplement); dir.create(sup, showWarnings = FALSE, recursive = TRUE)
log <- character(0); say <- function(...) { m <- sprintf(...); message(m); log[[length(log)+1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)
CORP <- c("CSJ Monologue", "Buckeye", "CSJ Dialogue")
DVS  <- list(c("raw_range", "F0_range_ST"), c("landmark", "F0_excursion_LM_ST"))

fit_dv <- function(d, dvcol) {
  d <- d[!is.na(d[[dvcol]]) & !is.na(d$Duration), ]; d <- droplevels(d)
  d$DV <- d[[dvcol]]; d$Speaker <- factor(d$Speaker); d$Vowel <- factor(d$Vowel)
  m <- bam(DV ~ s(Duration, k = 20) + s(Duration, Speaker, bs = "fs", m = 1, k = 5) +
             s(Vowel, bs = "re"), data = d, method = "fREML", discrete = TRUE, nthreads = NT)
  dur <- m$model$Duration; g <- seq(min(dur), max(dur), length.out = 200)
  nd <- data.frame(Duration = g,
                   Speaker = factor(levels(m$model$Speaker)[1], levels = levels(m$model$Speaker)),
                   Vowel   = factor(levels(m$model$Vowel)[1],   levels = levels(m$model$Vowel)))
  pr <- predict(m, nd, type = "terms"); cc <- which(colnames(pr) == "s(Duration)")
  q <- quantile(dur, c(0.05, 0.95)); in95 <- g >= q[1] & g <= q[2]
  f5 <- approx(g, pr[, cc], q[1])$y; f95 <- approx(g, pr[, cc], q[2])$y
  list(n = nrow(d), spk = nlevels(d$Speaker),
       eff = max(pr[in95, cc]) - min(pr[in95, cc]),
       slope = unname(coef(lm(pr[, cc] ~ g))[2]) * 0.1,
       sign = f5 - f95, cor_nv = cor(d$num_valid, d$DV))
}

rows <- list()
for (cp in CORP) {
  sub <- droplevels(subset(dat, Dataset == cp))
  for (dv in DVS) {
    r <- fit_dv(sub, dv[2])
    dir <- if (r$sign < -0.05) "shrinks_when_fast" else if (r$sign > 0.05) "grows_when_fast" else "flat"
    say("%-14s %-9s eff=%.2f st slope=%.3f sign=%.2f [%s] cor(nv,DV)=%.2f (N=%d)",
        cp, dv[1], r$eff, r$slope, r$sign, dir, r$cor_nv, r$n)
    rows[[length(rows)+1L]] <- data.frame(Corpus = cp, DV = dv[1], N = r$n, n_speakers = r$spk,
      eff_5_95_st = round(r$eff, 3), slope_per_100ms_st = round(r$slope, 4),
      sign_p5_minus_p95_st = round(r$sign, 3), direction_label = dir,
      cor_numvalid = round(r$cor_nv, 3),
      exceeds_JND_1.0 = r$eff > JND_STATIC[2], exceeds_JND_1.5 = r$eff > JND_MOVEMENT[2])
  }
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(sup, "TableS_landmark_validate.csv"), row.names = FALSE)

## side-by-side raw vs landmark effect shrinkage
rep <- c("# Landmark-excursion validation (frame-count-robust DV)", "",
  "Raw max-min vs fixed-landmark excursion, same GAMM, per corpus.", "")
for (cp in CORP) {
  rr <- tab[tab$Corpus == cp & tab$DV == "raw_range", ]
  rl <- tab[tab$Corpus == cp & tab$DV == "landmark", ]
  drop <- 100 * (rr$eff_5_95_st - rl$eff_5_95_st) / rr$eff_5_95_st
  rep <- c(rep, sprintf("- %-14s eff: raw %.2f -> landmark %.2f st (%.0f%% smaller); landmark %s JND1.0, %s JND1.5; dir=%s",
    cp, rr$eff_5_95_st, rl$eff_5_95_st, drop,
    ifelse(rl$exceeds_JND_1.0, "clears", "below"), ifelse(rl$exceeds_JND_1.5, "clears", "below"),
    rl$direction_label))
}
rep <- c(rep, "", "See artifact_resample.py (--lm) for the decisive resampling artifact_fraction on the landmark DV.",
  "", "## log", paste0("    ", log))
writeLines(rep, file.path(sup, "landmark_validate_report.md"))
cat("\n===== TableS_landmark_validate =====\n"); print(tab, row.names = FALSE)
say("DONE.")
