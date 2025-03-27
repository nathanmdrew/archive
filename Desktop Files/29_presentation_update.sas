/*/////////////////////////////
/*/
/*/		11/29/2016
/*/
/*/		Update stuff for presentation on Dec 8th
/*/


options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */

libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


data db1;
	set storage2.skeleton_pchem1_v5 (keep=pe_d ind_drop material studyref route dep_dose_amount2 samppmnper material_type study_key animal_key);
run;
/* 1929 */

proc freq data=db1;
	table pe_d;
run;

data db2;
	set db1;
	if ind_drop=0;
run;
/* 1557 */

data db3;
	set db2; *db1;

	if pe_d <= 3 then stratum=1;
	else if pe_d <= 14 then stratum = 2;
	else if pe_d <= 60 then stratum = 3;
	else stratum = 4;

	/* remove nonresponses, odd Xia animals --- leave duplicate controls for now */
	*if samppmnper=. then delete;
	*if study_key="100002" and ind_drop=1 then delete;
run;

proc freq data=db3;
	table stratum / missing list;
run;
/* where did my n=393 in Stratum1 come from?  */

data s1;
	set db3;
	if stratum=1;
run;

proc sort data=s1 nodupkey out=s1_sort(keep=study_key material material_type pe_d);
	by study_key material material_type pe_d;
run;


data s1_sort2;
	set s1_sort;
	if material_type in ("control", "controlColloid1", "controlIonized1", "control1", "control2", "control3", "control4",
						  "control5", "control6", "control7", "control8") then delete;
run;
/* 32 relationships */

data s1_sort2;
	set s1_sort2;
	case = _N_;
run;

proc sort data=s1; by study_key material material_type pe_d; run;

data s2;
	merge s1 s1_sort2;
	by study_key material material_type pe_d;
run;


data s3;
	set s1;

	if material_type="NS" then delete;
	if study_key in ("100002", "100003", "100005", "100006", "100007", "100019", "100020", "100021", "100023") then delete;
	if samppmnper=. then delete;
run;
/* 383, not 393?*/









data s3;
	set db3;
	if stratum=3;
run;

proc sort data=s3 nodupkey out=s3_sort(keep=study_key material material_type pe_d);
	by study_key material material_type pe_d;
run;


data s3_sort2;
	set s3_sort;
	if material_type in ("control", "control4", "control5", "control6") then delete;
run;
/* 22 relationships */
/* - 3 for the ENPRA positive control Silica
		19 */
/* - 2 for Sager, no data
		17 */
