## bootstrap_ci.R — speaker-cluster bootstrap 95% CIs for the 5-95% effective
## range of the landmark-excursion rate effect (Table 2), + leave-one-speaker-out.
## Resamples SPEAKERS with replacement (tokens kept intact within speaker;
## duplicated speakers relabelled to distinct levels), refits the same GAMM, and
## recomputes eff_595. Reproducible: fixed seed. Outputs:
##   results/supplement/TableS_bootstrap_ci.csv / TableS_loso.csv / bootstrap_ci_report.md
suppressWarnings(suppressMessages({ library(mgcv) }))
A <- commandArgs(FALSE); REPO <- normalizePath(file.path(dirname(sub("^--file=","",A[grep("^--file=",A)])),"..",".."))
SUP <- file.path(REPO, "results", "supplement")
GRID_N <- 200; B <- 1000; SEED <- 2026
set.seed(SEED)
need <- c("Dataset","Speaker","Vowel","Duration","F0_excursion_LM_ST")

t0 <- Sys.time()
dat <- tryCatch({ suppressMessages(library(data.table))
  as.data.frame(fread(file.path(REPO,"data/03_processed/rate_f0_master.csv"), select=need)) },
  error=function(e) read.csv(file.path(REPO,"data/03_processed/rate_f0_master.csv"), stringsAsFactors=FALSE)[,need])
cat(sprintf("[%.0fs] loaded %d rows\n", as.numeric(Sys.time()-t0,units="secs"), nrow(dat)))

fit_one <- function(df) suppressWarnings(bam(
  DV ~ s(Duration, k=20) + s(Duration, Speaker, bs="fs", m=1, k=5) + s(Vowel, bs="re"),
  data=df, method="fREML", discrete=TRUE, nthreads=1L))

eff595 <- function(model, dur) {
  grid <- seq(min(dur), max(dur), length.out=GRID_N)
  nd <- data.frame(Duration=grid,
    Speaker=factor(levels(model$model$Speaker)[1], levels=levels(model$model$Speaker)),
    Vowel  =factor(levels(model$model$Vowel)[1],   levels=levels(model$model$Vowel)))
  pr <- predict(model, newdata=nd, type="terms")
  fit <- pr[, which(colnames(pr)=="s(Duration)")]
  q <- as.numeric(quantile(dur, c(0.05,0.95))); in95 <- grid>=q[1] & grid<=q[2]
  max(fit[in95]) - min(fit[in95])
}

prep <- function(d) { d$DV <- d$F0_excursion_LM_ST
  d <- d[!is.na(d$Duration)&!is.na(d$Vowel)&!is.na(d$Speaker)&!is.na(d$DV), ]
  d$Speaker <- factor(d$Speaker); d$Vowel <- factor(d$Vowel); d }

corpora <- c("CSJ Monologue","Buckeye","CSJ Dialogue")
ci_rows <- list(); loso_rows <- list()

for (nm in corpora) {
  d <- prep(dat[dat$Dataset==nm, ])
  spk <- levels(d$Speaker); idx <- split(seq_len(nrow(d)), d$Speaker)
  point <- eff595(fit_one(d), d$Duration)
  cat(sprintf("[%s] N=%d spk=%d point=%.3f -> bootstrap B=%d\n", nm, nrow(d), length(spk), point, B)); flush.console()

  boots <- numeric(B); tb <- Sys.time()
  for (b in seq_len(B)) {
    drawn <- sample(spk, length(spk), replace=TRUE)
    rows <- unlist(idx[drawn], use.names=FALSE)
    db <- d[rows, ]; db$Speaker <- factor(rep(paste0("s",seq_along(drawn)), lengths(idx[drawn])))
    boots[b] <- tryCatch(eff595(fit_one(db), db$Duration), error=function(e) NA_real_)
    if (b %% 100 == 0) cat(sprintf("   %s %d/%d (%.0fs)\n", nm, b, B, as.numeric(Sys.time()-tb,units="secs")))
  }
  boots <- boots[is.finite(boots)]
  ci <- as.numeric(quantile(boots, c(0.025, 0.975)))
  ci_rows[[nm]] <- data.frame(corpus=nm, DV="landmark_excursion",
    point_estimate=round(point,3), ci_lower_95=round(ci[1],3), ci_upper_95=round(ci[2],3),
    n_boot=length(boots), seed=SEED,
    clears_1.0_stably = ci[1] > 1.0, clears_1.5_stably = ci[1] > 1.5)
  cat(sprintf("   -> 95%% CI [%.3f, %.3f] (n_boot=%d)\n", ci[1], ci[2], length(boots)))

  loso <- sapply(spk, function(s) tryCatch(eff595(fit_one(droplevels(d[d$Speaker!=s,])),
                                                  d$Duration[d$Speaker!=s]), error=function(e) NA_real_))
  loso_rows[[nm]] <- data.frame(corpus=nm, speaker=spk, eff595_wo_speaker=round(loso,3))
  cat(sprintf("   LOSO range [%.3f, %.3f]; point %.3f\n", min(loso,na.rm=TRUE), max(loso,na.rm=TRUE), point))
  write.csv(do.call(rbind, ci_rows),   file.path(SUP,"TableS_bootstrap_ci.csv"), row.names=FALSE)
  write.csv(do.call(rbind, loso_rows), file.path(SUP,"TableS_loso.csv"), row.names=FALSE)
}

ci_df <- do.call(rbind, ci_rows)
rep <- c("# Bootstrap 95% CIs for the landmark-excursion effective range", "",
  sprintf("Speaker-cluster bootstrap (B=%d, seed=%d); leave-one-speaker-out below.", B, SEED), "",
  "| corpus | point | 95% CI | clears 1.0 st stably | clears 1.5 st stably |","|---|---|---|---|---|")
for (i in seq_len(nrow(ci_df))) rep <- c(rep, sprintf("| %s | %.3f | [%.3f, %.3f] | %s | %s |",
  ci_df$corpus[i], ci_df$point_estimate[i], ci_df$ci_lower_95[i], ci_df$ci_upper_95[i],
  ci_df$clears_1.0_stably[i], ci_df$clears_1.5_stably[i]))
rep <- c(rep, "", "## Leave-one-speaker-out (effective range with each single speaker removed)")
lo <- do.call(rbind, loso_rows)
for (nm in corpora) { x <- lo$eff595_wo_speaker[lo$corpus==nm]
  rep <- c(rep, sprintf("- %s: range [%.3f, %.3f] across all single-speaker deletions.", nm, min(x), max(x))) }
writeLines(rep, file.path(SUP,"bootstrap_ci_report.md"))
cat(sprintf("[%.0fs] DONE\n", as.numeric(Sys.time()-t0,units="secs")))
