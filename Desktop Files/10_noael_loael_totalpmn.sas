options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Y:\ENM Categories\DB\SAS Datasets";
libname storage "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname pod1 "Y:\ENM Categories\DB\SAS Datasets\NOAELs_LOAELs_PMNpct_transformed";   
libname pod2 "Y:\ENM Categories\DB\SAS Datasets\NOAELs_LOAELs_PMNcount_transformed";



/*proc sort data=storage.skeleton1 nodupkey out=storage.keys2 (keep=study_key studyref material route);*/
/*	by study_key studyref material route;*/
/*run;*/

proc sort data=storage.skeleton1 nodupkey out=uniq_combos (keep=study_key pe_d material_type);
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

/* this dataset will be read into the Macro */
data skeleton;
	set storage.skeleton1;

	qc_index=_N_; /* used to ensure all observations are used in the following macro */

	if pmncount=. and samppmnper NE . and totcell NE . then pmncount=totcell*samppmnper;

	/* dist. of PMNCOUNT very right skewed.  Log transform is approx. Norm and seems to lead to Norm residuals*/
	/* dist. of SAMPPMNPER also right skewed.  Log transform isn't really Norm, but does seem to lead to Norm residuals */
	pmncount_transf = log10(pmncount);
	samppmnper_transf = log10(samppmnper); 
run;

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
		%if (&current_studykey. NE 100003) or (&current_studykey. NE 100005) or (&current_studykey. NE 100006) %then %do;
			data data_&ii.;
				set &dataname.;
				if study_key="&current_studykey." and pe_d=&current_postexp. and material_type in ("control", "&current_mat_type.");
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._Diagnostics.pdf";
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

		/* special directions if study key has odd control group namings */
		%if &current_studykey.= 100003 %then %do;
			data data_&ii.;
				set &dataname.;
				if study_key="&current_studykey." and pe_d=&current_postexp.;

				currentmat="&current_mat_type.";

				if pe_d=1 and currentmat="Ionized MeSo Silver" then do;
					if material_type not in ("Ionized MeSo Silver", "controlIonized1") then delete;
				end;
				if pe_d=1 and currentmat="Silver Colloid" then do;
					if material_type not in ("Silver Colloid", "controlColloid1") then delete;
				end;
				if pe_d=7 and currentmat="Ionized MeSo Silver" then do;
					if material_type not in ("Ionized MeSo Silver", "controlIonized2") then delete;
				end;
				if pe_d=7 and currentmat="Silver Colloid" then do;
					if material_type not in ("Silver Colloid", "controlColloid2") then delete;
				end;
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._Diagnostics.pdf";
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

		%if &current_studykey.=100005 %then %do;
			data data_&ii._1 data_&ii._2 data_&ii._3 data_&ii._4
				 data_&ii._5 data_&ii._6 data_&ii._7 data_&ii._8;
				set &dataname.;
				if study_key="&current_studykey." and pe_d=&current_postexp.;

				if exp_d=5 then output data_&ii._1;
				else if exp_d=10 then output data_&ii._2;
				else if exp_d=16 then output data_&ii._3;
				else if exp_d=20 then output data_&ii._4;
				else if exp_d=30 then output data_&ii._5;
				else if exp_d=41 then output data_&ii._6;
				else if exp_d=79 then output data_&ii._7;
				else if exp_d=116 then output data_&ii._8;
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._1_Diagnostics.pdf";
			proc glm data=data_&ii._1 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._1  CLDiffsInfo=Means2_&ii._1;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._1;
				set Means_&ii._1;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._1; by significance dep_dose_amount; run;
			data pod_&ii._1;
				set Means_&ii._1;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._1";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._2_Diagnostics.pdf";
			proc glm data=data_&ii._2 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._2  CLDiffsInfo=Means2_&ii._2;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._2;
				set Means_&ii._2;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._2; by significance dep_dose_amount; run;
			data pod_&ii._2;
				set Means_&ii._2;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._2";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._3_Diagnostics.pdf";
			proc glm data=data_&ii._3 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._3  CLDiffsInfo=Means2_&ii._3;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._3;
				set Means_&ii._3;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._3; by significance dep_dose_amount; run;
			data pod_&ii._3;
				set Means_&ii._3;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._3";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._4_Diagnostics.pdf";
			proc glm data=data_&ii._4 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._4  CLDiffsInfo=Means2_&ii._4;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._4;
				set Means_&ii._4;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._4; by significance dep_dose_amount; run;
			data pod_&ii._4;
				set Means_&ii._4;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._4";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._5_Diagnostics.pdf";
			proc glm data=data_&ii._5 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._5  CLDiffsInfo=Means2_&ii._5;
			quit;
			ods pds close;
			ods graphics off;

			data Means_&ii._5;
				set Means_&ii._5;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._5; by significance dep_dose_amount; run;
			data pod_&ii._5;
				set Means_&ii._5;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._5";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._6_Diagnostics.pdf";
			proc glm data=data_&ii._6 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._6  CLDiffsInfo=Means2_&ii._6;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._6;
				set Means_&ii._6;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._6; by significance dep_dose_amount; run;
			data pod_&ii._6;
				set Means_&ii._6;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._6";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._7_Diagnostics.pdf";
			proc glm data=data_&ii._7 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._7  CLDiffsInfo=Means2_&ii._7;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._7;
				set Means_&ii._7;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._7; by significance dep_dose_amount; run;
			data pod_&ii._7;
				set Means_&ii._7;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._7";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._8_Diagnostics.pdf";
			proc glm data=data_&ii._8 plots=diagnostics; 
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._8  CLDiffsInfo=Means2_&ii._8;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._8;
				set Means_&ii._8;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._8; by significance dep_dose_amount; run;
			data pod_&ii._8;
				set Means_&ii._8;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._8";
			run;
		%end;

		%if &current_studykey.=100006 %then %do;
			data data_&ii._1 data_&ii._2 data_&ii._3
				 data_&ii._4 data_&ii._5 data_&ii._6;
				set &dataname.;
				if study_key="&current_studykey.";

				if pe_d=0 and exp_d=20 then output data_&ii._1;
				else if pe_d=0 and exp_d=40 then output data_&ii._2; 
				else if pe_d=0 and exp_d=60 then output data_&ii._3;
				else if pe_d=36 and exp_d=20 then output data_&ii._4;
				else if pe_d=36 and exp_d=40 then output data_&ii._5;
				else if pe_d=36 and exp_d=60 then output data_&ii._6;  
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._1_Diagnostics.pdf";
			proc glm data=data_&ii._1 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._1  CLDiffsInfo=Means2_&ii._1;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._1;
				set Means_&ii._1;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._1; by significance dep_dose_amount; run;
			data pod_&ii._1;
				set Means_&ii._1;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._1";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._2_Diagnostics.pdf";
			proc glm data=data_&ii._2 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._2  CLDiffsInfo=Means2_&ii._2;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._2;
				set Means_&ii._2;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._2; by significance dep_dose_amount; run;
			data pod_&ii._2;
				set Means_&ii._2;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._2";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._3_Diagnostics.pdf";
			proc glm data=data_&ii._3 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._3  CLDiffsInfo=Means2_&ii._3;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._3;
				set Means_&ii._3;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._3; by significance dep_dose_amount; run;
			data pod_&ii._3;
				set Means_&ii._3;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._3";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._4_Diagnostics.pdf";
			proc glm data=data_&ii._4 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._4  CLDiffsInfo=Means2_&ii._4;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._4;
				set Means_&ii._4;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._4; by significance dep_dose_amount; run;
			data pod_&ii._4;
				set Means_&ii._4;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._4";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._5_Diagnostics.pdf";
			proc glm data=data_&ii._5 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._5  CLDiffsInfo=Means2_&ii._5;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._5;
				set Means_&ii._5;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._5; by significance dep_dose_amount; run;
			data pod_&ii._5;
				set Means_&ii._5;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._5";
			run;

			ods graphics on;
			ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\&OUTDIR.\Data_&ii._6_Diagnostics.pdf";
			proc glm data=data_&ii._6 plots=diagnostics;
			    class &dosevar.;
				model &responsevar. = &dosevar.;
				means &dosevar. / dunnett hovtest;
				ODS output CLDiffs=Means_&ii._6  CLDiffsInfo=Means2_&ii._6;
			quit;
			ods pdf close;
			ods graphics off;

			data Means_&ii._6;
				set Means_&ii._6;
				dep_dose_amount = scan(comparison, 1, '-')*1;
			run;
			proc sort data=Means_&ii._6; by significance dep_dose_amount; run;
			data pod_&ii._6;
				set Means_&ii._6;
				by significance;
				if first.significance and significance=1 then LOAEL=1;
				study_key="&current_studykey.";
				pe_d=&current_postexp.;
				material_type="&current_mat_type.";

				data_index="&ii._6";
			run;

		%end;

	%end; /* ends II loop */

	*ods exclude none; /* enable output */

	
data pod_all;
	set _null_;
	format data_index $ 4.;
run;
data pod_all (keep=study_key pe_d material_type dep_dose_amount significance loael data_index);
	set pod_all
		pod_1 (drop=comparison)	pod_2 (drop=comparison)	pod_3 (drop=comparison)	pod_4 (drop=comparison)	
		pod_5 (drop=comparison)	pod_6 (drop=comparison)	pod_7 (drop=comparison)	pod_8 (drop=comparison)	
		pod_9 (drop=comparison)	pod_10 (drop=comparison)	pod_11 (drop=comparison)	pod_12 (drop=comparison)	
		pod_13 (drop=comparison)	pod_14 (drop=comparison)	pod_15 (drop=comparison)	pod_16 (drop=comparison)	
		pod_17 (drop=comparison)	pod_18 (drop=comparison)	pod_19 (drop=comparison)	pod_20 (drop=comparison)	
		pod_21 (drop=comparison)	pod_22 (drop=comparison)	pod_23 (drop=comparison)	pod_24 (drop=comparison)	
		pod_25 (drop=comparison)	pod_26 (drop=comparison)	pod_27 (drop=comparison)	pod_28 (drop=comparison)	
		pod_29 (drop=comparison)	pod_30 (drop=comparison)	pod_31 (drop=comparison)	pod_32 (drop=comparison)	
		pod_33 (drop=comparison)	pod_34 (drop=comparison)	pod_35 (drop=comparison)	pod_36 (drop=comparison)	
		pod_37 (drop=comparison)	

		pod_38_1(drop=comparison) pod_38_2(drop=comparison) pod_38_3(drop=comparison) pod_38_4(drop=comparison) 
		pod_38_5(drop=comparison) pod_38_6(drop=comparison) pod_38_7(drop=comparison) pod_38_8(drop=comparison)
 
		pod_39_1(drop=comparison) pod_39_2(drop=comparison) pod_39_3(drop=comparison) pod_39_4(drop=comparison) 
		pod_39_5(drop=comparison) pod_39_6(drop=comparison)

		pod_40_1(drop=comparison) pod_40_2(drop=comparison) pod_40_3(drop=comparison) pod_40_4(drop=comparison)
		pod_40_5(drop=comparison) pod_40_6(drop=comparison) 

		pod_41 (drop=comparison)	pod_42 (drop=comparison)	pod_43 (drop=comparison)	pod_44 (drop=comparison)	
		pod_45 (drop=comparison)	pod_46 (drop=comparison)	pod_47 (drop=comparison)	pod_48 (drop=comparison)	
		pod_49 (drop=comparison)	pod_50 (drop=comparison)	pod_51 (drop=comparison)	pod_52 (drop=comparison)	
		pod_53 (drop=comparison)	pod_54 (drop=comparison)	pod_55 (drop=comparison)	pod_56 (drop=comparison)	
		pod_57 (drop=comparison)	pod_58 (drop=comparison)	pod_59 (drop=comparison)	pod_60 (drop=comparison)	
		pod_61 (drop=comparison)	pod_62 (drop=comparison)	pod_63 (drop=comparison)	pod_64 (drop=comparison)	
		pod_65 (drop=comparison)	pod_66 (drop=comparison)	pod_67 (drop=comparison)	pod_68 (drop=comparison)	
		pod_69 (drop=comparison)	pod_70 (drop=comparison)	pod_71 (drop=comparison)	pod_72 (drop=comparison)	
		pod_73 (drop=comparison)	pod_74 (drop=comparison);
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

proc sort data=storage.skeleton1 nodupkey out=uniq_keys (keep=study_key studyref material material_type);
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

proc datasets lib=work kill nolist memtype=data;
quit;

%mend; /* ends NOAEL_LOAEL() macro */

/* call macro */
%noael_loael(RESPONSEVAR=pmncount_transf, DATANAME=skeleton, DOSEVAR=dep_dose_amount2, OUTDIR=pmncount_transf_diagnostics, OUTWORK=pod2);
%noael_loael(RESPONSEVAR=samppmnper_transf, DATANAME=skeleton, DOSEVAR=dep_dose_amount2, OUTDIR=samppmnper_transf_diagnostics, OUTWORK=pod1);




/* combine the 2 NOAEL LOAEL files with BMD */
data nolo_pct1;
	set pod1.pod_all_5 (drop=data_index ind_qc);
	response="% PMN";
	*transformed="Yes";
	rename loael_dose=loael_pctpmn
		   noael_dose=noael_pctpmn;

run;
data nolo_count1;
	set pod2.pod_all_5 (drop=data_index ind_qc);
	response="Total PMN";
	*transformed="Yes";
	rename loael_dose=loael_countpmn
		   noael_dose=noael_countpmn;
run;
data bmd_pct1 ;*(rename=(study_key2=study_key));
	set storage2.bmd_final;
	response="% PMN";
	*transformed="No";

	*study_key2=put(study_key, 6.);

	rename bmd=bmd_pctpmn
		   bmdl=bmdl_pctpmn
		   post_exposure_days=pe_d;
	*drop study_key;
run;

proc sort data=nolo_pct1; by study_key material material_type pe_d; run;
proc sort data=nolo_count1; by study_key material material_type pe_d; run;
proc sort data=bmd_pct1; by study_key material material_type pe_d; run;

data pod_all1;
	merge nolo_pct1 (drop=response)
		  nolo_count1 (drop=response max_dose min_dose)
		  bmd_pct1 (keep=study_key material material_type pe_d bmd_pctpmn bmdl_pctpmn);
	by study_key material material_type pe_d;  

	if study_key="" then delete;

	index=_N_;
run;

data pod_all1;
	set pod_all1;

	if index=47 then delete;
run;

proc export data=pod_all1 outfile="Y:\ENM Categories\NOAEL_LOAEL_BMD_19OCT2015.xlsx" dbms=excel replace;
run;

proc sort data=pod_all1 out=pod_all1sort; by material; run;
proc rank data=pod_all1sort out=pod_all2;
	by material;
	var loael_pctpmn;
	ranks loael_pctpmn_ranks;
run;



data one;
	set pod_all1;
	keep study_key material material_type pe_d noael_pctpmn pod_type pod;
	pod_type="NOAEL";
	rename noael_pctpmn = pod;
run;
data two;
	set pod_all1;
	keep study_key material material_type pe_d loael_pctpmn pod_type pod;
	pod_type="LOAEL";
	rename loael_pctpmn = pod;
run;
data three;
	set pod_all1;
	keep study_key material material_type pe_d bmd_pctpmn pod_type pod;
	pod_type="BMD";
	rename bmd_pctpmn = pod;
run;
data four;
	set one two three;
run;

proc sgplot data=four;
	where pod >= 0;
	scatter x=pod y=pe_d / group=pod_type;
run;



proc sgplot data=four;
	where pod >= 0 AND pe_d <= 7;
	scatter x=pod y=pe_d / group=pod_type;
run;



proc sgplot data=four;
	where pod >= 0 and pod_type NE "NOAEL";
	scatter x=pod y=pe_d / group=pod_type;
run;



proc sgplot data=four;
	where pod >= 0 AND pe_d <= 7;
	scatter x=pod y=pe_d / group=pod_type;
run;
