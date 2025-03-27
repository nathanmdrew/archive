/*////////////////////////////////////////////
///		Model Averaging
///			Properties of Model-Averaged BMDLs: A Study of Model Averaging in Dichotomous Response Risk Estimation
///			Wheeler, Bailer 2007
///			Risk Analysis
/*/


/*////////////////////////////////////
///		Run program 00_dichotomous_extrarisk (or added) first
///			Run the models desired, need the parameter estimates and AIC
///				Current version assumes all models except MS3
///				Takes models with adequate fit (out_all2.sas7bdat)
/*/


%macro modelaverage(datain=, maxiterations=, convergence=, bmr=, dataout=,
					weibull=, logistic=, loglogistic=, gamma=, linear=, probit=, logprobit=, ms2=, ms3=, quadratic=,
					pe_weibull=, pe_logistic=, pe_log_logistic=, pe_gamma=, pe_linear=, pe_probit=, pe_log_probit=, pe_ms2=, pe_ms3=, pe_quadratic=,
					all_results=);

/* initial parameters */
%let gamma_aict=0;
%let linear_aict=0;
%let quadratic_aict=0;
%let loglogistic_aict=0;
%let logistic_aict=0;
%let logprobit_aict=0;
%let ms2_aict=0;
%let ms3_aict=0;
%let probit_aict=0;
%let weibull_aict=0;



/* set up plot */
data out_subset (keep=model aic aic_t);
	set &ALL_RESULTS.;
	
	useweibull=&weibull.;
	uselogistic=&logistic.;
	useloglogistic=&loglogistic.;
	usegamma=&gamma.;
	uselinear=&linear.;
	useprobit=&probit.;
	uselogprobit=&logprobit.;
	usems2=&ms2.;
	usems3=&ms3.;
	usequadratic=&quadratic.;
	
	aic_t = 0;
	/*aic_t = exp( (-1/2)*aic );*/    /* transformed AIC for weighting */

	if (usegamma=1 AND model="GAMMA") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("gamma_aict", aic_t);
	end;
	if (uselinear=1 AND model="QUANTAL LINEAR") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("linear_aict", aic_t);
	end;
	if (usequadratic=1 AND model="QUANTAL QUADRATIC") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("quadratic_aict", aic_t);
	end;
	if (useloglogistic=1 AND model="LOG-LOGISTIC") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("loglogistic_aict", aic_t);
	end;
	if (uselogistic=1 AND model="LOGISTIC") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("logistic_aict", aic_t);
	end;
	if (uselogprobit=1 AND model="LOG PROBIT") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("logprobit_aict", aic_t);
	end;
	if (usems2=1 AND model="MULTISTAGE 2") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("ms2_aict", aic_t);
	end;
    if (usems3=1 AND model="MULTISTAGE 3") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("ms3_aict", aic_t);
	end;
	if (useprobit=1 AND model="PROBIT") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("probit_aict", aic_t);
	end;
	if (useweibull=1 AND model="WEIBULL") then do;
		aic_t = exp( (-1/2)*aic );
		call symput("weibull_aict", aic_t);
	end;
run;

/* sum up the transformed AICs to get the denominator of the weight function */
proc sql noprint;
	select sum(aic_t)
	into :sum_aic_t
	from out_subset;
quit;

%if &gamma=1 %then %do;
	data v (keep=parameter estimate);
		set &pe_gamma.;
		if parameter="_gamma" then call symput("gamma_g", estimate);
		if parameter="_alpha" then call symput("gamma_a", estimate);
		if parameter="_beta"  then call symput("gamma_b", estimate);
	run;
%end;
%else %if &gamma=0 %then %do;
	data _null_;
		call symput("gamma_g", 0);
		call symput("gamma_a", 0);
		call symput("gamma_b", 0);
	run;
%end;


%if &linear=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_linear.;
		if parameter="_gamma" then call symput("linear_g", estimate);
		if parameter="_bdose" then call symput("linear_b", estimate);
	run;
%end;
%else %if &linear=0 %then %do;
	data _null_;
		call symput("linear_g", 0);
		call symput("linear_b", 0);
	run;
%end;


%if &quadratic=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_quadratic.;
		if parameter="_gamma" then call symput("quadratic_g", estimate);
		if parameter="_bdose" then call symput("quadratic_b", estimate);
	run;
%end;
%else %if &quadratic=0 %then %do;
	data _null_;
		call symput("quadratic_g", 0);
		call symput("quadratic_b", 0);
	run;
%end;


%if &loglogistic=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_log_logistic.;
		if parameter="_gamma" then call symput("loglogistic_g", estimate);
		if parameter="_alpha" then call symput("loglogistic_a", estimate);
		if parameter="_bdose" then call symput("loglogistic_b", estimate);
	run;
%end;
%else %if &loglogistic=0 %then %do;
	data _null_;
		call symput("loglogistic_g", 0);
		call symput("loglogistic_a", 0);
		call symput("loglogistic_b", 0);
	run;
%end;


%if &logistic=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_logistic.;
		if parameter="_alpha" then call symput("logistic_a", estimate);
		if parameter="_bdose" then call symput("logistic_b", estimate);
	run;
%end;
%else %if &logistic=0 %then %do;
	data _null_;
		call symput("logistic_a", 0);
		call symput("logistic_b", 0);
	run;
%end;


%if &logprobit=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_log_probit.;
		if parameter="_gamma" then call symput("logprobit_g", estimate);
		if parameter="_alpha" then call symput("logprobit_a", estimate);
		if parameter="_beta" then call symput("logprobit_b", estimate);
	run;
%end;
%else %if &logprobit=0 %then %do;
	data _null_;
		call symput("logprobit_g", 0);
		call symput("logprobit_a", 0);
		call symput("logprobit_b", 0);
	run;
%end;


%if &ms2=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_ms2.;
		if parameter="_gamma" then call symput("ms2_g", estimate);
		if parameter="_bdose1" then call symput("ms2_b1", estimate);
		if parameter="_bdose2" then call symput("ms2_b2", estimate);
	run;
%end;
%else %if &ms2=0 %then %do;
	data _null_;
		call symput("ms2_g", 0);
		call symput("ms2_b1", 0);
		call symput("ms2_b2", 0);
	run;
%end;


%if &ms3=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_ms3.;
		if parameter="_gamma" then call symput("ms3_g", estimate);
		if parameter="_bdose1" then call symput("ms3_b1", estimate);
		if parameter="_bdose2" then call symput("ms3_b2", estimate);
		if parameter="_bdose3" then call symput("ms3_b3", estimate);
	run;
%end;
%else %if &ms3=0 %then %do;
	data _null_;
		call symput("ms3_g", 0);
		call symput("ms3_b1", 0);
		call symput("ms3_b2", 0);
		call symput("ms3_b3", 0);
	run;
%end;


%if &probit=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_probit.;
		if parameter="_alpha" then call symput("probit_a", estimate);
		if parameter="_beta" then call symput("probit_b", estimate);
	run;
%end;
%else %if &probit=0 %then %do;
	data _null_;
		call symput("probit_a", 0);
		call symput("probit_b", 0);
	run;
%end;


%if &weibull=1 %then %do;
	data _null_ (keep=parameter estimate);
		set &pe_weibull.;
		if parameter="_gamma" then call symput("weibull_g", estimate);
		if parameter="_alpha" then call symput("weibull_a", estimate);
		if parameter="_bdose" then call symput("weibull_b", estimate);
	run;
%end;
%else %if &weibull=0 %then %do;
	data _null_;
		call symput("weibull_g", 0);
		call symput("weibull_a", 0);
		call symput("weibull_b", 0);
	run;
%end;


proc sql noprint;
	select min(dose)
	into :mindose
	from &DATAIN.;

	select max(dose)
	into :maxdose
	from &DATAIN.;
quit;


/* use the bisection method to numerically find the BMD */
data _null_;

	useweibull=&weibull.;
	uselogistic=&logistic.;
	useloglogistic=&loglogistic.;
	usegamma=&gamma.;
	uselinear=&linear.;
	useprobit=&probit.;
	uselogprobit=&logprobit.;
	usems2=&ms2.;
	usems3=&ms3.;
	usequadratic=&quadratic.;

	pi_gamma=0; pi_linear=0; pi_quadratic=0; pi_logistic=0; pi_log_logistic=0; pi_log_probit=0; pi_ms2=0; pi_ms3=0; pi_probit=0; pi_weibull=0;
	pi_gamma_mid=0; pi_linear_mid=0; pi_quadratic_mid=0; pi_logistic_mid=0; pi_log_logistic_mid=0; pi_log_probit_mid=0; pi_ms2_mid=0; pi_ms3_mid=0; pi_probit_mid=0; pi_weibull_mid=0;

	dose_mid = (&maxdose. + &mindose.)/2;	

	/* compute the model average probability at DOSE=0 for BMR computation */
	/* compute the model average probability at the initial midpoint for bisection */
	if usegamma=1 then do;
		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*0, &gamma_a., 1);
		pi_gamma_mid = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose_mid, &gamma_a., 1);
	end;
	if uselinear=1 then do;
		pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*0)));
		pi_linear_mid = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose_mid)));
	end;
	if usequadratic=1 then do;
		pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (0**2))));
		pi_quadratic_mid = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose_mid**2))));
	end;
	if uselogistic=1 then do;
		pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*0));
		pi_logistic_mid = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose_mid));
	end;
	if useloglogistic=1 then do;
		pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */
		pi_log_logistic_mid = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose_mid)));
	end;
	if uselogprobit=1 then do;
		pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */
		pi_log_probit_mid = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose_mid));
	end;
	if usems2=1 then do;
		pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (0) + &ms2_b2. * 0**2)));
		pi_ms2_mid = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose_mid) + &ms2_b2. * dose_mid**2)));
	end;
	if usems3=1 then do;
		pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (0) + &ms3_b2. * 0**2 + &ms3_b3.*0**3)));
		pi_ms3_mid = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (dose_mid) + &ms3_b2. * dose_mid**2 + &ms3_b3.*dose_mid**3)));
	end;
	if useprobit=1 then do;
		pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*0);
		pi_probit_mid = CDF('NORMAL', &probit_a. + &probit_b.*dose_mid);
	end;
	if useweibull=1 then do;
		pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (0**&weibull_a.))));
		pi_weibull_mid = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose_mid**&weibull_a.))));
	end;

	pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + 
				   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + 
				   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);
	pi_zero = pi_modelavg1 / &sum_aic_t.;
	pi_bmd_extra = &BMR.*(1-pi_zero) + pi_zero; /* compute probability of response at the unknown BMD for EXTRA RISK */
	call symput ("pi_bmd_e", pi_bmd_extra);

	pi_modelavg_mid1 = usegamma*(pi_gamma_mid * &gamma_aict.) + uselinear*(pi_linear_mid * &linear_aict.) + usequadratic*(pi_quadratic_mid * &quadratic_aict.) + 
						   uselogistic*(pi_logistic_mid * &logistic_aict.) + useloglogistic*(pi_log_logistic_mid * &loglogistic_aict.) + uselogprobit*(pi_log_probit_mid * &logprobit_aict.) + 
						   usems2*(pi_ms2_mid * &ms2_aict.) + usems3*(pi_ms3_mid * &ms3_aict.) + useprobit*(pi_probit_mid * &probit_aict.) + useweibull*(pi_weibull_mid * &weibull_aict.);
	pi_modelavg_mid = pi_modelavg_mid1 / &sum_aic_t.;
	call symput("pi_middose_current", pi_modelavg_mid);
	call symput("middose_current", dose_mid);
run;


/* redefine interval based on where the pi(midpoint) lies relative to pi(bmd) */
data _null_;
	
	pi_mid = &pi_middose_current.;
	pi_bmd = &pi_bmd_e.;
		
	if pi_mid > pi_bmd then do;
		lowerbound_current = &mindose.;
		upperbound_current=&middose_current.;
		call symput("lowerbound_current", lowerbound_current);
		call symput("upperbound_current", upperbound_current);
	end;

	if pi_mid < pi_bmd then do;
		lowerbound_current = &middose_current.;
		upperbound_current=&maxdose.;
		call symput("lowerbound_current", lowerbound_current);
		call symput("upperbound_current", upperbound_current);
	end; 

	if pi_mid = pi_bmd then do;
		BMD_MA = &middose_current.;
		call symput("BMD_MA", BMD_MA);
	end;
run;

%let currentiteration=0;
%let diff=100;

%do %until ( (&diff. < &convergence.) OR (&currentiteration. = &maxiterations.) );

	%let currentiteration = %sysevalf(&currentiteration + 1);

	%PUT *********************************************;
	%PUT CURRENT BISECTION ITERATION ---> &currentiteration.;
	%PUT MAX               ITERATION ---> &maxiterations.;
	%PUT =============================================;
	%PUT CURRENT DIFFERENCE          ---> &diff.;
	%PUT CONVERGENCE                 ---> &convergence.;
	%PUT *********************************************;

	data _null_;
		dose_mid = (&upperbound_current. + &lowerbound_current.)/2;

		useweibull=&weibull.;
		uselogistic=&logistic.;
		useloglogistic=&loglogistic.;
		usegamma=&gamma.;
		uselinear=&linear.;
		useprobit=&probit.;
		uselogprobit=&logprobit.;
		usems2=&ms2.;
		usems3=&ms3.;
		usequadratic=&quadratic.;

		pi_gamma=0; pi_linear=0; pi_quadratic=0; pi_logistic=0; pi_log_logistic=0; pi_log_probit=0; pi_ms2=0; pi_ms3=0; pi_probit=0; pi_weibull=0;
		
		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose_mid, &gamma_a., 1);
		if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose_mid)));
		if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose_mid**2))));
		if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose_mid));
		if useloglogistic=1 then pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose_mid)));
		if uselogprobit=1 then pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose_mid));
		if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose_mid) + &ms2_b2. * dose_mid**2)));
		if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (dose_mid) + &ms3_b2. * dose_mid**2 + &ms3_b3.*dose_mid**3)));
		if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose_mid);
		if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose_mid**&weibull_a.))));

		pi_modelavg_mid1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + 
						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + 
						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);
		pi_modelavg_mid = pi_modelavg_mid1 / &sum_aic_t.;

		call symput("pi_middose_current", pi_modelavg_mid);
		call symput("middose_current", dose_mid);
	run;

	/* Create new bisection interval endpoints */
	data _null_;
	
		pi_mid = &pi_middose_current.;
		pi_bmd = &pi_bmd_e.;
		difference = abs(pi_mid - pi_bmd);
		call symput("diff", difference);
		
		if pi_mid > pi_bmd then do;
			lowerbound_current = &lowerbound_current.;
			upperbound_current=&middose_current.;
			call symput("lowerbound_current", lowerbound_current);
			call symput("upperbound_current", upperbound_current);
		end;
		if pi_mid < pi_bmd then do;
			lowerbound_current = &middose_current.;
			upperbound_current=&upperbound_current.;
			call symput("lowerbound_current", lowerbound_current);
			call symput("upperbound_current", upperbound_current);
		end; 
		if pi_mid = pi_bmd then do;
			BMD_MA = &middose_current.;
			call symput("BMD_MA", BMD_MA);
		end;
	run;

%end;

data &dataout.;
	format ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
	informat ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
	ChiSq = .;
	GoF_pvalue = .;
	AIC = .;
	BMR = &BMR.;
	BMD = &middose_current.;
	BMDL = .;
	Model = "MODEL AVERAGE";
	Risk = "EXTRA";
run;

%mend; /* end MODELAVERAGE */
