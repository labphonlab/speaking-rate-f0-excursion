## long_vowel_subset.R — rate -> landmark-excursion for the LONG-vowel subset
## (CSJ Monologue & Dialogue), vs the short-vowel subset, with speaker-cluster
## bootstrap 95% CIs. Vowel levels: short {a,i,u,e,o}, long {ah,ih,uh,eh,oh}.
suppressWarnings(suppressMessages({ library(mgcv) }))
A<-commandArgs(FALSE); REPO<-normalizePath(file.path(dirname(sub("^--file=","",A[grep("^--file=",A)])),"..",".."))
GRID_N<-200; B<-1000; SEED<-2026; set.seed(SEED)
need<-c("Dataset","Speaker","Vowel","Duration","F0_excursion_LM_ST")
dat<-tryCatch({suppressMessages(library(data.table)); as.data.frame(fread(file.path(REPO,"data/03_processed/rate_f0_master.csv"),select=need))},
  error=function(e) read.csv(file.path(REPO,"data/03_processed/rate_f0_master.csv"),stringsAsFactors=FALSE)[,need])
LONG<-c("ah","ih","uh","eh","oh"); SHORT<-c("a","i","u","e","o")

fit_one<-function(df) suppressWarnings(bam(F0_excursion_LM_ST ~ s(Duration,k=20)+s(Duration,Speaker,bs="fs",m=1,k=5)+s(Vowel,bs="re"),
  data=df, method="fREML", discrete=TRUE, nthreads=1L))
eff<-function(model,dur){
  grid<-seq(min(dur),max(dur),length.out=GRID_N)
  nd<-data.frame(Duration=grid,Speaker=factor(levels(model$model$Speaker)[1],levels=levels(model$model$Speaker)),
    Vowel=factor(levels(model$model$Vowel)[1],levels=levels(model$model$Vowel)))
  pr<-predict(model,newdata=nd,type="terms"); fit<-pr[,which(colnames(pr)=="s(Duration)")]
  q<-as.numeric(quantile(dur,c(0.05,0.95))); in95<-grid>=q[1]&grid<=q[2]
  p5<-approx(grid,fit,xout=q[1])$y; p95<-approx(grid,fit,xout=q[2])$y
  list(eff595=max(fit[in95])-min(fit[in95]), sign=unname(p5-p95))   # sign<0 => shrinks when fast
}
prep<-function(d){ d<-d[!is.na(d$Duration)&!is.na(d$Vowel)&!is.na(d$Speaker)&!is.na(d$F0_excursion_LM_ST),]
  d$Speaker<-factor(d$Speaker); d$Vowel<-factor(d$Vowel); d }

rows<-list()
for(nm in c("CSJ Monologue","CSJ Dialogue")){
  for(sub in c("long")){
    vs<-if(sub=="long") LONG else SHORT
    d<-prep(dat[dat$Dataset==nm & dat$Vowel %in% vs,])
    m<-fit_one(d); e<-eff(m,d$Duration)
    spk<-levels(d$Speaker); idx<-split(seq_len(nrow(d)),d$Speaker)
    boots<-numeric(B); tb<-Sys.time()
    for(b in seq_len(B)){
      drawn<-sample(spk,length(spk),replace=TRUE); r<-unlist(idx[drawn],use.names=FALSE)
      db<-d[r,]; db$Speaker<-factor(rep(paste0("s",seq_along(drawn)),lengths(idx[drawn])))
      boots[b]<-tryCatch(eff(fit_one(db),db$Duration)$eff595,error=function(z) NA_real_)
    }
    boots<-boots[is.finite(boots)]; ci<-as.numeric(quantile(boots,c(0.025,0.975)))
    dir<-if(e$sign< -0.05)"shrinks_when_fast" else if(e$sign>0.05)"grows_when_fast" else "flat"
    cat(sprintf("[%s / %s] N=%d spk=%d  eff595=%.3f  sign=%.3f (%s)  95%%CI=[%.3f, %.3f] (n_boot=%d, %.0fs)\n",
      nm,sub,nrow(d),length(spk),e$eff595,e$sign,dir,ci[1],ci[2],length(boots),as.numeric(Sys.time()-tb,units="secs")))
    rows[[paste(nm,sub)]]<-data.frame(corpus=nm,subset=sub,N=nrow(d),n_speakers=length(spk),
      eff595_st=round(e$eff595,3),sign=round(e$sign,3),direction=dir,
      ci_lo=round(ci[1],3),ci_hi=round(ci[2],3),clears_1.0=ci[1]>1.0,seed=SEED)
  }
}
out<-do.call(rbind,rows)
write.csv(out,file.path(REPO,"results/supplement/TableS_long_vowel_subset.csv"),row.names=FALSE)
cat("\nwrote results/supplement/TableS_long_vowel_subset.csv\n")
