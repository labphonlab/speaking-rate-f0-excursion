## integrated_allvowel.R — verification (a): FULL integrated model (short+long,
## 10 vowel levels) on the expanded master, identical GAMM spec to the primary
## analysis. Reports 5-95% effective range vs short-only (1.52/1.38), % change,
## s(Vowel) k.check, and speaker-cluster bootstrap 95% CI.
suppressWarnings(suppressMessages({ library(mgcv) }))
A<-commandArgs(FALSE); REPO<-normalizePath(file.path(dirname(sub("^--file=","",A[grep("^--file=",A)])),"..",".."))
GRID_N<-200; B<-1000; SEED<-2026; set.seed(SEED)
need<-c("Dataset","Speaker","Vowel","Duration","F0_excursion_LM_ST")
dat<-tryCatch({suppressMessages(library(data.table)); as.data.frame(fread(file.path(REPO,"data/03_processed/rate_f0_master.csv"),select=need))},
  error=function(e) read.csv(file.path(REPO,"data/03_processed/rate_f0_master.csv"),stringsAsFactors=FALSE)[,need])
SHORT_ONLY<-c("CSJ Monologue"=1.519,"CSJ Dialogue"=1.377)

fit_one<-function(df) suppressWarnings(bam(F0_excursion_LM_ST ~ s(Duration,k=20)+s(Duration,Speaker,bs="fs",m=1,k=5)+s(Vowel,bs="re"),
  data=df, method="fREML", discrete=TRUE, nthreads=1L))
eff595<-function(model,dur){
  grid<-seq(min(dur),max(dur),length.out=GRID_N)
  nd<-data.frame(Duration=grid,Speaker=factor(levels(model$model$Speaker)[1],levels=levels(model$model$Speaker)),
    Vowel=factor(levels(model$model$Vowel)[1],levels=levels(model$model$Vowel)))
  pr<-predict(model,newdata=nd,type="terms"); fit<-pr[,which(colnames(pr)=="s(Duration)")]
  q<-as.numeric(quantile(dur,c(0.05,0.95))); in95<-grid>=q[1]&grid<=q[2]
  max(fit[in95])-min(fit[in95])
}
prep<-function(d){ d<-d[!is.na(d$Duration)&!is.na(d$Vowel)&!is.na(d$Speaker)&!is.na(d$F0_excursion_LM_ST),]
  d$Speaker<-factor(d$Speaker); d$Vowel<-factor(d$Vowel); d }

rows<-list()
for(nm in c("CSJ Monologue","CSJ Dialogue")){
  d<-prep(dat[dat$Dataset==nm,])
  m<-fit_one(d); pe<-eff595(m,d$Duration)
  cat(sprintf("\n===== %s : ALL VOWELS (10 levels) =====\n",nm))
  cat(sprintf("N=%d  n_speakers=%d  n_vowel_levels=%d (%s)\n", nrow(d), nlevels(d$Speaker), nlevels(d$Vowel), paste(levels(d$Vowel),collapse=",")))
  so<-SHORT_ONLY[[nm]]
  cat(sprintf("eff595 (all-vowel) = %.3f st  |  short-only = %.3f st  |  change = %+.3f st (%+.1f%%)\n", pe, so, pe-so, 100*(pe-so)/so))
  cat("--- k.check ---\n"); print(round(k.check(m),4)); flush.console()
  # bootstrap CI (speaker-cluster)
  spk<-levels(d$Speaker); idx<-split(seq_len(nrow(d)),d$Speaker); boots<-numeric(B); tb<-Sys.time()
  for(b in seq_len(B)){
    drawn<-sample(spk,length(spk),replace=TRUE); r<-unlist(idx[drawn],use.names=FALSE)
    db<-d[r,]; db$Speaker<-factor(rep(paste0("s",seq_along(drawn)),lengths(idx[drawn])))
    boots[b]<-tryCatch(eff595(fit_one(db),db$Duration),error=function(z) NA_real_)
  }
  boots<-boots[is.finite(boots)]; ci<-as.numeric(quantile(boots,c(0.025,0.975)))
  cat(sprintf(">> bootstrap 95%% CI = [%.3f, %.3f] (n_boot=%d, %.0fs) | clears 1.0 stably=%s\n", ci[1],ci[2],length(boots),as.numeric(Sys.time()-tb,units="secs"), ci[1]>1.0))
  rows[[nm]]<-data.frame(corpus=nm,model="all_vowels_10lvl",N=nrow(d),n_speakers=nlevels(d$Speaker),n_vowel_levels=nlevels(d$Vowel),
    eff595_all=round(pe,3),eff595_shortonly=so,change_st=round(pe-so,3),change_pct=round(100*(pe-so)/so,1),
    ci_lo=round(ci[1],3),ci_hi=round(ci[2],3),clears_1.0=ci[1]>1.0,seed=SEED)
}
write.csv(do.call(rbind,rows),file.path(REPO,"results/supplement/TableS_integrated_allvowel.csv"),row.names=FALSE)
cat("\nwrote results/supplement/TableS_integrated_allvowel.csv\n")
