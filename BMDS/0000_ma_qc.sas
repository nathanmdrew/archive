/*////////////////////////////////////////////
///		
/*/


options nocenter nonumber nodate ls=80 mprint symbolgen formdlim="*";


%macro modelaverage();


data out_subset (keep=model aic aic_t);
	set out_all2;

	aic_t = exp( (-1/2)*aic ); /* transformed AIC for weighting */

	if model="GAMMA" then call symput("gamma_aict", aic_t);
	if model="QUANTAL LINEAR" then call symput("linear_aict", aic_t);
	if model="QUANTAL QUADRATIC" then delete;/*///////////////////////*/
	if model="LOG-LOGISTIC" then call symput("loglogistic_aict", aic_t);
	if model="LOGISTIC" then call symput("logistic_aict", aic_t);
	if model="LOG PROBIT" then call symput("logprobit_aict", aic_t);
	if model="MULTISTAGE 2" then call symput("ms2_aict", aic_t);
    if model="MULTISTAGE 3" then delete; /*///////////////////////*/
	if model="PROBIT" then call symput("probit_aict", aic_t);
	if model="WEIBULL" then call symput("weibull_aict", aic_t);
run;

/* sum up the transformed AICs to get the denominator of the weight function */
proc sql noprint;
	select sum(aic_t)
	into :sum_aic_t
	from out_subset;
quit;

data pe_gamma2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_gamma;
	model = "GAMMA";
run;
data pe_linear2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_linear;
	model = "QUANTAL LINEAR";
run;
/*data pe_quadratic2 (keep=model parameter estimate);*/
/*	format model $17.;*/
/*	informat model $17.;*/
/*	set pe_quadratic;*/
/*	model = "QUANTAL QUADRATIC";*/
/*run;*/
data pe_log_logistic2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_log_logistic;
	model = "LOG-LOGISTIC";
run;
data pe_logistic2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_logistic;
	model = "LOGISTIC";
run;
data pe_log_probit2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_log_probit;
	model = "LOG PROBIT";
run;
data pe_ms2_2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_ms2;
	model = "MULTISTAGE 2";
run;
/*
data pe_ms3_2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_ms3;
	model = "MULTISTAGE 3";
run;
*/
data pe_probit2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_probit;
	model = "PROBIT";
run;
data pe_weibull2 (keep=model parameter estimate);
	format model $17.;
	informat model $17.;
	set pe_weibull;
	model = "WEIBULL";
run;

data pe_all;
	set pe_gamma2 pe_linear2 pe_quadratic2 pe_log_logistic2 pe_logistic2 pe_log_probit2 pe_ms2_2 pe_probit2 pe_weibull2;

	if model="GAMMA" then do;
	   if parameter="_gamma" then call symput("gamma_g", estimate);
	   if parameter="_alpha" then call symput("gamma_a", estimate);
	   if parameter="_beta"  then call symput("gamma_b", estimate);
	end;
	else if model="QUANTAL LINEAR" then do;
		if parameter="_gamma" then call symput("linear_g", estimate);
		if parameter="_bdose" then call symput("linear_b", estimate);
	end;
/*	else if model="QUANTAL QUADRATIC" then do;*/
/*		if parameter="_gamma" then call symput("quadratic_g", estimate);*/
/*		if parameter="_bdose" then call symput("quadratic_b", estimate);*/
/*	end;*/
	else if model="LOG-LOGISTIC" then do;
		if parameter="_gamma" then call symput("loglogistic_g", estimate);
		if parameter="_alpha" then call symput("loglogistic_a", estimate);
		if parameter="_bdose" then call symput("loglogistic_b", estimate);
	end;
	else if model="LOGISTIC" then do;
		if parameter="_alpha" then call symput("logistic_a", estimate);
		if parameter="_bdose" then call symput("logistic_b", estimate);
	end;
	else if model="LOG PROBIT" then do;
		if parameter="_gamma" then call symput("logprobit_g", estimate);
		if parameter="_alpha" then call symput("logprobit_a", estimate);
		if parameter="_beta" then call symput("logprobit_b", estimate);
	end;
	else if model="MULTISTAGE 2" then do;
		if parameter="_gamma" then call symput("ms2_g", estimate);
		if parameter="_bdose1" then call symput("ms2_b1", estimate);
		if parameter="_bdose2" then call symput("ms2_b2", estimate);
	end;
	/*
	else if model="MULTISTAGE 3" then do;
		if parameter="_gamma" then call symput("ms3_g", estimate);
		if parameter="_bdose1" then call symput("ms3_b1", estimate);
		if parameter="_bdose2" then call symput("ms3_b2", estimate);
		if parameter="_bdose3" then call symput("ms3_b3", estimate);
	end;
	*/
	else if model="PROBIT" then do;
		if parameter="_alpha" then call symput("probit_a", estimate);
		if parameter="_beta" then call symput("probit_b", estimate);
	end;
	else if model="WEIBULL" then do;
		if parameter="_gamma" then call symput("weibull_g", estimate);
		if parameter="_alpha" then call symput("weibull_a", estimate);
		if parameter="_bdose" then call symput("weibull_b", estimate);
	end;

run;



data modelavg1 (keep=dose pi_modelavg);
	do dose=0 to 4 by 0.01;				/* !!!!!!!!!!!!!   AUTO SELECT MIN AND MAX DOSE !!!!!!!!!!!!!!!!!!!!!!! */
	   if dose=0 then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));
			pi_loglogistic = &loglogistic_g.; /* specify equal to background at dose=0 */
			pi_logprobit = &logprobit_g.; /* specify equal to background at dose=0 */
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));

			pi_modelavg1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
			pi_modelavg = pi_modelavg1 / &sum_aic_t.;
	   end;
	   if dose>0 then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));
			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose)));
			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose));
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));

			pi_modelavg1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.)  + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);

			pi_modelavg = pi_modelavg1 / &sum_aic_t.;
		end;
		output;
	end;
run;


data bigplot;
	set prediction_weibull2 (keep=dose obs_prop lowerlimit upperlimit)
		modelavg1 (rename=(dose=ma_dose))
		plot_gamma (keep=dose1 resp1 rename=(dose1=gammadose resp1=gammaresp))
		plot_linear (keep=dose1 resp1 rename=(dose1=lineardose resp1=linearresp))
		plot_logistic (keep=dose1 resp1 rename=(dose1=logisticdose resp1=logisticresp))
		plot_log_logistic (keep=dose1 resp1 rename=(dose1=loglogisticdose resp1=loglogisticresp))
		plot_log_probit (keep=dose1 resp1 rename=(dose1=logprobitdose resp1=logprobitresp))
		plot_ms2 (keep=dose1 resp1 rename=(dose1=ms2dose resp1=ms2resp))
		plot_probit (keep=dose1 resp1 rename=(dose1=probitdose resp1=probitresp))
		plot_weibull (keep=dose1 resp1 rename=(dose1=weibulldose resp1=weibullresp));
run;

proc sgplot data=bigplot;
	yaxis min=0 max=1;
	scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); /* obs proportion w/ error bars */
	series x=ma_dose y=pi_modelavg / CurveLabel="Model-Average";
	series x=gammadose y=gammaresp / CurveLabel="Gamma";
	series x=lineardose y=linearresp / CurveLabel="Quantal Linear";
	series x=logisticdose y=logisticresp / CurveLabel="Logistic";
	series x=loglogisticdose y=loglogisticresp / CurveLabel="Log Logistic";
	series x=logprobitdose y=logprobitresp / CurveLabel="Log Probit";
	series x=ms2dose y=ms2resp / CurveLabel="Multistage 2";
	series x=probitdose y=probitresp / CurveLabel="Probit";
	series x=weibulldose y=weibullresp / CurveLabel="Weibull";
run;



%macro bisection(datain=, maxiterations=, convergence=, risktype=, bmr=);
	/*
		REQUIRES MACRO VARIABLES FOR
			Model parameter maximum likelihood estimates
			Transformed AIC weights
			Sum of transformed AIC weights
			BMR
	*/

	/* use the bisection method to numerically find the BMD */

	/* get initial interval endpoints as min and max dose */
	proc sql noprint;
		select min(dose)
		into :mindose
		from &DATAIN.;

		select max(dose)
		into :maxdose
		from &DATAIN.;
	quit;
	/* !!!!!!!!!  assumes mindose < maxdose; assumes maxdose>0 !!!!!!!!!!!!!!!! */

	data _null_;
		
		/* compute the model average probability at the current lowest dose */
		if &MINDOSE.=0 then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));
			pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */
			pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));

			pi_modelavg_lower1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;
	   end;
	   if &MINDOSE.>0 then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));
			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MINDOSE.)));
			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MINDOSE.));
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));

			pi_modelavg_lower1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);

			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;
		end;

		call symput("pi_lowerbound_current", pi_modelavg_lower);

		/* compute the model average probability at the current highest dose */
		if &MAXDOSE.>0 then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MAXDOSE., &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MAXDOSE.)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MAXDOSE.));
			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MAXDOSE.)));
			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MAXDOSE.));
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MAXDOSE.) + &ms2_b2. * &MAXDOSE.**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MAXDOSE.);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MAXDOSE.**&weibull_a.))));

			pi_modelavg_upper1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);

			pi_modelavg_upper = pi_modelavg_upper1 / &sum_aic_t.;
		end;

		call symput("pi_upperbound_current", pi_modelavg_upper);

		/* compute the model average probability at DOSE=0 for BMR computation */
		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*0, &gamma_a., 1);
		pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*0)));
		pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*0));
		pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */
		pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */
		pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (0) + &ms2_b2. * 0**2)));
		pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*0);
		pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (0**&weibull_a.))));

		pi_modelavg1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
		pi_zero = pi_modelavg1 / &sum_aic_t.;

		pi_bmd_extra = &BMR.*(1-pi_zero) + pi_zero; /* compute probability of response at the unknown BMD for EXTRA RISK */
		pi_bmd_added = &BMR. + pi_zero; /* compute probability of response at the unknown BMD for ADDED RISK */

		call symput ("pi_bmd_e", pi_bmd_extra);
		call symput ("pi_bmd_a", pi_bmd_added);
	run;

	/* Check initial endpoints against target, based on risk type */
	data _null_;
		temp = "&risktype.";
		temp2 = upcase(temp);
		call symput("uppercase_risktype", temp2);
	run;

	%macro runbisection_EXTRA();
		/* evaluate initial midpoint */
		data _null_;
			dose_mid = (&maxdose. + &mindose.)/2;

			pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose_mid, &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose_mid)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose_mid));
			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose_mid)));
			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose_mid));
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose_mid) + &ms2_b2. * dose_mid**2)));
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose_mid);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose_mid**&weibull_a.))));

			pi_modelavg_mid1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
			pi_modelavg_mid = pi_modelavg_mid1 / &sum_aic_t.;

			call symput("pi_middose_current", pi_modelavg_mid);
			call symput("middose_current", dose_mid);
		run;
		%put PI MIDDOSE --- &pi_middose_current.;
		%put MIDDOSE ---- &middose_current.;

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

			else if pi_mid < pi_bmd then do;
				lowerbound_current = &middose_current.;
				upperbound_current=&maxdose.;
				call symput("lowerbound_current", lowerbound_current);
				call symput("upperbound_current", upperbound_current);
			end; 
			else if pi_mid = pi_bmd then do;
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

				pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose_mid, &gamma_a., 1);
				pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose_mid)));
				pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose_mid));
				pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose_mid)));
				pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose_mid));
				pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose_mid) + &ms2_b2. * dose_mid**2)));
				pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose_mid);
				pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose_mid**&weibull_a.))));

				pi_modelavg_mid1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
									(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
									(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
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

				else if pi_mid < pi_bmd then do;
					lowerbound_current = &middose_current.;
					upperbound_current=&upperbound_current.;
					call symput("lowerbound_current", lowerbound_current);
					call symput("upperbound_current", upperbound_current);
				end; 
				else if pi_mid = pi_bmd then do;
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

		%let BMD_MA = &middose_current.;
	%mend; /* end RUNBISECTION_EXTRA */

	%runbisection_extra();

	/*
	%if &uppercase_risktype.=EXTRA %then %do;
		%if &lowerbound_current. < &pi_bmd_e. AND &upperbound_current. > &pi_bmd_e. %then %RUNBISECTION_EXTRA();
	%end;

	%if &uppercase_risktype.=ADDED %then %do;
		%if &lowerbound_current. < &pi_bmd_a. AND &upperbound_current. > &pi_bmd_a. %then %RUNBISECTION_ADDED();
	%end;
	*/

	data ma_out;
		bmd_ma = &bmd_ma.;
	run;
%mend; /* end BISECTION */

%bisection(datain=dataset, maxiterations=500, convergence=0.0001, risktype=EXTRA, bmr=0.1);
proc print data=_tracking;
run;

%put BMR IS &BMR.;
%put BMD IS CURRENTLY &BMD_MA.;


%mend; /* end MODELAVERAGE */";
