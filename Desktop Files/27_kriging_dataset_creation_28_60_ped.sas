/*/////////////////////////////////////////////////////////////////
///		Check if the 3 weird BMD cases even have a trend to model
///			Levene's test for homogeneity will be used
///			alpha = 0.05
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";

/* focus on first post exposure stratum for now */
data d1;
	set storage2.skeleton_pchem1_v5;
	if (pe_d >= 28) and (pe_d <= 60);
run;

data d1_ctrl;
	set d1;
	if dep_dose_amount2 = 0;
	/* different control animal schemes for Roberts2013, Porter1997, Porter1999 */
run;

data d1_expos;
	set d1;
	if dep_dose_amount2 > 0;
run;

* get combos for case identification ;
proc sort data=d1 out=d1_sort(keep=study_key material material_type pe_d) nodupkey;
	by study_key material material_type pe_d;
run;

* omit controls for now ;
data d1_sort2;
	set d1_sort;
	if material_type in ("control", "controlColloid1", "controlIonized1", "control4", 
						 "control5", "control6") then delete;
run;

* assign case numbers - # corresponds to rows in d1_sort2 ;
data temp;
	do case=1 to 22;
		output;
	end;
run;

data d1_sort3;
	merge d1_sort2 temp;
run;



* add controls to the cases ;
proc sort data=d1_expos;
	by study_key material material_type pe_d;
run;

data d2;
	merge d1_expos (in=aa keep=study_key material material_type pe_d studyref dep_dose_amount2 samppmnper exp_d) d1_sort3 (in=bb);
	by study_key material material_type pe_d;
	if aa;
run;

* this tells me how many control groups are needed for each case ;
* for most cases, i can reference study_key.  a few need exp_d ;
proc freq noprint data=d1_sort2;
	table study_key / missing list nocum out=key_freqs;
run;

data d1_ctrl2;
	set d1_ctrl;
	keep study_key material material_type pe_d studyref dep_dose_amount2 samppmnper exp_d;
run;

proc sort data=d1_ctrl2;
	by study_key exp_d pe_d;
run;



/*///////////////////////////////////////////////////////////
///		work in Excel
///			opened D1_SORT3 as a reference
///			opened D1_CTRL2 to make copies of control groups
///
///		quick notes
///			for the Porter Silica data, data not split by exposure duration
///				Porter1999 has 3 exposure lengths also at 15 mg/m3
///				since we're using deposited dose, all exposure lengths are combined
///				thus, all controls are combined into one mega control group
///			Sager2013 controls don't have BAL data, were used for Histopath
///
///			ENPRA Positive Control Crystalline Silica groups are included
/*/


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\28 - 60 Days Post Exposure\Control_Animals.xlsx" 
	out=ctrls1 dbms=excel; 
	sheet="By Case";
run;

data ctrls2;
	set ctrls1;

	key2 = put(study_key, 6.);
	drop study_key;
	rename key2=study_key;
run;


data d3;
	set d2 ctrls2;

	if case=. then delete; * drops the 3 non-control "control" Xia animals ;
run;

/*  --- QC Step

proc freq data=d3 noprint;
	table case / missing list nocum out=qc;
run;
data qc2;
	set d3;
	if case=.;
run;

	---		*/


proc sort data=d3;
	by case dep_dose_amount2;
run;

data storage2.kriging_28_60_postexp;
	set d3;
run;

proc export data=d3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\28 - 60 Days Post Exposure\NIOSHdosedata_postexp_28_60.xlsx" replace;
run;
