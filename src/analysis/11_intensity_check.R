## 11_intensity_check.R — is the rate->F0excursion effect just intensity scaling?
##
## Rival explanation: fast speech may simply raise overall vocal effort/loudness,
## and the excursion compression could be a by-product of intensity/loudness
## scaling rather than a pitch-target-specific (undershoot) phenomenon. We test
## this by adding intensity (dB) as a covariate and asking how much of the
## Duration effect it absorbs.
##
## (Named 11_ to avoid colliding with 04_robustness.R; the user called it
##  "04_intensity_check.R".)
##
## For each corpus x subset(all / accent_nucleus_strict) x DV(F0_range_ST raw,
## F0_excursion_LM_ST landmark) we compare the 5-95% Duration effective range
## WITHOUT vs WITH s(Intensity_Max) [primary] and s(Intensity_Mean) [robustness],
## and report the % reduction, the Duration-intensity correlation, and concurvity.
##
## Verdict: small reduction (<~20%) => not explained by intensity (pitch-specific);
##          large reduction (>~50%) => intensity is a major confound.
##
## Outputs: results/supplement/TableS_intensity_check.csv
##          results/figures/Fig_intensity_control.png
##          results/supplement/intensity_check_report.md
## Run: Rscript src/analysis/11_intensity_check.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))
NT <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NT) != 1L || is.na(NT) || NT < 1L) NT <- 1L
K_DUR <- 20; K_FS <- 5; K_INT <- 10
sup <- repo_path(CONFIG$paths$supplement); fig <- repo_path(CONFIG$paths$figures)
dir.create(sup, showWarnings = FALSE, recursive = TRUE); dir.create(fig, showWarnings = FALSE, recursive = TRUE)
log <- character(0); say <- function(...) { m <- sprintf(...); message(m); log[[length(log)+1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)

## 5-95% effective range of s(Duration), optionally holding an intensity covariate
## at its median. Returns eff + the smooth curve over the 5-95% window.
eff_dur <- function(m, dur) {
  grid <- seq(min(dur), max(dur), length.out = 200)
  mf <- m$model; resp <- names(mf)[1]
  nd <- data.frame(Duration = grid)
  for (v in setdiff(names(mf), c(resp, "Duration"))) {
    col <- mf[[v]]
    nd[[v]] <- if (is.factor(col)) factor(levels(col)[1], levels = levels(col))
               else stats::median(col, na.rm = TRUE)
  }
  pr <- predict(m, nd, type = "terms"); cc <- which(colnames(pr) == "s(Duration)")
  q <- quantile(dur, c(0.05, 0.95)); in95 <- grid >= q[1] & grid <= q[2]
  list(eff = max(pr[in95, cc]) - min(pr[in95, cc]),
       grid = grid[in95], fit = pr[in95, cc])
}

concurv <- function(m, term = "s(Intensity") {
  tryCatch({
    cm <- concurvity(m, full = FALSE)$estimate
    ri <- grep("s\\(Duration\\)$", rownames(cm)); ci <- grep(term, colnames(cm))
    if (length(ri) && length(ci)) round(cm[ri[1], ci[1]], 3) else NA_real_
  }, error = function(e) NA_real_)
}

fit_no  <- function(d, dv) bam(as.formula(sprintf(
  "%s ~ s(Duration, k=%d) + s(Duration, Speaker, bs='fs', m=1, k=%d) + s(Vowel, bs='re')",
  dv, K_DUR, K_FS)), data = d, method = "fREML", discrete = TRUE, nthreads = NT)
fit_int <- function(d, dv, icol) bam(as.formula(sprintf(
  "%s ~ s(Duration, k=%d) + s(%s, k=%d) + s(Duration, Speaker, bs='fs', m=1, k=%d) + s(Vowel, bs='re')",
  dv, K_DUR, icol, K_INT, K_FS)), data = d, method = "fREML", discrete = TRUE, nthreads = NT)

DVS <- c("F0_range_ST", "F0_excursion_LM_ST")
INT <- c("Intensity_Max", "Intensity_Mean")
CORP <- c("CSJ Monologue", "Buckeye", "CSJ Dialogue")

rows <- list(); curves <- list()
for (cp in CORP) {
  base_all <- subset(dat, Dataset == cp)
  subsets <- list(all = base_all)
  if (any(base_all$HasTone == "True"))
    subsets[["accent_nucleus_strict"]] <- subset(base_all, HasTone == "True" & AccentNucleus == "True")
  for (sub_nm in names(subsets)) {
    for (dv in DVS) {
      d <- subsets[[sub_nm]]
      d <- d[!is.na(d[[dv]]) & !is.na(d$Duration) & !is.na(d$Intensity_Max) & !is.na(d$Intensity_Mean), ]
      d <- droplevels(d); d$Speaker <- factor(d$Speaker); d$Vowel <- factor(d$Vowel)
      m0 <- fit_no(d, dv); e0 <- eff_dur(m0, d$Duration)
      if (sub_nm == "all") curves[[paste(cp, dv, "no")]] <- e0
      for (ic in INT) {
        mi <- fit_int(d, dv, ic); ei <- eff_dur(mi, d$Duration)
        if (sub_nm == "all" && ic == "Intensity_Max") curves[[paste(cp, dv, "int")]] <- ei
        pct <- 100 * (e0$eff - ei$eff) / e0$eff
        rr <- cor(d$Duration, d[[ic]])
        say("%-14s %-21s %-18s / %-14s: eff %.2f -> %.2f (%.0f%% red), cor(dur,int)=%.2f",
            cp, sub_nm, dv, ic, e0$eff, ei$eff, pct, rr)
        rows[[length(rows)+1L]] <- data.frame(
          Dataset = cp, Subset = sub_nm, DV = dv, intensity_measure = ic, N = nrow(d),
          eff_5_95_no_intensity_ST = round(e0$eff, 3),
          eff_5_95_with_intensity_ST = round(ei$eff, 3),
          pct_reduction = round(pct, 1),
          duration_intensity_correlation = round(rr, 3),
          concurvity_dur_intensity = concurv(mi))
      }
    }
  }
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(sup, "TableS_intensity_check.csv"), row.names = FALSE)

## descriptive intensity stats per corpus
desc <- do.call(rbind, lapply(CORP, function(cp) {
  d <- subset(dat, Dataset == cp)
  data.frame(Dataset = cp,
             Intensity_Max_mean = round(mean(d$Intensity_Max, na.rm = TRUE), 1),
             Intensity_Max_sd = round(sd(d$Intensity_Max, na.rm = TRUE), 1),
             Intensity_Mean_mean = round(mean(d$Intensity_Mean, na.rm = TRUE), 1),
             Intensity_Mean_sd = round(sd(d$Intensity_Mean, na.rm = TRUE), 1))
}))

## figure: 3 corpora x 2 DV, s(Duration) before (solid) vs after intensity control (dashed)
png(file.path(fig, "Fig_intensity_control.png"), width = 1250, height = 1500, res = 150)
op <- par(mfrow = c(3, 2), mar = c(4.2, 4.4, 3, 1))
for (cp in CORP) for (dv in DVS) {
  e0 <- curves[[paste(cp, dv, "no")]]; ei <- curves[[paste(cp, dv, "int")]]
  if (is.null(e0) || is.null(ei)) { plot.new(); next }
  ylim <- range(c(e0$fit, ei$fit)); ylim <- ylim + c(-0.15, 0.15) * diff(ylim)
  dvlab <- ifelse(dv == "F0_range_ST", "F0range raw", "F0excursion LM")
  plot(NA, xlim = range(e0$grid), ylim = ylim, xlab = "Duration (s), 5-95%",
       ylab = "partial effect (ST)", main = sprintf("%s — %s", cp, dvlab))
  rect(par("usr")[1], -JND_STATIC[1], par("usr")[2], JND_STATIC[1], col = "#00000010", border = NA)
  rect(par("usr")[1], -JND_STATIC[2], par("usr")[2], JND_STATIC[2], col = "#00000008", border = NA)
  abline(h = 0, col = "grey50", lty = 2)
  lines(e0$grid, e0$fit, lwd = 2.6, col = "#1F3B63")
  lines(ei$grid, ei$fit, lwd = 2.6, col = "#C1440E", lty = 2)
  legend("topleft", c(sprintf("no control (%.2f st)", diff(range(e0$fit))),
                      sprintf("+ Intensity_Max (%.2f st)", diff(range(ei$fit)))),
         col = c("#1F3B63", "#C1440E"), lwd = 2.6, lty = c(1, 2), bty = "n", cex = 0.85)
}
par(op); dev.off()
say("wrote Fig_intensity_control.png")

## report: one line per corpus (primary = landmark DV + Intensity_Max, all vowels)
verdict1 <- function(pct) if (pct < 20) "F0/pitch-target specific (NOT intensity)" else
  if (pct < 50) "partly intensity-linked (interpret with care)" else "intensity may be a MAJOR confound"
rep <- c("# Intensity-confound check (is rate->excursion just loudness scaling?)", "",
  "DV = F0_excursion_LM_ST (primary) & F0_range_ST (raw). Covariate = s(Intensity_Max/Mean).", "",
  "## descriptive intensity (dB) per corpus")
for (i in seq_len(nrow(desc))) rep <- c(rep, sprintf(
  "- %-14s Intensity_Max %.1f±%.1f dB; Intensity_Mean %.1f±%.1f dB",
  desc$Dataset[i], desc$Intensity_Max_mean[i], desc$Intensity_Max_sd[i],
  desc$Intensity_Mean_mean[i], desc$Intensity_Mean_sd[i]))
rep <- c(rep, "", "## primary verdict — landmark DV, all vowels, Intensity_Max control")
for (cp in CORP) {
  r <- tab[tab$Dataset == cp & tab$Subset == "all" & tab$DV == "F0_excursion_LM_ST" &
             tab$intensity_measure == "Intensity_Max", ]
  if (!nrow(r)) next
  rep <- c(rep, sprintf(
    "- %s: intensity control -> Duration eff %.2f -> %.2f ST (%.0f%% reduction; cor(dur,int)=%.2f, concurvity=%.2f). [%s]",
    cp, r$eff_5_95_no_intensity_ST, r$eff_5_95_with_intensity_ST, r$pct_reduction,
    r$duration_intensity_correlation, r$concurvity_dur_intensity, verdict1(r$pct_reduction)))
}
rep <- c(rep, "",
  "## accent-nucleus strict (landmark DV, Intensity_Max)")
for (cp in c("CSJ Monologue", "CSJ Dialogue")) {
  r <- tab[tab$Dataset == cp & tab$Subset == "accent_nucleus_strict" &
             tab$DV == "F0_excursion_LM_ST" & tab$intensity_measure == "Intensity_Max", ]
  if (nrow(r)) rep <- c(rep, sprintf("- %s: %.2f -> %.2f ST (%.0f%% red). [%s]",
    cp, r$eff_5_95_no_intensity_ST, r$eff_5_95_with_intensity_ST, r$pct_reduction, verdict1(r$pct_reduction)))
}
rep <- c(rep, "",
  "NB: Duration and intensity are correlated, so a with-intensity model splits shared",
  "variance; concurvity is reported. A SMALL reduction is strong evidence the effect is",
  "not mere loudness scaling; interpret a large reduction together with concurvity.",
  "", "## full table: TableS_intensity_check.csv (all DV x subset x intensity measure)",
  "", "## log", paste0("    ", log))
writeLines(rep, file.path(sup, "intensity_check_report.md"))
cat("\n===== TableS_intensity_check (landmark, all, Intensity_Max) =====\n")
print(tab[tab$Subset == "all" & tab$DV == "F0_excursion_LM_ST" & tab$intensity_measure == "Intensity_Max",
          c("Dataset", "eff_5_95_no_intensity_ST", "eff_5_95_with_intensity_ST", "pct_reduction",
            "duration_intensity_correlation")], row.names = FALSE)
say("DONE.")
