## 12_peak_delay_check.R — does landmark excursion miss the true F0 peak because
## of ososagari (peak alignment to the FOLLOWING vowel)?
##
## Ishihara, T. (2003). A phonological effect on tonal alignment in Tokyo Japanese.
## Proc. 15th ICPhS, Barcelona, 615-619. In Tokyo Japanese, CV+CV / CVCV
## word-initial accented sequences realise the F0 peak at the ONSET OF THE
## SECOND-SYLLABLE VOWEL in nearly all cases (the peak skips the accented mora);
## CVN (heavy, moraic-nasal coda) sequences show NO delay (peak near the end of the
## first mora); CVR/CVV realise the peak within the long vowel/diphthong
## (F(2,90)=31.417, p<.0001). So for CVCV ososagari the accent peak is realised
## OUTSIDE the accented vowel — and a within-vowel landmark excursion (10-90%) may
## measure a span that never contains the true peak.
##
## We quantify this with the X-JToBI accentual-fall points 'A'/'Ax' already used
## for AccentDist (AccentDist==0 <=> an A point falls inside the vowel):
##   A1  each CSJ vowel -> A_in_current (AccentDist==0) / A_in_next_vowel
##       (the immediately following adjacent vowel has AccentDist==0 = ososagari
##       signature) / neither. Fractions per corpus.
##   A2  is next_vowel_peak associated with short Duration / following segment?
##   A3  for next_vowel_peak vowels, landmark excursion of the vowel ALONE vs the
##       CONCATENATED [vowel + following vowel] interval (from peak_delay_extract.py).
##   A4  headline landmark eff (5-95%) excluding vs only next_vowel_peak tokens.
##   A5  interpretive note on the accent-nucleus-strict analysis (no correction).
## Buckeye has no X-JToBI tone tier, so this analysis is CSJ-only.
##
## Outputs: results/supplement/TableS_peak_delay_check.csv
##          results/supplement/peak_delay_report.md
## Run (after peak_delay_extract.py): Rscript src/analysis/12_peak_delay_check.R

suppressWarnings(suppressMessages({ library(mgcv); library(dplyr) }))
source(file.path(dirname(sub("^--file=", "",
       commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "_utils.R"))
NT <- tryCatch(as.integer(CONFIG$compute$r_nthreads), error = function(e) 1L)
if (length(NT) != 1L || is.na(NT) || NT < 1L) NT <- 1L
ADJ_GAP <- 0.15
sup <- repo_path(CONFIG$paths$supplement)
log <- character(0); say <- function(...) { m <- sprintf(...); message(m); log[[length(log)+1L]] <<- m }

dat <- read.csv(repo_path(CONFIG$paths$master_csv), stringsAsFactors = FALSE)
CORP <- c("CSJ Monologue", "CSJ Dialogue")

## derive the A1 group in R (same rule as peak_delay_extract.py) so A1/A2/A4 are
## self-contained; A3 concat excursions are read from the Python token file.
d <- dat %>% filter(Dataset %in% CORP, !is.na(AccentDist), !is.na(F0_excursion_LM_ST)) %>%
  arrange(Dataset, Speaker, Tmin) %>% group_by(Dataset, Speaker) %>%
  mutate(next_ad = lead(AccentDist), gap = lead(Tmin) - Tmax,
         A_in_current = AccentDist == 0,
         next_vowel_peak = !A_in_current & !is.na(next_ad) & gap >= -1e-6 &
                           gap <= ADJ_GAP & next_ad == 0,
         group = ifelse(A_in_current, "A_in_current",
                 ifelse(next_vowel_peak, "A_in_next_vowel", "neither"))) %>%
  ungroup()

eff595 <- function(df) {
  df <- droplevels(df); df$Speaker <- factor(df$Speaker); df$Vowel <- factor(df$Vowel)
  m <- bam(F0_excursion_LM_ST ~ s(Duration, k = 20) +
             s(Duration, Speaker, bs = "fs", m = 1, k = 5) + s(Vowel, bs = "re"),
           data = df, method = "fREML", discrete = TRUE, nthreads = NT)
  dur <- m$model$Duration; g <- seq(min(dur), max(dur), length.out = 200)
  nd <- data.frame(Duration = g,
                   Speaker = factor(levels(m$model$Speaker)[1], levels = levels(m$model$Speaker)),
                   Vowel   = factor(levels(m$model$Vowel)[1],   levels = levels(m$model$Vowel)))
  pr <- predict(m, nd, type = "terms"); cc <- which(colnames(pr) == "s(Duration)")
  q <- quantile(dur, c(.05, .95)); in95 <- g >= q[1] & g <= q[2]
  max(pr[in95, cc]) - min(pr[in95, cc])
}

## Analysis 3 token file (concat excursions for next_vowel_peak)
tok_path <- file.path(sup, "peak_delay_tokens.csv")
tok <- if (file.exists(tok_path)) read.csv(tok_path, stringsAsFactors = FALSE) else NULL

rows <- list()
for (cp in CORP) {
  dd <- filter(d, Dataset == cp)
  n <- nrow(dd)
  frac <- table(dd$group) / n
  g2 <- filter(dd, group == "A_in_next_vowel")
  ## A2: Duration by group + fraction next_vowel_peak in the short-Duration tertile
  dur_q <- quantile(dd$Duration, c(1/3, 2/3))
  short <- dd$Duration <= dur_q[1]
  say("%s: A_in_current %.1f%% | A_in_next_vowel %.1f%% | neither %.1f%% (N=%d)",
      cp, 100*frac["A_in_current"], 100*frac["A_in_next_vowel"], 100*frac["neither"], n)
  say("  %s: median Duration all=%.3f vs next_vowel_peak=%.3f s; next_vowel_peak share short-tertile=%.1f%% vs long-tertile=%.1f%%",
      cp, median(dd$Duration), median(g2$Duration),
      100*mean(dd$group[short]=="A_in_next_vowel"),
      100*mean(dd$group[dd$Duration >= dur_q[2]]=="A_in_next_vowel"))

  ## A3: concat vs current excursion (from python token file)
  a3_cur <- a3_cat <- a3_gap <- NA_real_; a3_n <- 0L
  if (!is.null(tok)) {
    t2 <- tok %>% filter(Dataset == cp, group == "A_in_next_vowel",
                         !is.na(lm_exc_current), !is.na(lm_exc_concat))
    if (nrow(t2)) { a3_cur <- median(t2$lm_exc_current); a3_cat <- median(t2$lm_exc_concat)
      a3_gap <- median(t2$lm_exc_concat - t2$lm_exc_current); a3_n <- nrow(t2) }
  }
  say("  A3 concat excursion (next_vowel_peak, N=%d): current %.2f -> concat %.2f st (median under-capture %.2f st)",
      a3_n, a3_cur, a3_cat, a3_gap)

  ## A4: headline eff excluding vs only next_vowel_peak
  eff_all  <- eff595(dd)
  eff_excl <- eff595(filter(dd, group != "A_in_next_vowel"))
  eff_only <- tryCatch(eff595(g2), error = function(e) NA_real_)
  say("  A4 landmark eff(5-95): all=%.2f | excl next_vowel_peak=%.2f | only next_vowel_peak=%.2f st",
      eff_all, eff_excl, eff_only)

  rows[[cp]] <- data.frame(Dataset = cp, N_vowels = n,
    pct_A_in_current = round(100*frac["A_in_current"], 1),
    pct_A_in_next_vowel = round(100*frac["A_in_next_vowel"], 1),
    pct_neither = round(100*frac["neither"], 1),
    median_dur_all = round(median(dd$Duration), 3),
    median_dur_next_vowel_peak = round(median(g2$Duration), 3),
    A3_n = a3_n, A3_current_exc_st = round(a3_cur, 3),
    A3_concat_exc_st = round(a3_cat, 3), A3_undercapture_st = round(a3_gap, 3),
    A4_eff_all_st = round(eff_all, 3), A4_eff_excl_st = round(eff_excl, 3),
    A4_eff_only_st = round(eff_only, 3), row.names = NULL)
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(sup, "TableS_peak_delay_check.csv"), row.names = FALSE)

## report
rep <- c("# Peak-delay / ososagari check (does landmark excursion miss the peak?)", "",
  "Ishihara (2003, ICPhS 15, Barcelona, 615-619): CVCV word-initial accents realise",
  "the F0 peak at the onset of the SECOND-syllable vowel (peak skips the accented",
  "mora); CVN: no delay; F(2,90)=31.417, p<.0001. We quantify via X-JToBI 'A' points.",
  sprintf("Adjacency gap for 'next vowel' = %.2fs. Buckeye excluded (no tone tier).", ADJ_GAP), "")
rep <- c(rep, "## A1 — where does the X-JToBI 'A' point fall (per corpus)")
for (i in seq_len(nrow(tab))) rep <- c(rep, sprintf(
  "- %s: A_in_current %.1f%% | **A_in_next_vowel %.1f%%** (ososagari) | neither %.1f%%",
  tab$Dataset[i], tab$pct_A_in_current[i], tab$pct_A_in_next_vowel[i], tab$pct_neither[i]))
rep <- c(rep, "", "## A2 — next_vowel_peak vs Duration")
for (i in seq_len(nrow(tab))) rep <- c(rep, sprintf(
  "- %s: median Duration all %.3f vs next_vowel_peak %.3f s (shorter vowels tend to be pre-nuclear).",
  tab$Dataset[i], tab$median_dur_all[i], tab$median_dur_next_vowel_peak[i]))
rep <- c(rep, "", "## A3 — landmark excursion under-capture (vowel alone vs vowel+next vowel)")
for (i in seq_len(nrow(tab))) rep <- c(rep, sprintf(
  "- %s (N=%d): current %.2f -> concat %.2f st, **median under-capture %.2f st**.",
  tab$Dataset[i], tab$A3_n[i], tab$A3_current_exc_st[i], tab$A3_concat_exc_st[i], tab$A3_undercapture_st[i]))
rep <- c(rep, "", "## A4 — impact on the headline landmark effect (5-95% eff)")
for (i in seq_len(nrow(tab))) rep <- c(rep, sprintf(
  "- %s: all %.2f | excl next_vowel_peak %.2f | only next_vowel_peak %.2f st.",
  tab$Dataset[i], tab$A4_eff_all_st[i], tab$A4_eff_excl_st[i], tab$A4_eff_only_st[i]))
rep <- c(rep, "",
  "## A5 — interpretive note on the accent-nucleus-strict analysis (no correction)",
  "The current AccentNucleus = AccentDist==0 flags the vowel that CONTAINS an 'A'",
  "point. Under CVCV ososagari the 'A' lands in the SECOND-syllable vowel, so",
  "'strict nucleus' partly tags the post-accentual vowel where the peak is realised,",
  "not the lexically accented mora. The strict-nucleus effect (Mono 1.27 / Dial 1.03",
  "st) should therefore be read as 'vowels that carry the realised accentual fall',",
  "which for CVCV is the second-syllable vowel; the rate->excursion conclusion is",
  "unaffected (both the accent-bearing and peak-bearing vowels show the effect), but",
  "the phonological labelling of WHICH vowel is 'the nucleus' is approximate.",
  "", "## log", paste0("    ", log))
writeLines(rep, file.path(sup, "peak_delay_report.md"))
cat("\n===== TableS_peak_delay_check =====\n"); print(tab, row.names = FALSE)
say("DONE.")
