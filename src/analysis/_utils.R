## _utils.R — shared helpers for the R analysis scripts.
## Sourced by 01/02/03. Keeps config access and pathing in one place.

suppressWarnings(suppressMessages({
  library(yaml)
}))

## Resolve the repo root from this file's location, robust to getwd().
.repo_root <- function() {
  # when sourced, sys.frame(1)$ofile or normalizePath of the calling file
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
  here <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
  # this file lives in src/analysis/ ; repo root is two up
  root <- normalizePath(file.path(here, "..", ".."), mustWork = FALSE)
  if (file.exists(file.path(root, "config", "config.yaml"))) return(root)
  # fallback: walk up until config/config.yaml is found
  d <- normalizePath(getwd())
  for (i in 1:6) {
    if (file.exists(file.path(d, "config", "config.yaml"))) return(d)
    d <- dirname(d)
  }
  stop("could not locate repo root (config/config.yaml)")
}

REPO   <- .repo_root()
CONFIG <- yaml::read_yaml(file.path(REPO, "config", "config.yaml"))

repo_path <- function(...) file.path(REPO, ...)

## Semitone conversion. Differences in ST are reference-invariant, so for
## effective-RANGE and SLOPE of a smooth the choice of `ref` cancels; we use
## 1 Hz by default purely as a stable anchor.
hz_to_st <- function(hz, ref = 1) 12 * log2(hz / ref)

## F0 JND bands (semitones), single-sourced from config.jnd. `static` is the
## classic level-discrimination JND (~0.5-1 st); `movement` is the stricter
## pitch-MOVEMENT relevance threshold ('t Hart 1981, ~1.5 st) appropriate for an
## excursion DV. JND_THRESHOLDS is the sorted union used for exceeds-* columns.
.jnd_cfg <- (function() {
  j <- tryCatch(CONFIG$jnd, error = function(e) NULL)
  st <- if (!is.null(j$static))   as.numeric(j$static)   else c(0.5, 1.0)
  mv <- if (!is.null(j$movement)) as.numeric(j$movement) else c(1.0, 1.5)
  list(static = st, movement = mv, thresholds = sort(unique(c(st, mv))))
})()
JND_STATIC     <- .jnd_cfg$static
JND_MOVEMENT   <- .jnd_cfg$movement
JND_THRESHOLDS <- .jnd_cfg$thresholds

## Add one logical column per JND threshold (exceeds_JND_<t>) to a data.frame,
## testing `effcol` (default the 5-95% effective range) against each threshold.
add_jnd_flags <- function(df, effcol = "eff_range_5_95_st",
                          thresholds = JND_THRESHOLDS) {
  for (t in thresholds)
    df[[sprintf("exceeds_JND_%.1f", t)]] <- df[[effcol]] > t
  df
}

## N-audit line, appended to a log vector by the caller.
audit_line <- function(tag, n_input, n_used, n_speakers) {
  sprintf("[N-audit] %-28s n_input=%d n_used=%d n_dropped=%d n_speakers=%d",
          tag, n_input, n_used, n_input - n_used, n_speakers)
}
