options nocenter nonumber nodate ls=80 mprint symbolgen formdlim="*";

/* mock up a correlation bootstrap */
/* 1) manually bootstrap
   2) find a proc to do it
*/

data toy;

   /* heights and weights */
   do ii=1 to 25;
      ht = rand("Normal", 67, 4);
      wt = rand("Normal", 150, 15);
	  output;
   end;

   /* these are generated independently - corr will be near 0 */

run;

proc print data=toy;
run;

proc sgplot data=toy;
   scatter x=ht y=wt;
run;
/* looks like no assoc. */

proc corr data=toy;
run;
/* .007 with the first iteration */


%macro bootstrap(B=, STUFF=);

   /* generate a number 1 - 25
      take that II from Toy
      Repeat 25 time
      Calculate and store Corr
   */

   /* B := Number of Bootstrap Samples
      STUFF := Data with observations to resample
   */
 
   data corrs;
   set _NULL_;
   format corr 8.7;
   run;

   %do jj=1 %to &B.; 

   data lucky boot cor temp;
      set _NULL_;
   run;


 
   data lucky;
      do ii=1 to 25;
         rand_obs = round(rand("Uniform", 1, 25), 1);
		 output;
	  end;
	  drop ii;
	  rename rand_obs=ii;
   run;

   proc sort data=lucky;
      by ii;
   run;

   data boot;
      merge &STUFF. lucky (in=bb);
	  by ii;
	  if bb;
   run;

   proc corr data=boot outp=cor noprint;
      var ht wt;
   run;

   data temp;
      set cor;
	  if _N_=4;
	  keep wt;
	  rename wt=corr;
	run;

	data corrs;
	   set corrs temp;
	run;


   %end; /* end JJ loop */

   proc sort data=corrs;
   by corr;
   run;

   data percentile;
   set corrs;
   if _N_ in (5,50,95);
   run;

%mend;

%bootstrap(B=100, STUFF=toy);





/* generate correlated data 
      ht ~ N(67, 4)
      wt ~ N(150, 15)
      corr = 0.5
*/
data toy_cov (type=COV);
input _TYPE_ $ 1-4 _NAME_ $ 9-10 ht wt ;
datalines ;
COV     ht 16 30
COV     wt 30 225
MEAN       67 150
;

/* corr = cov/(sd1*sd2)
   cov = corr*sd1*sd2
       = 0.5*4*15
       = 30
*/

proc simnorm data=toy_cov outsim=toy_sim numreal=25 seed=73940;
   var ht wt;
run;

proc corr data=toy_sim;
   var ht wt;
run;

data toy_sim;
   set toy_sim;
   rename Rnum=ii;
run;

PROC datasets;
   delete boot cor corrs lucky temp;
run;

%bootstrap(B=100, STUFF=toy_sim);
* neat ;
* 0.217, 0.745    median=0.487 ;



proc univariate data=corrs;
   histogram corr;
   /* sd = 0.17296528
      mean = 0.47942915
   */
run;

/* if X,Y bivariate Normal -> */
data _tmp;
	file print;
   /* z = 0.5*ln(1+r/1-r)
   z +- 1.96*sqrt(1/n-3) */

   r = 0.47942915; /* mean of bootstrap corrs */
   n = 25;

   z = (0.5)*log( (1+r)/(1-r) );
   se = sqrt(1/(n-3));

   zL = z - (1.96*se);
   zU = z + (1.96*se);

   rL = (exp(2*zL)-1)/(exp(2*zL)+1);
   rU = (exp(2*zU)-1)/(exp(2*zU)+1);

   put "The 95% CI for r is : [" rL ", " rU "].";

   /* The 95% CI for r is : [0.1039920682 , 0.7352756347 ].  */
run;




/* now use a sampling proc instead of by hand sampling */


%macro bootstrap2(B=, STUFF=);

   /* generate a number 1 - 25
      take that II from Toy
      Repeat 25 time
      Calculate and store Corr
   */

   /* B := Number of Bootstrap Samples
      STUFF := Data with observations to resample
   */
 
   data corrs;
   set _NULL_;
   format corr 8.7;
   run;

   %do jj=1 %to &B.; 

   data lucky boot cor temp;
      set _NULL_;
   run;

   proc surveyselect data=&STUFF. out=boot noprint method=urs sampsize=25 outhits;
	run;

   proc corr data=boot outp=cor noprint;
      var ht wt;
   run;

   data temp;
      set cor;
	  if _N_=4;
	  keep wt;
	  rename wt=corr;
	run;

	data corrs;
	   set corrs temp;
	run;


   %end; /* end JJ loop */

   proc sort data=corrs;
   by corr;
   run;

   data percentile;
   set corrs;
   if _N_ in (5,50,95);
   run;

%mend;

PROC datasets;
   delete boot cor corrs lucky temp;
run;

%bootstrap2(B=100, STUFF=toy_sim);

/* [0.0086, 0.6288]



/************** LSAT and GPA Example ********************/

data law;
   input school lsat gpa;
   datalines;
   1 576 3.39
   2 635 3.30
   3 558 2.81
   4 578 3.03
   5 666 3.44
   6 580 3.07
   7 555 3.00
   8 661 3.43
   9 651 3.36
   10 605 3.13
   11 653 3.12
   12 575 2.74
   13 545 2.76
   14 572 2.88
   15 594 2.96
   ;
run;

proc corr data=law;
   var lsat gpa;
run;
/* r = 0.77637 */


%macro bootstrap2(B=, STUFF=, N=, VAR1=, VAR2=);

   /* B := Number of Bootstrap Samples
      STUFF := Data with observations to resample
      N := Sample size
   */
 
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

   data percentile;
   set corrs;
   if _N_ in (50,500,950);
   run;

%mend;

PROC datasets;
   delete boot cor corrs lucky temp;
run;

%bootstrap2(B=1000, STUFF=law, N=15, VAR1=lsat, VAR2=gpa);

proc univariate data=corrs;
   histogram corr;
run;

proc means data=corrs;
   var corr;
run;
/* SD is about the same as Efron & Tibshirani (they have 0.127, I get 0.130 */
/* Percentile interval does differ */
/* I get [0.521, 0.943] for a central 90%
   They get [0.488, 0.900] for a parametric bootstrap - unclear which type */




/* way faster */
proc surveyselect data=law noprint
   out=boot_law (rename=(Replicate=SampleID))
   method=urs
   sampsize=15
   reps=1000
   outhits;
run;

proc corr data=boot_law noprint outp=boot_law_corr;
   by sampleid;
   var lsat gpa;
run;

data boot_law_corr2 (keep=sampleid gpa);
   set boot_law_corr;
   if _NAME_ = "lsat";
run;

proc univariate data=boot_law_corr2;
      histogram gpa;
   run;
/* [0.497, 0.949] */
