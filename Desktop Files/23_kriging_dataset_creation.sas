/*//////////////////////////////////////////////////
///		Recreate the data set fed into Kriging code
///			Properly ID cases - include controls
///
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";

/* focus on first post exposure stratum for now */
data d1;
	set storage2.skeleton_pchem1_v5;
	if pe_d <= 3;
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
	if material_type in ("control", "controlColloid1", "controlIonized1", "control1", "control2", "control3", "control4", 
						 "control5", "control6", "control7", "control8") then delete;
run;

* assign case numbers ;
data temp;
	do case=1 to 32;
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
///				Porter1997 has 8 different exposure lengths at 15 mg/m3
///				Porter1999 has 3 exposure lengths also at 15 mg/m3
///				since we're using deposited dose, all exposure lengths are combined
///				thus, all controls are combined into one mega control group
///			Roberts2013 controls match the exposed material, as in the paper
///				some controls are for the Colloid group, some for Ionized --- not all combined into 1
///			Sager2013 controls match the exposed material, as in the paper
///				some controls are for the Bare group, some for Carboxylated --- not all combined into 1
/*/

proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\Data Correction\control_case_data.xlsx" 
	out=ctrls1 dbms=excel; 
	sheet="ctrl_cases";
run;

data ctrls2;
	set ctrls1;

	key2 = put(study_key, 6.);
	drop study_key;
	rename key2=study_key;
run;

data d3;
	set d2 ctrls2;

	if case=. then delete; * drops the non-control "control" Xia animal ;
run;

proc sort data=d3;
	by case dep_dose_amount2;
run;

data storage2.kriging_0_3_postexp;
	set d3;
run;

proc export data=d3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\Data Correction\NIOSHdosedata_postexp_0_3.xlsx" replace;
run;

/* v2 file is created manually, where columns are rearranged to match the format from Feng/Ying */



proc summary data=d3 nway;
	class case;
	var dep_dose_amount2;
	output out=doserange (drop=_type_ _freq_) min=min_dose max=max_dose;
run;

proc summary data=d3 nway;
	class case dep_dose_amount2;
	var samppmnper;
	output out=resprange (drop=_type_ _freq_) min=min_resp mean=avg_resp max=max_resp;
run;
