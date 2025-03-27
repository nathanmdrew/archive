options nocenter nonumber nodate ls=80 formdlim="*" symbolgen mprint;

proc import datafile="C:\Users\vom8\Desktop\WFH\NTP\_summary_LUNG_FIBROSIS_24_6_2019.csv" out=summ1 dbms=csv replace;
run;

data summ2;
   set summ1 (keep=index DOSE num_examined n_ever_tumor);
run;

/* format: dose - respond (yes and no) - num per respond class */

data d2;
	set summ2;
	respond=1;
	nonrespond = num_examined - n_ever_tumor;
run;

data d3a;
   set d2 (drop=n_ever_tumor num_examined respond);
   respond=0;
   rename nonrespond=n;
run;

data d3b;
   set d2 (drop=num_examined nonrespond);
   rename n_ever_tumor=n;
run;

data d4;
   set d3a d3b;
run;

proc sort data=d4;
   by index dose respond;
run;

/* some dose/responds are duplicated (different dose desc, for example) */
/* make sure each dose has 0 or 1 for respond, sum the # responding */
proc summary data=d4 nway;
	class index dose respond;
	var n;
	output out=d5 (drop=_TYPE_ _FREQ_) sum()=n;
run;


/* index - dose counter JJ */
proc sort data=d5 out=d5_keys (keep=index dose) nodupkey;
   by index dose;
run;

data d5_keys2;
	set d5_keys;
	by index;

	if first.index then jj=1;
	else jj=jj+1;
	retain jj;
run;

data d6;
   merge d5 d5_keys2;
   by index dose;
run;



%macro ntp_trends();
   
	/* total number of relationships to examine */
	proc sql noprint;
		select max(index)
		into :maxindex
		from d6;
	quit;
	
	/* Cochran-Armitage (CA) Trend Test and Exact Chi Square for each relationship */
	%do ii=1 %to &maxindex.;

	    /*start with a blank trend result */
		data temp_trend;
			set _NULL_;
		run;

		data temp;
			set d6 (where=(index=&ii.));
		run;

		proc freq data=temp;
   			table dose * respond / trend;
   			weight n;
   			ods output TrendTest = temp_trend;
		run;
	
		data temp_trend2 (keep=index pvalue_trend CA_Trend);
			set temp_trend (where=(Name1 in ("PL_TREND", "PR_TREND"))); /* doesn't indicate direction of trend*/
			index=&ii.;
			pvalue_trend = nValue1;
			CA_Trend="N";
			if pvalue_trend < 0.05 then CA_Trend="Y";
		run;
		
		data results;
			set results temp_trend2;
		run;

	%end;

%mend;

data results;
	format index 2. pvalue_trend D12.3 CA_Trend $1. /*pvalue_chisq D12.3 ChiSq_Assoc $1.*/;
run;

%ntp_trends();

data results2;
	set results (where=(index NE .));
run;

proc sort data=results2;
   by index;
run;

/*data d5_keys3_backup;*/
/*	set d5_keys3;  error version */
/*run;*/

data d5_keys3;
	merge d5_keys2 results2;
	by index;
run;



proc sort data=d5_keys3 nodupkey out=index_trend (keep = index pvalue_trend CA_trend);
   by index pvalue_trend CA_trend;
run;

proc sort data=summ1 nodupkey out=results1 (keep = index chemical_name cas_number_y species_common_name strain sex2);
   by index chemical_name cas_number_y species_common_name strain sex2;
run;

data results1b;
	merge results1 index_trend;
	by index;
run;

/*proc freq data=results1b;*/
/*   table CA_trend;*/
/*run;*/
/**/
/*proc summary nway data=summ1;*/
/*   by index;*/
/*   var n_ever_tumor;*/
/*   output out=qc5 (drop=_TYPE_ _FREQ_) sum()=total_tumor;*/
/*run;*/

/*data qc6;*/
/*	set qc5;*/
/*	if total_tumor>0;*/
/*run;*/
/**/
/*data qc7;*/
/*   merge results1b qc5;*/
/*   by index;*/
/*run;*/
/**/
/*data qc8;*/
/*	set qc7;*/
/*	if total_tumor=0 and CA_trend="Y";*/
/*run;*/

/*data results1c;*/
/*   merge results1b qc5;*/
/*   by index;*/
/*run;*/



/* fishers exact for now --- not the best inferential method */
/* i think a permutation test might be better, but large sample sizes might make this intractable */

%macro ntp_fisher();

   /* total number of relationships to examine */
	proc sql noprint;
		select max(index)
		into :maxindex
		from d6;
	quit;

	%do kk=1 %to &maxindex.;
		data temp_fisher temp_fisher2;
			set _NULL_;
		run;

		data temp;
			set d6 (where=(index=&kk.));
		run;

		proc sql noprint;
			select max(jj)
			into :maxdoses
			from temp;
		quit;

		%do aa=2 %to &maxdoses.;
			data temp_fisher temp_fisher2;
				set _NULL_;
			run;

			proc freq data=temp;
				where jj in (1, &aa.);
				table dose*respond;
				weight n;
				exact fisher / maxtime=15;
				ods output FishersExact = temp_fisher;
			run;

			data temp_fisher2 (keep=index jj pvalue_fisher);
				set temp_fisher (where=(Name1="XPR_FISH"));
				index=&kk.;
				jj=&aa.;
				pvalue_fisher=nvalue1;
			run;

			data results_fisher;
				set results_fisher temp_fisher2;
			run;

		%end; /* end AA loop */

	%end; /* end KK loop */

%mend;

data results_fisher;
	format index 8. jj 8. pvalue_fisher D12.3;
run;

%ntp_fisher();

data results_fisher2;
	set results_fisher (where=(index NE .));
run;

data d5_keys4;
	merge d5_keys3 results_fisher2;
	by index jj;
run;

/*data d5_keys4_backup;*/
/*	set d5_keys4;*/
/*run;*/



proc sort data=summ2;
   by index dose;
run;
data d7;
	merge summ2 d5_keys4;
	by index dose;
run;
proc summary data=d7 nway;
   by index dose jj pvalue_trend CA_trend pvalue_fisher;
   var n_ever_tumor num_examined;
   output out=d8 (drop=_TYPE_ _FREQ_) sum()=total_fibrosis total_examined;
run;

proc export data=d8 outfile="C:\Users\vom8\Desktop\WFH\NTP\fibrosis_trendtest_fisherexact_results.xlsx" dbms=excel replace;
run;


data nl1;
	set d5_keys4;

	NOAEL=0;
	if CA_Trend="N" then NOAEL=1;
	if pvalue_fisher > 0.05 then NOAEL=1;
	if dose=0 then NOAEL=0;

	LOAEL=0;
	if pvalue_fisher < 0.05 and pvalue_fisher NE . then LOAEL=1;
	if dose=0 then LOAEL=0;
run;


data noael1;
	set nl1;
	if NOAEL=1;
run;

proc summary data=noael1 nway;
    class index;
	var dose;
	output out=noael2 (drop=_TYPE_ _FREQ_) max()=NOAEL_dose;
run;

data loael1;
	set nl1;
	if LOAEL=1;
run;

proc summary data=loael1 nway;
    class index;
	var dose;
	output out=loael2 (drop=_TYPE_ _FREQ_) min()=LOAEL_dose;
run;

data nl2;
	merge nl1 noael2 loael2;
	by index;
run;

data qc;
	set nl2;
	if (noael_dose > loael_dose) and loael_dose ne .;
run;

/* lazy ad-hoc fixing of incorrect NOAELs */
data nl3;
	set nl2;

	if index = 69 then noael_dose=10;
	if index = 70 then noael_dose=10;
	if index = 71 then noael_dose=5;
	if index = 72 then noael_dose=5;

run;



proc sort data=nl3 out=nl4 (keep=index noael_dose loael_dose) nodupkey;
   by index noael_dose loael_dose;
run;


proc sort data=summ1 out=final1(keep=index cas_number_y chemical_name species_common_name strain sex2 dose_unit) nodupkey;
   by index cas_number_y chemical_name species_common_name strain sex2 dose_unit;
run;

/* Identify duplicate indices, usually caused by differing dose metrics */
/*proc freq data=final2;*/
/*   table index/ out=qc2;*/
/*run;*/
/**/
/*data qc3;*/
/*   set qc2;*/
/*   if COUNT>1;*/
/*run;*/
/**/
/*data qc4;*/
/*   set final2;*/
/*   if index in (33, 34, 35, 36, 59, 60);*/
/*run;*/

data final2;
	merge final1 nl4;
	by index;

	if dose_unit in ("", "MG", "MG/ M") then delete; *controls, duplicate indices caused by different dose metrics;
	
run;
/* 93 rows for 93 indices - good */





/* Want: Data summary, trend test, NOAEL, LOAEL */
data final3;
   merge results1b final2(keep=index noael_dose loael_dose);
   by index;

   if index=86 and strain="Harlan" then delete; *clean up dupe;
run;

/* save summary */
proc export data=final3 outfile="C:\Users\vom8\Desktop\WFH\NTP\fibrosis_noael_loael.xlsx" dbms=excel replace;
run;






/* various QC */
proc freq data=final3;
   table CA_trend;
run;

data qc_noael_only qc_loael_only qc_both qc_neither;
   set final3;
   if noael_dose NE . and loael_dose=. then output qc_noael_only; *15;
   if noael_dose =. and loael_dose NE . then output qc_loael_only; *22;
   if noael_dose NE . and loael_dose NE . then output qc_both; *13;
   if noael_dose = . and loael_dose = . then output qc_neither; *43;
run;
