/*///////////////////////////////////////////
///		Identify unique experiment
///			Material - Type (Species, Gender)
///
///			Create datasets, Control+Material+MaterialType
///
///		Set up quadratic plane regression for
///		Deposited Dose and Post Exposure
///			Can I mock up a potential change
///			to handle Inh - > CumExp & PostExp
///					IT/PA - > DepDose & PostExp
///
///		Parameters should be > 0
///			start unbounded
///			if negative, set to 0
///			compare to a constrained regression (NLIN?)
///
///		Miscellaneous TO DOs
///		--------------------
///			Re-evaluate Xia PoDs after deleting the 6 bad controls
///			Get cell counts for 100005, 100006 and bring in PMN counts
///			Re-fit GENMOD using binomial dist and logit link, check for overdispersion
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage "Y:\ENM Categories\DB\SAS Datasets";
libname storage "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";

/* copy the working version --- missing responses omitted, missing values filled in with indicators */
/* keep stuff relevant to QC and modeling */
data one;
   set storage.skeleton_pchem1_v2_impute (keep=study_key material material_type species strain gender route pe_d samppmnper exp_d dep_dose_amount2 administered_dose cum_expos sampcell samppmncount);
	
   if material_type="control" and administered_dose NE 0 then DELETE; /* 6 obs from Xia are "controls" with non-zero dose */

   if material_type in ("control6", "control7", "control8") then material_type = "control"; /* fix bug from program 11 */

   if samppmncount = . and sampcell ne . then samppmncount = sampcell * samppmnper;

run;

proc sort data=one out=uniqs01 (keep=study_key material material_type route) nodupkey;
	where material_type NE "control";
	by study_key material material_type route;
run;
data uniqs01;
	set uniqs01;
	
	loop_index=_N_;
run;

proc sql noprint;
	select max(loop_index)
	into :MAX_LOOP_INDEX
	from uniqs01;
quit;

%macro reg_data();
	/*//////////////////////////////////////////////////////////////////////////////
	///		Split up the master data into Test-Control sets by Material and Type
	///		Unique Experiments are in the UNIQS01 table
	///		This process eliminates paired controls
	/*/

	%do II=1 %to &MAX_LOOP_INDEX;

		data _NULL_;
			set uniqs01 (firstobs=&II. obs=&II.);

			call symput('CURRENT_STUDY', study_key);
			call symput('CURRENT_MAT', material);
			call symput('CURRENT_TYPE', material_type);
		run;

		data subset_&II.;
			set one;
			if study_key="&CURRENT_STUDY." and material="&CURRENT_MAT." and material_type in ("&CURRENT_TYPE.", "control");

			/* transformations, additional terms (interaction, quadratics) */
		run;

	%end; /* End of II loop */

%mend;

%reg_data();
		

proc sgplot data=subset_1;
	title "Dose vs. PMN Proportion";
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=subset_1;
	title "Post Exposure Days vs. PMN Proportion";
	scatter x=pe_d y=samppmnper;
run;
title " ";


data subset_1_2;
	set subset_1;
	int = dep_dose_amount2 * pe_d;
	t_dose = log10(dep_dose_amount2+1);
	t_ped = sqrt(pe_d);
	t_int = t_dose * t_ped;

	dose_sq = dep_dose_amount2 * dep_dose_amount2;
	ped_sq = pe_d * pe_d;
	int_sq = dose_sq * ped_sq;

	dose_cu = dose_sq * dep_dose_amount2;
	ped_cu = ped_sq * pe_d;
	int_cu = int_sq * int;

	t_dose_sq = t_dose * t_dose;
	t_ped_sq = t_ped * t_ped;
	t_int_sq = t_dose_sq * t_ped_sq;

	log_ped = log10(pe_d + 1);
	log_pmn = log10(samppmnper + 1);
	logit_pmn = log(samppmnper / (1-samppmnper));
	logit_pmn2 = log( (samppmnper+0.0053476) / (1 - (samppmnper+0.0053476)));

	observation = _N_;

run;
proc univariate data=subset_1_2;
	var logit_pmn2;
run;
proc univariate data=subset_1_2;
	var samppmnper;
run;
proc freq data=subset_1_2;
	table dep_dose_amount2 pe_d dep_dose_amount2*pe_d;
run;

proc sgplot data=subset_1_2;
	scatter x=int y=samppmnper;
run;
proc sgplot data=subset_1_2;
	title "Log10(Post Exposure Days) vs. PMN%";
	scatter x=log_ped y=samppmnper;
run;
proc sgplot data=subset_1_2;
	title "Log10(Post Exposure Days) vs. log10(PMN%)";
	scatter x=log_ped y=log_pmn;
run;
proc sgplot data=subset_1_2;
	title "Post Exposure Days vs. Logit(PMN%)";
	scatter x=pe_d y=logit_pmn;
run;
proc sgplot data=subset_1_2;
	title "Dose vs. Logit(PMN%)";
	scatter x=dep_dose_amount2 y=logit_pmn2;
run;

data subset_1_2;
	set subset_1_2;
	dose_jit = dep_dose_amount2 + (0.1*ranuni(0));
run;
proc g3d data=subset_1_2;
	Title "Dose and Post Exposure Days vs. PMN Proportion";
	scatter dose_jit * pe_d = samppmnper / shape="balloon" size=.5 rotate=250;
run;
proc g3d data=subset_1_2;
	Title "Dose and Post Exposure Days vs. Logit(PMN Proportion)";
	scatter dose_jit * pe_d = logit_pmn2 / shape="balloon" size=.5 rotate=250;
run;

ods graphics on;
proc reg data=subset_1_2;
	*model samppmnper = dep_dose_amount2 pe_d int / partial;
	*model samppmnper = t_dose t_ped t_int / partial lackfit; * lack p-value = <.0001; ;
	*model samppmnper = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq / partial lackfit; * lack p-value = 0.0133 ;
	*model samppmnper = dep_dose_amount2 pe_d int dose_sq ped_sq  / partial lackfit; * lack p-value = <.0001 ;
	*model samppmnper = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq dose_cu ped_cu int_cu / partial lackfit selection=B; * lack p-value =  ;
	model logit_pmn2 = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq / partial lackfit;
quit;







proc genmod data=subset_1_2;
	model samppmnper = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq / link=logit;
	/* int_sq not sig. */
run;
quit;
proc genmod data=subset_1_2;
	model samppmnper = dep_dose_amount2 pe_d int dose_sq ped_sq / link=logit;
	/* int, dose_sq, ped_sq not sig. --- int had highest p-value */
run;
quit;
proc genmod data=subset_1_2;
	model samppmnper = dep_dose_amount2 pe_d dose_sq ped_sq / link=logit;
	/* dose_sq,  not sig. */
run;
quit;
proc genmod data=subset_1_2;
	model samppmnper = dep_dose_amount2 pe_d ped_sq / link=logit obstats;
	output pred=preds
		   out=residuals;
run;
quit;


/*/////////////////////////////////////////////////////////////////
///		Before fitting overdisp, model-link-no outliers must be OK
///
/*/
proc genmod data=subset_1_2;
	model samppmncount / sampcell = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq / dist=binomial link=logit obstats;
	ods output obstats=a_obstats;
	/* int_sq not sig. */
run;
quit;
proc genmod data=subset_1_2;
	model samppmncount / sampcell = dep_dose_amount2 pe_d int dose_sq ped_sq / dist=binomial link=logit obstats;
	ods output obstats=a_obstats;
	/* deviances are huge --- lack of fit */
run;
quit;
proc sgplot data=a_obstats;
	scatter x=observation y=cookd; /* 3 influential points d>1 */
run;
proc sgplot data=a_obstats;
	scatter x=observation y=leverage; /*  */
run;
proc sgplot data=a_obstats;
	scatter x=pred y=streschi;
run;
data qc;
	set a_obstats;
	if cookd>.6;
run;
data qc;
	set subset_1_2;
	if observation in (58, 60, 66, 72);
run;

data subset_1_3;
	set subset_1_2;
	if observation in (58, 60, 66, 72) then delete;
run;
proc genmod data=subset_1_3;
	model samppmncount / sampcell = dep_dose_amount2 pe_d int dose_sq ped_sq / dist=binomial link=logit obstats;
	ods output obstats=b_obstats;
	/* smaller deviances, still huge */
run;
quit;
proc sgplot data=b_obstats;
	scatter x=observation y=cookd; /*  */
run;
proc sgplot data=b_obstats;
	scatter x=pred y=streschi;
run;
ods graphics on;
proc loess data=b_obstats;
	model streschi = pred;
run;
/* supports OK model? */


/*////////////////////////////////////////////////////
///		Fit for overdispersion
/*/
proc genmod data=subset_1_2;
	model samppmncount / sampcell = dep_dose_amount2 pe_d int dose_sq ped_sq int_sq / dist=binomial link=logit obstats scale=P;
	ods output obstats=c_obstats;
	/* int_sq not sig  */
run;
quit;
proc genmod data=subset_1_2;
	model samppmncount / sampcell = dep_dose_amount2 pe_d int dose_sq ped_sq / dist=binomial link=logit obstats scale=P;
	ods output obstats=c_obstats;
	/* int not sig  */
run;
quit;
proc genmod data=subset_1_2;
	model samppmncount / sampcell = dep_dose_amount2 pe_d dose_sq ped_sq / dist=binomial link=logit obstats scale=P;
	ods output obstats=c_obstats;
	/* scaled deviance is still huge BUT just fits! */
run;
quit;
data one;
	file print;
	x = cinv(.05, 109);
	put x; *85.903007731   ;

	y = cinv(0.95, 3);
	put y;
run;
proc loess data=c_obstats;
	model streschi = pred;
run;


data data3;
	set data3;
	residuals = logit_pmn2 - preds;
run;
proc sgplot data=data3;
	scatter x=preds y=residuals;
run;
proc sgplot data=data3;
	scatter x=dep_dose_amount2 y=samppmnper;
	scatter x=dep_dose_amount2 y=preds;
run;
proc g3d data=data3;
	scatter dep_dose_amount2 * pe_d = preds / shape="balloon" size=0.5;
run;


data subset_1_3;
	set subset_1;

	samppmnper2 = samppmnper + 0.0000001;
run;
proc transreg data=subset_1_3;
	model boxcox(samppmnper2) = identity(dep_dose_amount2);
run;
/* lambda = 0.25 */

data subset_1_3;
	set subset_1_3;

	t_samppmnper = (samppmnper**(0.25) - 1) / 0.25;
run;
proc reg data=subset_1_3;
	model t_samppmnper = dep_dose_amount2;
run;
proc glm data=subset_1_3 plots=diagnostics;
	class dep_dose_amount2;
	model t_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / hovtest=BF;
quit;












data two;
	set one;

	/* normalize predictors */
	norm_dose = dep_dose_amount2 / 169.96666667;
	norm_postexp = pe_d / 364;

	dose_sq = norm_dose * norm_dose;
	pe_d_sq = norm_postexp * norm_postexp;
	dose_pe_d_int = norm_dose * norm_postexp;
	dose_pe_d_int_sq = dose_pe_d_int * dose_pe_d_int;

	log10_samppmnper = log10(samppmnper+1);
run;


proc reg data=two outest=two_est;
	where study_key="100001" and material_type in ("NB1", "control");

	*model log10_samppmnper = norm_dose  norm_postexp  dose_pe_d_int dose_sq pe_d_sq dose_pe_d_int_sq;
	model samppmnper = norm_dose  norm_postexp  dose_pe_d_int dose_sq pe_d_sq dose_pe_d_int_sq;
run;
quit;


proc summary data=two nway;
	where study_key="100001" and material_type in ("NB1", "control");
	class dep_dose_amount2;
	var samppmnper;
	output out=two_dev (drop=_type_ _freq_) std()=sd;
run;
proc sgplot data=two;
	where study_key="100001" and material_type in ("NB1", "control");
	scatter x=dep_dose_amount2 y=samppmnper;
run;

data two_a;
	set two;
	if study_key="100001" and material_type in ("NB1", "control");
run;
proc sort data=two_a;
	by dep_dose_amount2;
run;
proc means data=three;
	var samppmnper; * 0.1460280 ;
run;
proc means data=two_a;
	where samppmnper>0;
	var samppmnper;
	* min = 0.0053476 ;
run;

data two_b;
	set two_a;

	samppmnper2 = samppmnper + 0.0053476; * add the minimumum non-zero response for the logit transform ;

	logit_samppmnper2 = log( samppmnper2 / (1 - samppmnper2) ); * map [0, 1) to the real line ;
run;


data three;
	merge two_a two_dev;
	by dep_dose_amount2;

	w_dep_dose_amount2 = dep_dose_amount2 / sd;
	w_samppmnper = samppmnper / sd;

	w2_samppmnper = samppmnper / 0.1460280;

	w3_samppmnper = 1 / sin( sqrt(samppmnper) ); *arcine-sqrt;
	w4_samppmnper = sqrt(samppmnper);

	*w_samppmnper = ;

run;

proc sgplot data=three;
	scatter x=dep_dose_amount2 y=w4_samppmnper;
run;

proc sgplot data=two_b;
	*scatter x=dep_dose_amount2 y=logit_samppmnper2;
	*histogram logit_samppmnper2;
	histogram samppmnper;
run;

proc reg data=three;
	model w3_samppmnper = dep_dose_amount2;
run;
quit;

proc reg data=two_b;
	model logit_samppmnper2 = dep_dose_amount2;
quit;






proc nlin data=two;
	where study_key="100001" and material_type in ("NB1", "control");
	parms b0=0 b1=0 b2=0 b3=0 b4=0 b5=0 b6=0;
	bounds b1 b4 >= 0;
	model samppmnper = b0 + b1*norm_dose  + b2*norm_postexp + b3*dose_pe_d_int + b4*dose_sq + b5*pe_d_sq + b6*dose_pe_d_int_sq;
run;
quit;


proc transreg data=three;
	model boxcox(samppmnper = dep_dose_amount2);
run;
