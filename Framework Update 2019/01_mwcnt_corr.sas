/* What's the correlation between CNT potency and Length? */
/* What's the uncertainty in that estimate ? */

proc import datafile="Z:\ENM Categories\Framework Update 2019\MWCNT_potency_length_corr.xlsx" out=cnt1 
   dbms=excel
   replace;
run;

data cnt2;
   set cnt1;

   length_nm = length;
   if length_units NE "nm" then length_nm = length*1000;
run;

/* omit the missing lengths */
data cnt3;
   set cnt2;
   if length_nm > 0;
   rename BMD__ug_g_lung_=BMD;
run;

proc sgplot data=cnt3;
   scatter x=length_nm y=BMD;
run;

proc reg data=cnt3;
   model bmd = length_nm;
quit;
/* not a significant association
   slope = 0.004, p-value = 0.1339
   so for a 1000nm increase in length, associated with increase in potency of 4 ug/g lung on average
*/

proc corr data=cnt3 fisher (biasadj=no);
   var bmd length_nm;
run;

%macro bootstrap(B=, STUFF=, VAR1=, VAR2=);

   /* B := Number of Bootstrap Samples
      STUFF := Data with observations to resample
	  VAR1 := First variable in association (X)
      VAR2 := Second variable in association (Y)
   */

   PROC datasets;
      delete boot cor corrs lucky temp;
   run;
 
   proc sql noprint;
   	  select count(&VAR1.)
	  into :N
	  from &STUFF.;
	quit;

   data corrs;
      set _NULL_;
      format corr 8.7;
   run;

   %do jj=1 %to &B.; 

      data lucky boot cor temp;
         set _NULL_;
      run;

      proc surveyselect data=&STUFF. out=boot noprint method=urs sampsize=&N. outhits;
	  run;

      proc corr data=boot outp=cor noprint;
         var &VAR1. &VAR2.;
      run;

      data temp;
         set cor;
	     if _N_=4;
	     keep &VAR2.;
	     rename &VAR2.=corr;
	   run;

	   data corrs;
	      set corrs temp;
	   run;


   %end; /* end JJ loop */

   proc sort data=corrs;
      by corr;
   run;

   proc univariate data=corrs;
      histogram corr;
   run;

%mend;

%bootstrap(B=1000, STUFF=cnt3, VAR1=BMD, VAR2=length_nm);

/* 90% percentile interval (5% to 95%)
   [-0.132, 0.813]
*/


/* way faster */
proc surveyselect data=cnt3 noprint
   out=boot_cnt (rename=(Replicate=SampleID))
   method=urs
   sampsize=16
   reps=10000
   outhits;
run;

proc corr data=boot_cnt noprint outp=boot_corr;
   by sampleid;
   var bmd length_nm;
run;

data boot_corr2 (keep=sampleid length_nm);
   set boot_corr;
   if _NAME_ = "BMD";
run;

proc univariate data=boot_corr2 (rename=(length_nm=Correlation));
      histogram Correlation;
   run;



/* look at theresas data */
data cnt4;
   set cnt3;
   if index < 71;
run;

proc corr data=cnt4 fisher (biasadj=no);
   var bmd length_nm;
run;

/* way faster */
proc surveyselect data=cnt4 noprint
   out=boot_cnt2 (rename=(Replicate=SampleID))
   method=urs
   sampsize=12
   reps=10000
   outhits;
run;

proc corr data=boot_cnt2 noprint outp=boot_corr2;
   by sampleid;
   var bmd length_nm;
run;

data boot_corr22 (keep=sampleid length_nm);
   set boot_corr2;
   if _NAME_ = "BMD";
run;

proc univariate data=boot_corr22 (rename=(length_nm=Correlation));
      histogram Correlation;
   run;
