/*/
//		Create DAX files to re-compute BMD/BMDL in BMDS
///		BMR = 10%
//
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


data d1;
	set storage2.skeleton_pchem1_v5;
run;

/* 12 studies */
/*
Study Ref		Mat		Type			PeD		Key		Index
------------	-----	-----------		--		------	-----
Porter 2013		TiO2	NB2				1		100001	1
Porter 2013		TiO2	NB2				3		100001	2
ENPRA-NRCWE		MWCNT	Long			1		100008	3
ENPRA-NRCWE		MWCNT	Short			1		100011	4
Sager 2013		MWCNT	Bare			1		100004	5
Porter 2013		TiO2	NB1				1		100001	6
ENPRA-NRCWE		MWCNT	Long			1		100009	7
Porter 2013		TiO2	NB1				3		100001	8
ENPRA-NRCWE		MWCNT	Short			1		100010	9
Sager 2013		MWCNT	Carboxylated	1		100004	10
Bermudez 2004	TiO2	Ultrafine		0		100025	11
Bermudez 2002	TiO2	Fine			0		100024	12
*/

proc sort data=d1 out=d1_sort(keep=study_key studyref material material_type pe_d) nodupkey;
	by study_key studyref material material_type pe_d;
run;

data a1 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100001" and pe_d=1 and material_type in ("NB2", "control");
	index=1;
run;
data a2 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100001" and pe_d=3 and material_type in ("NB2", "control");
	index=2;
run;
data a3 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100008" and pe_d=1 and material_type in ("long", "control");
	index=3;
run;
data a4 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100011" and pe_d=1 and material_type in ("short", "control");
	index=4;
run;
data a5 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100004" and pe_d=1 and material_type in ("Bare", "control");
	index=5;
run;
data a6 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100001" and pe_d=1 and material_type in ("NB1", "control");
	index=6;
run;
data a7 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100009" and pe_d=1 and material_type in ("long", "control");
	index=7;
run;
data a8 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100001" and pe_d=3 and material_type in ("NB1", "control");
	index=8;
run;
data a9 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100010" and pe_d=1 and material_type in ("short", "control");
	index=9;
run;
data a10 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100004" and pe_d=1 and material_type in ("Carboxylated", "control");
	index=10;
run;
data a11 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100025" and pe_d=0 and material_type in ("Ultrafine", "control");
	index=11;
run;
data a12 (keep=study_key studyref material material_type pe_d samppmnper dep_dose_amount2 index);
	set d1;
	if study_key="100024" and pe_d=0 and material_type in ("Fine", "control");
	index=12;
run;


/* visual checks */
proc sgplot data=a1;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a2;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a3;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a4;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a5;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a6;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a7;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a8;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a9;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a10;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a11;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=a12;
	scatter x=dep_dose_amount2 y=samppmnper;
run;


data out1;
	set a1-a12;
	if samppmnper=. then delete;
run;

/* export to excel (tab = all)
		create tabs for each set of data 1 - 12
*/
proc export data=out1 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\Publication\BMDS BMR10\data.xlsx" dbms=excel;
run;
