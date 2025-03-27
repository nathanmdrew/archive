options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */

libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


data s1 s2 s3 s4;
	set storage2.skeleton_pchem1_v5;

	if pe_d <= 3 then output s1; 		/* 974 */
	else if pe_d <= 14 then output s2; 	/* 273 */
	else if pe_d <= 60 then output s3; 	/* 475 */
	else output s4; 					/* 207 */
run;
/* --- total 1929 --- */

data s12;
	set s1;
	if ind_drop=0;	/* 844 */
run;
data s22;
	set s2;
	if ind_drop=0;	/* 207 */
run;
data s32;
	set s3;
	if ind_drop=0;	/* 355 */
run;
data s42;
	set s4;
	if ind_drop=0;	/* 151 */
run;
/* --- total 1557 --- */



/* update to Table 1 in response to reviewer */
/* 06jun2017 */
data db;
	set storage2.skeleton_pchem1_v5;
run;

proc sort data=db out=db_dose(keep=study_key studyref material material_type administered_dose dose_unit) nodupkey;
	by study_key studyref material material_type administered_dose dose_unit;
run;
