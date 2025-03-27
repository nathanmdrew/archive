/* Multiple Comparisons for NOAEL/LOAEL identification - proportion response */
/* Fisher's Exact Test?  Used in Silver CIB, Kasai CNT */
/*      Not really a fan of this, as it was designed with the Fixed Marginal Totals, which isn't true in a dose-response exp */
/* Bonferroni 2 sample proportion tests? */
/* non-parametric?  kruskal-wallis (ANOVA) to exact Wilcoxon? */

options nocenter nonumber nodate ls=80 formdlim="*" symbolgen mprint;

proc import datafile="C:\Users\vom8\Desktop\WFH\NTP\_temp_summary.xlsx" out=ntp_infl dbms=excel replace;
	sheet="_temp_summary";
run;

data d1 (keep=index dose n_ever_infl num_examined);
   set ntp_infl;
run;

/* format: dose - respond (yes and no) - num respond */

data d2;
	set d1;
	respond=1;
	nonrespond = num_examined - n_ever_infl;
run;

data d3a;
   set d2 (drop=n_ever_infl num_examined respond);
   respond=0;
   rename nonrespond=n;
run;

data d3b;
   set d2 (drop=num_examined nonrespond);
   rename n_ever_infl=n;
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


/* index - dose counter */
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

data d5_keys3;
	merge d5_keys2 results2;
	by index;
run;


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
		data temp;
			set d6 (where=(index=&kk.));
		run;

		proc sql noprint;
			select max(jj)
			into :maxdoses
			from temp;
		quit;

		%do aa=2 %to &maxdoses.;
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

	if index in (65,66,67,70,84) then noael_dose=.;
run;

proc sort data=nl3 out=nl4 (keep=index noael_dose loael_dose) nodupkey;
   by index noael_dose loael_dose;
run;


proc sort data=ntp_infl out=final1(keep=index study_title cas_number_y chemical_name species_common_name strain sex2 dose_unit) nodupkey;
   by index study_title cas_number_y chemical_name species_common_name strain sex2 dose_unit;
run;

data final2;
	merge final1 nl4;
	by index;

	if index=87 and strain="HSD" then delete; /* duplicate strain info */
	if dose_unit in ("", "MG", "MG/ M3") then delete; /* duplicate dose units */
	*_N = _N_;
	if _N_ in (13,15,17,19,66,69,71,127,130,133,136,145,169,174,178,184) then delete;
run;


/* save summary */
proc export data=final2 outfile="\\cdc.gov\private\M606\vom8\MyLargeWorkspace Backup\NTPDatabase\_backup_16aug2018\WFH\NTP\infl_noael_loael.xlsx" dbms=excel;
run;


/* add to BMD results - may be easier this way since Inflammation indices are messed up */
proc import datafile="C:\Users\vom8\Desktop\_bmd_summary_05sep2018.xlsx" out=infl_bmd1 dbms=excel;
   sheet="Inflammation";
run;

data final3 (drop=dose_unit);
	set final2;
	rename cas_number_y = CAS_Number
			chemical_name = Material
			species_common_name = Species
			sex2 = sex
			index=index2;
run;

proc sort data=infl_bmd1;   by cas_number material species strain sex;  run;
proc sort data=final3;	by cas_number material species strain sex; run;

data final4;
	merge infl_bmd1 final3;
	by cas_number material species strain sex;
run;
