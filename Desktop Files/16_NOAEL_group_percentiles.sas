options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
*libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";


/*///////////////   PoDs --- 0 to 3 days ////////////////////*/
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups_noINH_NOAEL.csv" 
            out=pod1_noael_noinh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups_INH_NOAEL.csv" 
            out=pod1_noael_inh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_0_to_3_groups_all_NOAEL.csv" 
            out=pod1_noael_all
			dbms=csv replace;
run;

proc univariate data=pod1_noael_noinh;
	by group;
	var noael;
	ods output quantiles=pod1_noinh_quantiles;
run;
proc univariate data=pod1_noael_inh;
	by cut_clust_pod0_3;
	var X__PMN___NOAEL;
	ods output quantiles=pod1_inh_quantiles;
run;
proc univariate data=pod1_noael_all;
	by cut_clust_pod0_3;
	var X__PMN___NOAEL;
	ods output quantiles=pod1_all_quantiles;
run;

data pod1_noinh_quantiles;
	set pod1_noinh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod1_inh_quantiles;
	set pod1_inh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod1_all_quantiles;
	set pod1_all_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;

proc export data=pod1_noinh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_0_to_3_noinh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod1_inh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_0_to_3_inh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod1_all_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_0_to_3_all_percentiles.xlsx"
			dbms=excel
			replace;
run;


/*///////////////   PoDs --- 7 to 14 days ////////////////////*/
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_7_to_14_groups_noINH_NOAEL.csv" 
            out=pod2_noael_noinh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_7_to_14_groups_INH_NOAEL.csv" 
            out=pod2_noael_inh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_7_to_14_groups_all_NOAEL.csv" 
            out=pod2_noael_all
			dbms=csv replace;
run;

proc univariate data=pod2_noael_noinh;
	by cut_clust_pod7_14;
	var X__PMN___NOAEL;
	ods output quantiles=pod2_noinh_quantiles;
run;
proc univariate data=pod2_noael_inh;
	by cut_clust_pod7_14;
	var X__PMN___NOAEL;
	ods output quantiles=pod2_inh_quantiles;
run;
proc univariate data=pod2_noael_all;
	by cut_clust_pod7_14;
	var X__PMN___NOAEL;
	ods output quantiles=pod2_all_quantiles;
run;

data pod2_noinh_quantiles;
	set pod2_noinh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod2_inh_quantiles;
	set pod2_inh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod2_all_quantiles;
	set pod2_all_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;

proc export data=pod2_noinh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_7_to_14_noinh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod2_inh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_7_to_14_inh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod2_all_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_7_to_14_all_percentiles.xlsx"
			dbms=excel
			replace;
run;


/*///////////////   PoDs --- 28 to 60 days ////////////////////*/
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_28_to_60_groups_noINH_NOAEL.csv" 
            out=pod3_noael_noinh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_28_to_60_groups_INH_NOAEL.csv" 
            out=pod3_noael_inh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_28_to_60_groups_all_NOAEL.csv" 
            out=pod3_noael_all
			dbms=csv replace;
run;

proc univariate data=pod3_noael_noinh;
	by cut_clust_pod28_60;
	var X__PMN___NOAEL;
	ods output quantiles=pod3_noinh_quantiles;
run;
proc univariate data=pod3_noael_inh;
	by cut_clust_pod28_60;
	var X__PMN___NOAEL;
	ods output quantiles=pod3_inh_quantiles;
run;
proc univariate data=pod3_noael_all;
	by cut_clust_pod28_60;
	var X__PMN___NOAEL;
	ods output quantiles=pod3_all_quantiles;
run;

data pod3_noinh_quantiles;
	set pod3_noinh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod3_inh_quantiles;
	set pod3_inh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod3_all_quantiles;
	set pod3_all_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;

proc export data=pod3_noinh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_28_to_60_noinh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod3_inh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_28_to_60_inh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod3_all_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_28_to_60_all_percentiles.xlsx"
			dbms=excel
			replace;
run;


/*///////////////   PoDs --- 91 to 364 days ////////////////////*/
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_91_to_364_groups_noINH_NOAEL.csv" 
            out=pod4_noael_noinh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_91_to_364_groups_INH_NOAEL.csv" 
            out=pod4_noael_inh
			dbms=csv replace;
run;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\POD_91_to_364_groups_all_NOAEL.csv" 
            out=pod4_noael_all
			dbms=csv replace;
run;

proc univariate data=pod4_noael_noinh;
	by cut_clust_pod91_364;
	var X__PMN___NOAEL;
	ods output quantiles=pod4_noinh_quantiles;
run;
proc univariate data=pod4_noael_inh;
	by cut_clust_pod91_364;
	var X__PMN___NOAEL;
	ods output quantiles=pod4_inh_quantiles;
run;
proc univariate data=pod4_noael_all;
	by cut_clust_pod91_364;
	var X__PMN___NOAEL;
	ods output quantiles=pod4_all_quantiles;
run;

data pod4_noinh_quantiles;
	set pod4_noinh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod4_inh_quantiles;
	set pod4_inh_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;
data pod4_all_quantiles;
	set pod4_all_quantiles;
	if quantile not in ("95%", "50% Median", "5%") then delete;
run;

proc export data=pod4_noinh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_91_to_364_noinh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod4_inh_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_91_to_364_inh_percentiles.xlsx"
			dbms=excel
			replace;
run;
proc export data=pod4_all_quantiles
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_91_to_364_all_percentiles.xlsx"
			dbms=excel
			replace;
run;


/*/////////////////// Combine all quantile files into one ////////////////////*/
data all1;
	set pod1_noinh_quantiles (in=a) pod1_inh_quantiles (in=b rename=(cut_clust_pod0_3=Group)) pod1_all_quantiles (in=c rename=(cut_clust_pod0_3=Group))
		pod2_noinh_quantiles (in=d rename=(cut_clust_pod7_14=Group)) pod2_inh_quantiles (in=e rename=(cut_clust_pod7_14=Group)) pod2_all_quantiles (in=f rename=(cut_clust_pod7_14=Group))
		pod3_noinh_quantiles (in=g rename=(cut_clust_pod28_60=Group)) pod3_inh_quantiles (in=h rename=(cut_clust_pod28_60=Group)) pod3_all_quantiles (in=i rename=(cut_clust_pod28_60=Group))
		pod4_noinh_quantiles (in=j rename=(cut_clust_pod91_364=Group)) pod4_inh_quantiles (in=k rename=(cut_clust_pod91_364=Group)) pod4_all_quantiles (in=l rename=(cut_clust_pod91_364=Group));

	format strata $10.;

	if a then do;  strata="0 to 3";  type="No Inhalation";  end;
	if b then do;  strata="0 to 3";  type="Inhalation";  varname="NOAEL";  end;
	if c then do;  strata="0 to 3";  type="All Routes";  varname="NOAEL";  end;

	if d then do;  strata="7 to 14";  type="No Inhalation";  varname="NOAEL";  end;
	if e then do;  strata="7 to 14";  type="Inhalation";  varname="NOAEL";  end;
	if f then do;  strata="7 to 14";  type="All Routes";  varname="NOAEL";  end;

	if g then do;  strata="28 to 60";  type="No Inhalation";  varname="NOAEL";  end;
	if h then do;  strata="28 to 60";  type="Inhalation";  varname="NOAEL";  end;
	if i then do;  strata="28 to 60";  type="All Routes";  varname="NOAEL";  end;

	if j then do;  strata="91 to 364";  type="No Inhalation";  varname="NOAEL";  end;
	if k then do;  strata="91 to 364";  type="Inhalation";  varname="NOAEL";  end;
	if l then do;  strata="91 to 364";  type="All Routes";  varname="NOAEL";  end;

run;

proc export data=all1
			outfile="Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster\Percentiles\pod_all_percentiles_combined.xlsx"
			dbms=excel
			replace;
run;
