options nocenter nonumber nodate ls=80 formdlim="*" symbolgen mprint;

proc import datafile="C:\Users\vom8\Desktop\WFH\NTP\_summary_LUNG_CELL_NEOPLASIA_24_8_2018.xlsx" out=ntp_lungneo dbms=excel replace;
run;

data d1 (keep=index dose n_ever_tumor num_examined);
   set ntp_lungneo;
run;

* add PSLT;
data d1a;
   input index dose n_ever_tumor num_examined;
   datalines;
   94	0	0	77
94	10	0	75
94	50	0	74
94	250	14	74
95	0	2	79
95	10	2	71
95	50	1	75
95	250	12	77
96	0	1	217
96	9.3	19	100
97	0	0	105
97	2.5	8	107
97	6.6	28	105
98	0	3	109
98	2.5	2	106
98	6.6	4	106
99	0	1	217
99	11.4	28	100
100	0	3	111
100	5.4	5	114
   ;
run;

data d1b;
	set d1 d1a;
run;

/* format: dose - respond (yes and no) - num respond */

data d2;
	set d1b;
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

	if index in (25, 30, 33, 57) then noael_dose=.;
run;

proc sort data=nl3 out=nl4 (keep=index noael_dose loael_dose) nodupkey;
   by index noael_dose loael_dose;
run;


proc sort data=ntp_lungneo out=final1(keep=index cas_number_y chemical_name species_common_name strain sex2 dose_unit) nodupkey;
   by index cas_number_y chemical_name species_common_name strain sex2 dose_unit;
run;

data final2;
	merge final1 nl4;
	by index;

	if dose_unit in ("", "MG/ M3", "MG") and index < 94 then delete;

run;

/* save summary */
proc export data=final2 outfile="\\cdc.gov\private\M606\vom8\MyLargeWorkspace Backup\NTPDatabase\_backup_16aug2018\WFH\NTP\lungneo_noael_loael.xlsx" dbms=excel;
run;
