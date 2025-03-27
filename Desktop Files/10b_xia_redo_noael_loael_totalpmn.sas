options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


/*  
    Recompute NOAELs, LOAELs for Xia after throwing out "controls" with non-zero doses
    See if any change occurs
*/
proc freq data=storage2.skeleton1;
	table study_key;
run;
* 178 obs for Xia ;

data skeleton qc_badobs;
	set storage2.skeleton1;
	if study_key="100002";

	qc_index=_N_; /* used to ensure all observations are used in the following macro */

	if pmncount=. and samppmnper NE . and totcell NE . then pmncount=totcell*samppmnper;

	/* dist. of PMNCOUNT very right skewed.  Log transform is approx. Norm and seems to lead to Norm residuals*/
	/* dist. of SAMPPMNPER also right skewed.  Log transform isn't really Norm, but does seem to lead to Norm residuals */
	pmncount_transf = log10(pmncount);
	samppmnper_transf = log10(samppmnper); 

	if material_type="control" and dep_dose_amount2 > 0 then do;
		output qc_badobs;
		delete;
	end;
	else output skeleton;

run;
* 172 in skeleton, 6 in QC = 178 total ;

proc univariate data=skeleton;
	histogram samppmnper_transf;
run;

proc sort data=skeleton nodupkey out=uniq_combos (keep=study_key pe_d material_type);
	by study_key pe_d material_type;
run;

data uniq_combos2;
	set uniq_combos;
	by study_key;

	if material_type in ("control", "control1", "control2", "control3", "control4", 
						 "control5", "control6", "control7", "control8", "controlIonized1", "controlIonized2",
						 "controlColloid1", "controlColloid2") then delete;
run;
data uniq_combos2;
	set uniq_combos2;
	index=_N_;
run;



/* Conduct Dunnett's Test */
libname pod1 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets\NOAELs_LOAELs_xiav2_PMNpct_transformed";   
libname pod2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets\NOAELs_LOAELs_xiav2_PMNcount_transformed";

%macro noael_loael(RESPONSEVAR=, DATANAME=, DOSEVAR=, OUTDIR=, OUTWORK=);

	/*///////////////////////////
	///  Macro Input
	///		RESPONSEVAR: The response variable being modeled by dose in Proc GLM
	///		DATANAME   : The data set containing the dose-response info
	///					 This macro currently is built for the SKELETON dataset above (handling odd cases)
	///		DOSEVAR    : The dose variable of interest
	///		OUTDIR	   : Specify the file location where GLM output will be saved in PDF form
	///	 	OUTWORK    : Specify the location to copy all of the WORK. datatables; must have a LIBNAME
	/*/

	*ods exclude all; /* suppress output */

	/* get the number of experiments for the following loop */
	proc sql noprint;
		select max(index)
		into :combos
		from uniq_combos2;
	quit;

	%do ii=1 %to &combos.;

		/* get current study, post exposure, material type variables */
		data _NULL_;
			set uniq_combos2 (firstobs=&ii. obs=&ii.);

			call symput('current_studykey', study_key);
			call symput('current_postexp', pe_d);
			call symput('current_mat_type', material_type);
		run;

		/* check macro vars */
		%put ************************************************;
		%put **  Current Study Key:          &current_studykey.;
		%put **  Current Post Exposure Days: &current_postexp.;
		%put **  Current Material Type:      &current_mat_type.;
		%put ************************************************;


		/* subset database for the non-special keys with odd Control Group namings */
		
			data data_&ii.;
				set &dataname.;
				if study_key="&current_studykey." and pe_d=&current_postexp. and material_type in ("control", "&current_mat_type.");
			run;

			ods graphics on;
			ods pdf file="Z:\MyLargeWorkspace Backup\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._Diagnostics.pdf";
			proc glm data=data_&ii. plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii.  CLDiffsInfo=Means2_&ii.;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii.;
				set Means_&ii.;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;

			proc sort data=Means_&ii.; by significance dep_dose_amount; run;

			data pod_&ii.;
				set Means_&ii.;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii.";
			run;

	%end;

	
data pod_all;
	set _null_;
	format data_index $ 4.;
run;
data pod_all (keep=study_key pe_d material_type dep_dose_amount significance loael data_index);
	set pod_all
		pod_1 (drop=comparison)	pod_2 (drop=comparison)	pod_3 (drop=comparison)	pod_4 (drop=comparison)	
		pod_5 (drop=comparison)	pod_6 (drop=comparison)	pod_7 (drop=comparison)	pod_8 (drop=comparison)	
		pod_9 (drop=comparison)	pod_10 (drop=comparison)	pod_11 (drop=comparison)	pod_12 (drop=comparison);
run;
			
/* get NOAELs from doses less than the indicated LOAELs */
/* data_index is used primarily to discern between doses in the "odd" groups --- 100003 100005 100006 */
data loaels (keep=study_key pe_d material_type loael_dose data_index);
	set pod_all;
	if loael=1;
	loael_dose=dep_dose_amount;
run;

data pod_all2;
	merge pod_all
		  loaels;
	by study_key pe_d material_type data_index;

	/* if there is a loael, indicate possible noaels */
	if dep_dose_amount < loael_dose then possible_noael=1;
	/* if there is no loael, then everything is a possible noael */
	if loael_dose=. then possible_noael=1;
run;

/* noael = max(possible noaels) */
proc summary data=pod_all2 nway;
	by study_key pe_d material_type data_index;
	var dep_dose_amount;
	where possible_noael=1;
	output out=noaels (drop=_type_ _freq_) max()=noael_dose;
run;

data pod_all_3;
	merge loaels noaels;
	by study_key pe_d material_type data_index;
run;

proc summary data=pod_all nway;
	class study_key pe_d material_type data_index;
	var dep_dose_amount;
	output out=pod_all_doses (drop=_type_ _freq_) min()=min_dose max()=max_dose;
run;

data pod_all_4;
	merge pod_all_3 pod_all_doses;
	by study_key pe_d material_type data_index;
	
	if (noael_dose > loael_dose) and (loael_dose NE .)then ind_QC=1;

run;

proc sort data=storage2.skeleton1 nodupkey out=uniq_keys (keep=study_key studyref material material_type);
	by study_key material_type studyref material;
run;



/* FIXED the Key Merge*/
proc sort data=pod_all_4;
	by study_key material_type;
run;
data pod_all_5;
	merge pod_all_4 (in=aa)
		  uniq_keys (in=bb)
		  /*storage.keys (keep=study_key studyref chemical rename=(chemical=Material))*/
		  ;
	by study_key material_type;
	if aa;
	/* contains duplicates for study 100006 */
run;
/*//////////////
///	exported to excel, manually moved/deleted columns around, deleted 100006 duplicates manually
///	saved as "NOAELs LOAELs 11sep2015.xlsx"
/*/

	proc datasets library=work;
		copy out=&OUTWORK.;
	quit;

/*	proc datasets lib=work kill nolist memtype=data;*/
/*	quit;*/

%mend;

%noael_loael(RESPONSEVAR=samppmnper_transf, DATANAME=skeleton, DOSEVAR=dep_dose_amount2, OUTDIR=xiav2_samppmnper_transf_diagnostics, OUTWORK=pod1);
%noael_loael(RESPONSEVAR=pmncount_transf, DATANAME=skeleton, DOSEVAR=dep_dose_amount2, OUTDIR=xiav2_pmncount_transf_diagnostics, OUTWORK=pod2);


/* Conclusions
   -----------

   PMN Proportion NOAELs and LOAELs are unchanged
		Log10 transform does not always solve nonconstant var
			Data5 p-value  = 0.0012 (0.0532 with B-F)
			Data7 p-value  = 0.0136 (0.0944 with B-F)
			Data8 p-value  = 0.0272
			Data9 p-value  = 0.0300
			Data11 p-value = <0.0001
			Data12 p-value = 0.0266

			Chose Levene's first because dist(samppmnper_transf) ~ symmetric/bell shaped
				changing to B-F may be "cheating"
			Try logit transform

*/


			ods graphics on;
			proc glm data=data_5 plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest=bf;
				*ODS output CLDiffs=Means_&ii.  CLDiffsInfo=Means2_&ii.;
			quit;
			ods graphics off;

			ods graphics on;
			proc glm data=data_7 plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest=bf;
				*ODS output CLDiffs=Means_&ii.  CLDiffsInfo=Means2_&ii.;
			quit;
			ods graphics off;

			data skeleton;
				set skeleton;
				logit_samppmnper = log(samppmnper / (1-samppmnper));
			run;
			proc univariate data=skeleton; histogram logit_samppmnper; run; /* dist bimodal... kind of odd */

			data data_5_2;
				set data_5;
				logit_samppmnper = log(samppmnper / (1-samppmnper));
			run;
			ods graphics on;
			proc glm data=data_5_2 plots=diagnostics;
			    class dep_dose_amount2;
				model logit_samppmnper = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				*ODS output CLDiffs=Means_&ii.  CLDiffsInfo=Means2_&ii.;
			quit;
			ods graphics off;
			/* same HoV p-value as log10 transform */
			proc glm data=data_5_2 plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				*ODS output CLDiffs=Means_&ii.  CLDiffsInfo=Means2_&ii.;
			quit;
			ods graphics off;
			/* actually a better (0.0013) p-value with untransformed response! */

			


/* try weighted least squares */
proc sgplot data=data_5;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc reg data=data_5;
	model samppmnper = dep_dose_amount2;
	output out=data_5_out r=resid;
run;
data data_5_out;
	set data_5_out;

	abs_resid = abs(resid);
	sq_resid = resid**2;
run;
proc sgplot data=data_5_out;
	Title "Dose vs. Residuals";
	Title2 "Samppmnper = Deposited Dose";
	scatter x=dep_dose_amount2 y=resid;
run;
proc sgplot data=data_5_out;
	Title "Dose vs. Absolute Residuals";
	Title2 "Samppmnper = Deposited Dose";
	scatter x=dep_dose_amount2 y=abs_resid;
run;
proc sgplot data=data_5_out;
	Title "Dose vs. Squared Residuals";
	Title2 "Samppmnper = Deposited Dose";
	scatter x=dep_dose_amount2 y=sq_resid;
run;

/* looks like Absolute Resids are linearly related to Dose */

proc reg data=data_5_out;
	model abs_resid = dep_dose_amount2;
	output out=data_5_out2 p=est_sd;
run;
data data_5_out2;
	set data_5_out2;
	weight = 1/(est_sd**2);
run;
proc glm data=data_5_out2 plots=diagnostics;
	class dep_dose_amount2;
	model samppmnper = dep_dose_amount2;
	weight weight;
	means dep_dose_amount2 / hovtest dunnett;
run;
quit;
