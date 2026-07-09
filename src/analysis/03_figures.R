## 03_figures.R — paper figures, built from saved .rds fits (no refitting).
##
## Fig 1 (Fig1_max_vs_range.png): the DV argument. Population s(Duration) partial
##   effects in semitones for F0max (top row) vs F0range (bottom row) across the
##   three corpora, with JND guide bands and pointwise 95% CI. Shows F0max hugs
##   the JND band while F0range clears it. Reads fit_<key>_<dv>.rds from 02.
##
## Fig 2 (Fig2_japanese_gradient.png): 案A. (a) rate->F0range response for
##   Japanese Monologue vs Dialogue overlaid (population, random effects excluded)
##   with 95% CI; (b) the Style difference smooth (Dialogue - Monologue) with CI
##   straddling 0 => style-invariant. Reads fit_models_jp_gradient.rds from 01.
##
## Run (after 01 and 02): Rscript src/analysis/03_figures.R

suppressWarnings(suppressMessages({ library(mgcv) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))

sup <- repo_path(CONFIG$paths$supplement)
fig <- repo_path(CONFIG$paths$figures)
dir.create(fig, showWarnings = FALSE, recursive = TRUE)
JND <- JND_STATIC
GRID_N <- 200

col_line <- "#1F3B63"; col_ci <- "#4C78A833"; col_hi <- "#E4572E55"
col_mono <- "#1F3B63"; col_dial <- "#C1440E"

need_rds <- function(f) {
  p <- file.path(sup, f)
  if (!file.exists(p)) { message("MISSING ", f, " (run 01/02 first)"); return(NULL) }
  readRDS(p)
}

## population s(Duration) partial effect (+/-95% CI) from a simple fit
pop_partial <- function(fit) {
  dur <- fit$model$Duration
  grid <- seq(min(dur), max(dur), length.out = GRID_N)
  nd <- data.frame(Duration = grid,
                   Speaker = factor(levels(fit$model$Speaker)[1], levels = levels(fit$model$Speaker)),
                   Vowel   = factor(levels(fit$model$Vowel)[1],   levels = levels(fit$model$Vowel)))
  pr <- predict(fit, newdata = nd, type = "terms", se.fit = TRUE)
  cc <- which(colnames(pr$fit) == "s(Duration)")
  f <- pr$fit[, cc]; se <- pr$se.fit[, cc]
  q <- quantile(dur, c(0.05, 0.95))
  list(grid = grid, fit = f, lower = f - 1.96 * se, upper = f + 1.96 * se, q = q)
}

panel_partial <- function(e, title, ylim, dv_lab) {
  plot(NA, xlim = range(e$grid), ylim = ylim, xlab = "Duration (s)",
       ylab = dv_lab, main = title, cex.main = 1.0, cex.lab = 1.05)
  rect(par("usr")[1], -JND[1], par("usr")[2], JND[1], col = "#00000012", border = NA)
  rect(par("usr")[1], -JND[2], par("usr")[2], JND[2], col = "#00000008", border = NA)
  abline(h = 0, col = "grey40", lty = 2)
  polygon(c(e$grid, rev(e$grid)), c(e$lower, rev(e$upper)), col = col_ci, border = NA)
  sig <- (e$lower > 0) | (e$upper < 0)
  if (any(sig)) {
    rr <- rle(sig); ends <- cumsum(rr$lengths); st <- ends - rr$lengths + 1
    for (i in which(rr$values)) {
      xs <- e$grid[st[i]:ends[i]]
      polygon(c(xs, rev(xs)), c(e$lower[st[i]:ends[i]], rev(e$upper[st[i]:ends[i]])),
              col = col_hi, border = NA)
    }
  }
  lines(e$grid, e$fit, lwd = 2.6, col = col_line)
  abline(v = e$q, col = "grey55", lty = 3)
}

## =============================================================== Fig 1 ======
corpora <- list(c("csj_mono", "CSJ Monologue"), c("buckeye", "Buckeye"),
                c("csj_dial", "CSJ Dialogue"))
DVROWS <- c("max", "range", "landmark")
fits <- list()
for (k in corpora) for (dv in DVROWS)
  fits[[paste0(k[1], "_", dv)]] <- need_rds(sprintf("fit_%s_%s.rds", k[1], dv))

if (all(!sapply(fits, is.null))) {
  eff <- lapply(fits, pop_partial)
  ylim_row <- function(dv) {
    lo <- min(sapply(corpora, function(k) min(eff[[paste0(k[1], "_", dv)]]$lower)))
    hi <- max(sapply(corpora, function(k) max(eff[[paste0(k[1], "_", dv)]]$upper)))
    pad <- 0.08 * (hi - lo); c(min(lo, -JND[2]) - pad, max(hi, JND[2]) + pad)
  }
  yl <- setNames(lapply(DVROWS, ylim_row), DVROWS)
  rowlab <- c(max = "F0max", range = "F0range (raw max-min)", landmark = "F0excursion (landmark)")

  png(file.path(fig, "Fig1_max_vs_range.png"), width = 1650, height = 1650, res = 175)
  op <- par(mfrow = c(3, 3), mar = c(4.2, 4.4, 3, 1), oma = c(0, 3.2, 2.4, 0))
  for (dv in DVROWS) for (k in corpora) {
    e <- eff[[paste0(k[1], "_", dv)]]
    er <- {q <- e$q; g <- e$grid; in95 <- g >= q[1] & g <= q[2]
           max(e$fit[in95]) - min(e$fit[in95])}
    panel_partial(e, sprintf("%s\n(5-95%% eff = %.2f st)", k[2], er), yl[[dv]],
                  "partial effect (ST)")
  }
  for (i in seq_along(DVROWS))
    mtext(rowlab[DVROWS[i]], side = 2, outer = TRUE, line = 0.8,
          at = 1 - (i - 0.5) / length(DVROWS), cex = 0.95, font = 2)
  mtext("Speech-rate (vowel duration) -> F0, semitones. Grey bands = JND +/-0.5, +/-1.0 st; orange = pointwise CI excludes 0.",
        side = 3, outer = TRUE, line = 0.4, cex = 0.9)
  par(op); dev.off()
  message("wrote Fig1_max_vs_range.png (3 rows: max / raw range / landmark)")
}

## =============================================================== Fig 2 ======
mC <- need_rds("fit_models_jp_gradient.rds")
if (!is.null(mC)) {
  dur <- mC$model$Duration
  grid <- seq(min(dur), max(dur), length.out = GRID_N)
  refSpk <- levels(mC$model$Speaker)[1]; refVow <- levels(mC$model$Vowel)[1]
  mk <- function(style) data.frame(
    Duration = grid, Style = factor(style, levels = levels(mC$model$Style)),
    StyleO = ordered(style, levels = levels(mC$model$StyleO)),
    Speaker = factor(refSpk, levels = levels(mC$model$Speaker)),
    Vowel = factor(refVow, levels = levels(mC$model$Vowel)))
  ## population response (exclude random speaker/vowel smooths)
  excl <- c("s(Duration,Speaker)", "s(Vowel)")
  pm <- predict(mC, mk("Monologue"), type = "link", se.fit = TRUE, exclude = excl)
  pd <- predict(mC, mk("Dialogue"),  type = "link", se.fit = TRUE, exclude = excl)
  ## difference smooth (shape change), from the ordered-factor by-term
  prt <- predict(mC, mk("Dialogue"), type = "terms", se.fit = TRUE)
  dcol <- grep("StyleODialogue", colnames(prt$fit))
  dfit <- prt$fit[, dcol]; dse <- prt$se.fit[, dcol]
  q <- quantile(dur, c(0.05, 0.95))

  png(file.path(fig, "Fig2_japanese_gradient.png"), width = 1500, height = 720, res = 165)
  op <- par(mfrow = c(1, 2), mar = c(4.4, 4.6, 3.2, 1))

  # (a) overlaid response curves
  ylo <- min(pm$fit - 1.96 * pm$se.fit, pd$fit - 1.96 * pd$se.fit)
  yhi <- max(pm$fit + 1.96 * pm$se.fit, pd$fit + 1.96 * pd$se.fit)
  plot(NA, xlim = range(grid), ylim = c(ylo, yhi), xlab = "Duration (s)",
       ylab = "predicted F0 excursion, landmark (ST)", main = "(a) Japanese: Monologue vs Dialogue",
       cex.lab = 1.05)
  for (p in list(list(pm, col_mono), list(pd, col_dial))) {
    pr <- p[[1]]; cl <- p[[2]]
    polygon(c(grid, rev(grid)), c(pr$fit - 1.96 * pr$se.fit, rev(pr$fit + 1.96 * pr$se.fit)),
            col = adjustcolor(cl, 0.18), border = NA)
    lines(grid, pr$fit, lwd = 2.6, col = cl)
  }
  abline(v = q, col = "grey55", lty = 3)
  legend("topleft", c("Monologue", "Dialogue"), col = c(col_mono, col_dial),
         lwd = 2.6, bty = "n", cex = 1.05)

  # (b) difference smooth
  dl <- dfit - 1.96 * dse; du <- dfit + 1.96 * dse
  plot(NA, xlim = range(grid), ylim = range(c(dl, du, -JND, JND)), xlab = "Duration (s)",
       ylab = "Dialogue - Monologue (ST)",
       main = "(b) style difference smooth (n.s.)", cex.lab = 1.05)
  rect(par("usr")[1], -JND[1], par("usr")[2], JND[1], col = "#00000012", border = NA)
  abline(h = 0, col = "grey40", lty = 2)
  polygon(c(grid, rev(grid)), c(dl, rev(du)), col = col_ci, border = NA)
  lines(grid, dfit, lwd = 2.6, col = col_line)
  abline(v = q, col = "grey55", lty = 3)
  par(op); dev.off()
  message("wrote Fig2_japanese_gradient.png")
}

message("DONE. figures in ", fig)
