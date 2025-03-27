options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage "Y:\ENM Categories\DB\SAS Datasets";


proc corr data=storage.skeleton_pchem1_v2_impute out=corrs;
run;


/* read in PoD clustering, make some plots/IDs */
proc import datafile="Y:\ENM Categories\NOAEL_LOAEL_BMD_WITH_GROUPS_04NOV2015.csv" out=pods1 dbms=csv;
run;


/*   %PMN - NOAEL  */
proc sort data=pods1 out=pods1_pct_noael (keep=clust_pct_no_cut5 material material_type post_exposure_days) nodupkey;
	by clust_pct_no_cut5 material material_type post_exposure_days;
run;
proc summary data=pods1 nway;
	class clust_pct_no_cut5;
	var X__PMN___NOAEL;
	output out=summ_pct_noael (drop=_type_ _freq_) min()=min_noael max()=max_noael;
run;
data pods1_pct_noael_2;
	merge pods1_pct_noael summ_pct_noael;
	by clust_pct_no_cut5;
run;




/*   %PMN - LOAEL  */
proc sort data=pods1 out=pods1_pct_loael (keep=clust_pct_lo_cut5 material material_type post_exposure_days) nodupkey;
	by clust_pct_lo_cut5 material material_type post_exposure_days;
run;
proc summary data=pods1 nway;
	class clust_pct_lo_cut5;
	var X__PMN___LOAEL;
	output out=summ_pct_loael (drop=_type_ _freq_) min()=min_loael max()=max_loael;
run;
data pods1_pct_loael_2;
	merge pods1_pct_loael summ_pct_loael;
	by clust_pct_lo_cut5;
run;



/*   %PMN - BMD  */
proc sort data=pods1 out=pods1_pct_bmd (keep=clust_pct_bmd_cut5 material material_type post_exposure_days) nodupkey;
	by clust_pct_bmd_cut5 material material_type post_exposure_days;
run;
proc summary data=pods1 nway;
	class clust_pct_bmd_cut5;
	var X__PMN___BMD;
	output out=summ_pct_bmd (drop=_type_ _freq_) min()=min_bmd max()=max_bmd;
run;
data pods1_pct_bmd_2;
	merge pods1_pct_bmd summ_pct_bmd;
	by clust_pct_bmd_cut5;
run;



/*   Total PMN - NOAEL  */
proc sort data=pods1 out=pods1_count_noael (keep=clust_count_no_cut5 material material_type post_exposure_days) nodupkey;
	by clust_count_no_cut5 material material_type post_exposure_days;
run;
proc summary data=pods1 nway;
	class clust_count_no_cut5;
	var Total_PMN___NOAEL;
	output out=summ_count_noael (drop=_type_ _freq_) min()=min_noael max()=max_noael;
run;
data pods1_count_noael_2;
	merge pods1_count_noael summ_count_noael;
	by clust_count_no_cut5;
run;



/*   Total PMN - LOAEL  */
proc sort data=pods1 out=pods1_count_loael (keep=clust_count_lo_cut5 material material_type post_exposure_days) nodupkey;
	by clust_count_lo_cut5 material material_type post_exposure_days;
run;
proc summary data=pods1 nway;
	class clust_count_lo_cut5;
	var Total_PMN___LOAEL;
	output out=summ_count_loael (drop=_type_ _freq_) min()=min_loael max()=max_loael;
run;
data pods1_count_loael_2;
	merge pods1_count_loael summ_count_loael;
	by clust_count_lo_cut5;
run;




/* code in leaves using IF THEN */

/* random forest? */
