options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";

proc freq data=storage2.skeleton_pchem1_v2_impute noprint;
	table study_key * studyref * material * material_type / missing list nocum out=freqs1;
run;
data freqs1;
	set freqs1;
	if material_type="control" then delete;
run;

/*/////////////////////////////////////////////////////////////
///		Read in the Hierarchical Cluster results
///		Concatenate and QC
///		Export to R for Classification Trees
///
/*/

/*proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups.csv" */
/*            out=pod_0_3 dbms=csv;*/
/*run;*/
/*proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_7_to_14_groups.csv" */
/*            out=pod_7_14 dbms=csv;*/
/*run;*/
/*proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_28_to_60_groups.csv" */
/*            out=pod_28_60 dbms=csv;*/
/*run;*/
/*proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_91_to_364_groups.csv" */
/*            out=pod_91_364 dbms=csv;*/
/*run;*/



data WORK.POD_0_3    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups.csv' 
			delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Reference $20. ;
	informat Post_Exposure best32. ;
	informat Material $20. ;
	informat Material_Type $20. ;
	informat PoD best32. ;
	informat PoD_Type $5. ;
	informat Has_NOAEL_ $1. ;
	informat Has_BMDL_ $1. ;
	informat BMDL_EXPLANATION $50. ;
	informat Group best32. ;

	format Reference $20. ;
	format Post_Exposure best12. ;
	format Material $20. ;
	format Material_Type $20. ;
	format PoD best12. ;
	format PoD_Type $5. ;
	format Has_NOAEL_ $1. ;
	format Has_BMDL_ $1. ;
	format BMDL_EXPLANATION $50. ;
	format Group best12. ;

	input
            Reference $
            Post_Exposure
            Material $
            Material_Type $
            PoD
            PoD_Type $
            Has_NOAEL_ $
            Has_BMDL_ $
            BMDL_EXPLANATION $
            Group
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data WORK.POD_7_14    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_7_to_14_groups.csv' 
			delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Reference $20. ;
	informat Post_Exposure best32. ;
	informat Material $20. ;
	informat Material_Type $20. ;
	informat PoD best32. ;
	informat PoD_Type $5. ;
	informat Has_NOAEL_ $1. ;
	informat Has_BMDL_ $1. ;
	informat BMDL_EXPLANATION $50. ;
	informat Group best32. ;

	format Reference $20. ;
	format Post_Exposure best12. ;
	format Material $20. ;
	format Material_Type $20. ;
	format PoD best12. ;
	format PoD_Type $5. ;
	format Has_NOAEL_ $1. ;
	format Has_BMDL_ $1. ;
	format BMDL_EXPLANATION $50. ;
	format Group best12. ;

	input
            Reference $
            Post_Exposure
            Material $
            Material_Type $
            PoD
            PoD_Type $
            Has_NOAEL_ $
            Has_BMDL_ $
            BMDL_EXPLANATION $
            Group
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data WORK.POD_28_60    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_28_to_60_groups.csv' 
			delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Reference $20. ;
	informat Post_Exposure best32. ;
	informat Material $20. ;
	informat Material_Type $20. ;
	informat PoD best32. ;
	informat PoD_Type $5. ;
	informat Has_NOAEL_ $1. ;
	informat Has_BMDL_ $1. ;
	informat BMDL_EXPLANATION $50. ;
	informat Group best32. ;

	format Reference $20. ;
	format Post_Exposure best12. ;
	format Material $20. ;
	format Material_Type $20. ;
	format PoD best12. ;
	format PoD_Type $5. ;
	format Has_NOAEL_ $1. ;
	format Has_BMDL_ $1. ;
	format BMDL_EXPLANATION $50. ;
	format Group best12. ;

	input
            Reference $
            Post_Exposure
            Material $
            Material_Type $
            PoD
            PoD_Type $
            Has_NOAEL_ $
            Has_BMDL_ $
            BMDL_EXPLANATION $
            Group
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data WORK.POD_91_364    ;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_91_to_364_groups.csv' 
			delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat Reference $20. ;
	informat Post_Exposure best32. ;
	informat Material $20. ;
	informat Material_Type $20. ;
	informat PoD best32. ;
	informat PoD_Type $5. ;
	informat Has_NOAEL_ $1. ;
	informat Has_BMDL_ $1. ;
	informat BMDL_EXPLANATION $50. ;
	informat Group best32. ;

	format Reference $20. ;
	format Post_Exposure best12. ;
	format Material $20. ;
	format Material_Type $20. ;
	format PoD best12. ;
	format PoD_Type $5. ;
	format Has_NOAEL_ $1. ;
	format Has_BMDL_ $1. ;
	format BMDL_EXPLANATION $50. ;
	format Group best12. ;

	input
            Reference $
            Post_Exposure
            Material $
            Material_Type $
            PoD
            PoD_Type $
            Has_NOAEL_ $
            Has_BMDL_ $
            BMDL_EXPLANATION $
            Group
;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;


data all01;
	set pod_0_3 (in=aa) pod_7_14 (in=bb) pod_28_60 (in=cc) pod_91_364 (in=dd);

	if aa then stratum=1;
	else if bb then stratum=2;
	else if cc then stratum=3;
	else if dd then stratum=4;

	if reference="" then delete;

run;
/* all 89 obs are present */

proc sort data=storage2.skeleton_pchem1_v2_impute out=keys (keep=study_key studyref material material_type) nodupkey;
	by study_key studyref material material_type;
run;

proc sql;
	create table all02 as
	select aa.*
		   ,bb.study_key
	from all01 aa
	 left join keys bb
	 on aa.reference=bb.studyref AND aa.material=bb.material AND aa.material_type=bb.material_type;
quit;
