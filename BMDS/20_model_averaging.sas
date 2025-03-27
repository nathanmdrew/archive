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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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
	data _temp_ (keep=parameter estimate);
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

/*////////////////////////   Model Average Plots ////////////////////////////////////*/
/*data modelavg1 (keep=dose pi_modelavg);*/
/**/
/*	useweibull=&weibull.;*/
/*	uselogistic=&logistic.;*/
/*	useloglogistic=&loglogistic.;*/
/*	usegamma=&gamma.;*/
/*	uselinear=&linear.;*/
/*	useprobit=&probit.;*/
/*	uselogprobit=&logprobit.;*/
/*	usems2=&ms2.;*/
/*	usems3=&ms3.;*/
/*	usequadratic=&quadratic.;*/
/**/
/*	pi_gamma=0; pi_linear=0; pi_quadratic=0; pi_logistic=0; pi_log_logistic=0; pi_log_probit=0; pi_ms2=0; pi_ms3=0; pi_probit=0; pi_weibull=0;*/
/**/
/*	do dose=&mindose. to &maxdose. by 0.01;				*/
/*	   if dose=0 then do;*/
/*	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);*/
/*			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));*/
/*			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose**2))));*/
/*			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));*/
/*			if useloglogistic=1 then pi_loglogistic = &loglogistic_g.; /* specify equal to background at dose=0 */*/
/*			if uselogprobit=1 then pi_logprobit = &logprobit_g.; /* specify equal to background at dose=0 */*/
/*			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));*/
/*			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp( -(&ms3_b1. * (dose) + &ms3_b2. * dose**2 + &ms3_b3.*dose**3)));*/
/*			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);*/
/*			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));*/
/**/
/*			pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + */
/*						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + */
/*						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg = pi_modelavg1 / &sum_aic_t.;*/
/*	   end;*/
/**/
/*	   if dose>0 then do;*/
/*	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);*/
/*			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));*/
/*			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose**2))));*/
/*			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));*/
/*			if useloglogistic=1 then pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose)));*/
/*			if uselogprobit=1 then pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose));*/
/*			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));*/
/*			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (dose) + &ms3_b2. * dose**2 + &ms3_b3.*dose**3)));*/
/*			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);*/
/*			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));*/
/**/
/*			pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + */
/*						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + */
/*						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg = pi_modelavg1 / &sum_aic_t.;*/
/*		end;*/
/**/
/*		output;*/
/**/
/*	end;*/
/**/
/*run;*/;

/*
data bigplot;
	set prediction_weibull2 (keep=dose obs_prop lowerlimit upperlimit)
		modelavg1 (rename=(dose=ma_dose))
		plot_gamma (keep=dose1 resp1 rename=(dose1=gammadose resp1=gammaresp))
		plot_linear (keep=dose1 resp1 rename=(dose1=lineardose resp1=linearresp))
		plot_quadratic (keep=dose1 resp1 rename=(dose1=quadraticdose resp1=quadraticresp))
		plot_logistic (keep=dose1 resp1 rename=(dose1=logisticdose resp1=logisticresp))
		plot_log_logistic (keep=dose1 resp1 rename=(dose1=loglogisticdose resp1=loglogisticresp))
		plot_log_probit (keep=dose1 resp1 rename=(dose1=logprobitdose resp1=logprobitresp))
		plot_ms2 (keep=dose1 resp1 rename=(dose1=ms2dose resp1=ms2resp))
		plot_ms3 (keep=dose1 resp1 rename=(dose1=ms3dose resp1=ms3resp))
		plot_probit (keep=dose1 resp1 rename=(dose1=probitdose resp1=probitresp))
		plot_weibull (keep=dose1 resp1 rename=(dose1=weibulldose resp1=weibullresp));
run;

proc sgplot data=bigplot;
	title "All Model Fits with the Model Average";
	yaxis min=0 max=1;
	scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); 
	series x=ma_dose y=pi_modelavg / CurveLabel="Model-Average";
	series x=gammadose y=gammaresp / CurveLabel="Gamma";
	series x=lineardose y=linearresp / CurveLabel="Quantal Linear";
	series x=quadraticdose y=quadraticresp / CurveLabel="Quantal Quadratic";
	series x=logisticdose y=logisticresp / CurveLabel="Logistic";
	series x=loglogisticdose y=loglogisticresp / CurveLabel="Log Logistic";
	series x=logprobitdose y=logprobitresp / CurveLabel="Log Probit";
	series x=ms2dose y=ms2resp / CurveLabel="Multistage 2";
	series x=ms3dose y=ms3resp / CurveLabel="Multistage 3";
	series x=probitdose y=probitresp / CurveLabel="Probit";
	series x=weibulldose y=weibullresp / CurveLabel="Weibull";
run;

proc sgplot data=bigplot;
	title "Comparison of Best Fit, Model Average, and Worst Fit";
	yaxis min=0 max=1;
	scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); 
	series x=ma_dose y=pi_modelavg / CurveLabel="Model-Average";
	*series x=gammadose y=gammaresp / CurveLabel="Gamma";
	series x=lineardose y=linearresp / CurveLabel="Quantal Linear";
	series x=quadraticdose y=quadraticresp / CurveLabel="Quantal Quadratic";
	*series x=logisticdose y=logisticresp / CurveLabel="Logistic";
	*series x=loglogisticdose y=loglogisticresp / CurveLabel="Log Logistic";
	*series x=logprobitdose y=logprobitresp / CurveLabel="Log Probit";
	*series x=ms2dose y=ms2resp / CurveLabel="Multistage 2";
	*series x=ms3dose y=ms3resp / CurveLabel="Multistage 3";
	*series x=probitdose y=probitresp / CurveLabel="Probit";
	*series x=weibulldose y=weibullresp / CurveLabel="Weibull";
run;
*/




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
		
		/* compute the model average probability at the current lowest dose */
/*		if &MINDOSE.=0 then do;*/
/*	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);*/
/*			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));*/
/*			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (&MINDOSE.**2))));*/
/*			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));*/
/*			if useloglogistic=1 then pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */*/
/*			if uselogprobit=1 then pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */*/
/*			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));*/
/*			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MINDOSE.) + &ms3_b2. * &MINDOSE.**2 + &ms3_b3.*&MINDOSE.**3))); */
/*			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);*/
/*			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));*/
/**/
/*			pi_modelavg_lower1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + */
/*						   		 uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + */
/*						   		 usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;*/
/*	   end;*/
/**/
/*	   if &MINDOSE.>0 then do;*/
/*	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);*/
/*			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));*/
/*			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (&MINDOSE.**2))));*/
/*			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));*/
/*			if useloglogistic=1 then pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MINDOSE.)));*/
/*			if uselogprobit=1 then pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MINDOSE.));*/
/*			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));*/
/*			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MINDOSE.) + &ms3_b2. * &MINDOSE.**2 + &ms3_b3.*&MINDOSE.**3)));*/
/*			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);*/
/*			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));*/
/**/
/*			pi_modelavg_lower1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + */
/*						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + */
/*						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;*/
/*		end;*/
/**/
/*		call symput("pi_lowerbound_current", pi_modelavg_lower);*/
/**/
/*		/* compute the model average probability at the current highest dose */*/
/*		if &MAXDOSE.>0 then do;*/
/*	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MAXDOSE., &gamma_a., 1);*/
/*			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MAXDOSE.)));*/
/*			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (&MAXDOSE.**2))));*/
/*			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MAXDOSE.));*/
/*			if useloglogistic=1 then pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MAXDOSE.)));*/
/*			if uselogprobit=1 then pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MAXDOSE.));*/
/*			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MAXDOSE.) + &ms2_b2. * &MAXDOSE.**2)));*/
/*			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MAXDOSE.) + &ms3_b2. * &MAXDOSE.**2 + &ms3_b3.*&MAXDOSE.**3))); */
/*			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MAXDOSE.);*/
/*			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MAXDOSE.**&weibull_a.))));*/
/**/
/*			pi_modelavg_upper1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + */
/*						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + */
/*						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg_upper = pi_modelavg_upper1 / &sum_aic_t.;*/
/*		end;*/
/**/
/*		call symput("pi_upperbound_current", pi_modelavg_upper);*/

		/* compute the model average probability at DOSE=0 for BMR computation */;
		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*0, &gamma_a., 1);
		if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*0)));
		if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (0**2))));
		if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*0));
		if useloglogistic=1 then pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */
		if uselogprobit=1 then pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */
		if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (0) + &ms2_b2. * 0**2)));
		if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (0) + &ms3_b2. * 0**2 + &ms3_b3.*0**3)));
		if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*0);
		if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (0**&weibull_a.))));

		pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + 
						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + 
						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);
		pi_zero = pi_modelavg1 / &sum_aic_t.;

		pi_bmd_extra = &BMR.*(1-pi_zero) + pi_zero; /* compute probability of response at the unknown BMD for EXTRA RISK */

		call symput ("pi_bmd_e", pi_bmd_extra);
	run;

	/* evaluate initial midpoint */
	data _null_;
			dose_mid = (&maxdose. + &mindose.)/2;

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

		data _tracking;
			iter = &currentiteration.;
			lower = &lowerbound_current.;
			mid = &middose_current.;
			upper = &upperbound_current.;
			pi_mid = &pi_middose_current.;
			pi_BMD = &pi_bmd_e.;
		run;

		%do %while ( %sysevalf( %sysfunc(ABS(&pi_bmd_e. - &pi_middose_current.)) > &convergence) OR (&currentiteration. < &maxiterations.));
		/*%do %while ( %sysevalf(&currentiteration. < &maxiterations.));*/

			%let currentiteration = %sysevalf(&currentiteration + 1);
			%PUT CURRENT BISECTION ITERATION ---> &currentiteration.;

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

			data _temp;
				iter = &currentiteration.;
				lower = &lowerbound_current.;
				mid = &middose_current.;
				upper = &upperbound_current.;
				pi_mid = &pi_middose_current.;
				pi_BMD = &pi_bmd_e.;
			run;

			data _tracking;
				set _tracking _temp;
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
