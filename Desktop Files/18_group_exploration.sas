options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";

/* read in current BMDs --- corrected extrapolations */
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups_all_BMD_new.csv" 
            out=bmd1
			dbms=csv replace;
run;
data bmd2 (rename=(post_exposure_days=pe_d study_key2=study_key cut_clust_newbmd2=bmd_group X__PMN___BMD=BMD));
	set bmd1;

	study_key2=put(study_key, 6.);
	drop study_key;
run;

data db1;
	set storage2.skeleton_pchem1_v3;
run;



data group4_1;
	set db1;
	if study_key="100024" and pe_d=0;
run;
proc sgplot data=group4_1;
	scatter x=dep_dose_amount2 y=samppmnper;
run;


proc freq data=db1;
	table material_type;
	*where study_key="100004";
	where study_key="100012";
run;
data group3_1;
	/* 4, 12, 25 key
	   1, 1,  0  ped
       carboxylated, long, ultrafine */

	set db1;
	if (study_key="100004" and pe_d=1 and material_type in ("Carboxylated", "control")) or
	   (study_key="100012" and pe_d=1) or
	   (study_key="100025" and pe_d=0);
run;
proc sgplot data=group3_1;
	scatter x=dep_dose_amount2 y=samppmnper;
run;


