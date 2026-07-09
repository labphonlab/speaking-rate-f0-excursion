## loso_10lvl.R — leave-one-speaker-out on the 10-level (short+long) primary model.
## Confirms no single speaker drives the rate->landmark-excursion effect.
suppressWarnings(suppressMessages(library(mgcv)))
A<-commandArgs(FALSE); REPO<-normalizePath(file.path(dirname(sub("^--file=","",A[grep("^--file=",A)])),"..",".."))
dat<-read.csv(file.path(REPO,"data/03_processed/rate_f0_master.csv"),stringsAsFactors=FALSE)
fit_one<-function(df) suppressWarnings(bam(F0_excursion_LM_ST ~ s(Duration,k=20)+s(Duration,Speaker,bs="fs",m=1,k=5)+s(Vowel,bs="re"),
  data=df, method="fREML", discrete=TRUE, nthreads=1L))
eff595<-function(m,dur){ g<-seq(min(dur),max(dur),length.out=200)
  nd<-data.frame(Duration=g,Speaker=levels(m$model$Speaker)[1],Vowel=levels(m$model$Vowel)[1])
  pr<-predict(m,nd,type="terms"); f<-pr[,which(colnames(pr)=="s(Duration)")]
  q<-quantile(dur,c(.05,.95)); i<-g>=q[1]&g<=q[2]; max(f[i])-min(f[i]) }
rows<-list()
for(nm in c("CSJ Monologue","CSJ Dialogue")){
  d<-dat[dat$Dataset==nm & !is.na(dat$F0_excursion_LM_ST) & !is.na(dat$Duration),]
  d$Speaker<-factor(d$Speaker); d$Vowel<-factor(d$Vowel)
  full<-eff595(fit_one(d),d$Duration)
  spk<-levels(d$Speaker); effs<-numeric(length(spk))
  for(i in seq_along(spk)){ di<-droplevels(d[d$Speaker!=spk[i],]); effs[i]<-tryCatch(eff595(fit_one(di),di$Duration),error=function(z)NA) }
  effs<-effs[is.finite(effs)]
  cat(sprintf("[%s] 10lvl full eff=%.3f | LOSO n=%d: range=[%.3f, %.3f]  all>1.0=%s  all>1.5=%s  most-influential(drop->%s spk %s: %.3f)\n",
    nm, full, length(effs), min(effs), max(effs), all(effs>1.0), all(effs>1.5),
    ifelse(which.min(effs)==which.min(effs),"lowest",""), spk[which.min(effs)], min(effs)))
  rows[[nm]]<-data.frame(corpus=nm,n_speakers=length(effs),full_eff=round(full,3),
    loso_min=round(min(effs),3),loso_max=round(max(effs),3),all_above_1.0=all(effs>1.0),all_above_1.5=all(effs>1.5))
}
write.csv(do.call(rbind,rows),file.path(REPO,"results/supplement/TableS_loso_10lvl.csv"),row.names=FALSE)
cat("wrote results/supplement/TableS_loso_10lvl.csv\n")
