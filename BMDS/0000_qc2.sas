%let risktype=adDed;

%macro test;
%put *** RISK TYPE IS &risktype. ***;

data _null_;
	temp = "&risktype.";
	temp2 = upcase(temp);
	call symput("upper_risktype", temp2);
run;

%if &upper_risktype.=ADDED %then %do;
	%let works=1;
%end;

%else %do;
	%let works=0;
%end;

%put *** Does it work?  &works. ***;

%mend;

%test;





/* want to find the root of Y = X - 5, where x is in [-10, 10]
		the root is of course 5
*/

%let maxdose=10;
%let mindose=-10;
%let lowerbound_current=-10;
%let upperbound_current=10;
%let pi_bmd_e = 0; /* want the root to be X such that Y=0 */
%let convergence=0.00000000001;

%macro runbisection_EXTRA();
		/* evaluate initial midpoint */
		data _null_;
			dose_mid = (&maxdose. - &mindose.)/2;

			pi_modelavg_mid = dose_mid - 5;

			call symput("pi_middose_current", pi_modelavg_mid);
			call symput("middose_current", dose_mid);
		run;

		/* redefine interval based on where the pi(midpoint) lies relative to pi(bmd) */
		%if %sysevalf(&pi_middose_current. - &pi_bmd_e.) > 0 %then %do;
			%let lowerbound_prev = &lowerbound_current.;
	
			%let upperbound_prev = &upperbound_current.;
			%let upperbound_current = &pi_middose_current.;
		%end;
		%else %if &pi_middose_current. < &pi_bmd_e. %then %do;
			%let lowerbound_prev = &lowerbound_current.;
			%let lowerbound_current = &pi_middose_current.;

			%let upperbound_prev = &upperbound_current.;
		%end; 
		%else %if &pi_middose_current. = &pi_bmd_e. %then %do;
			%let BMD_MA = &middose_current.;
		%end;

		%do %while ( %sysevalf( %sysfunc(ABS(&pi_bmd_e. - &pi_middose_current.)) > &convergence) );

			data _null_;
				dose_mid = (&upperbound_current. - &lowerbound_current.)/2;

				pi_modelavg_mid = dose_mid - 5;

				call symput("pi_middose_current", pi_modelavg_mid);
				call symput("middose_current", dose_mid);
			run;

			%if %sysevalf(&pi_middose_current. - &pi_bmd_e.) > 0 %then %do;
				%let lowerbound_prev = &lowerbound_current.;
	
				%let upperbound_prev = &upperbound_current.;
				%let upperbound_current = &pi_middose_current.;
			%end;
			%else %if &pi_middose_current. < &pi_bmd_e. %then %do;
				%let lowerbound_prev = &lowerbound_current.;
				%let lowerbound_current = &pi_middose_current.;

				%let upperbound_prev = &upperbound_current.;
			%end; 
			%else %if &pi_middose_current. = &pi_bmd_e. %then %do;
				%let BMD_MA = &middose_current.;
			%end;

		%end;

%mend; /* end RUNBISECTION_EXTRA */
%runbisection_extra;
%put BMD IS &middose_current.;






%let mindose=0;
%let maxdose=4;
%let bmr=0.1;
data _null_;
	file print;
		if %sysevalf(&MINDOSE.=0) then do;
	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);
			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));
			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));
			pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */
			pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */
			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));
			/* pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MINDOSE.) + &ms3_b2. * &MINDOSE.**2 + &ms3_b3.*&MINDOSE.**3))); ---CHECK PARENTHESES---*/
			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);
			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));

			pi_modelavg_lower1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + 
							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + 
							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);
			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;
	   end;
	   
/*	   if %sysevalf(&MINDOSE.>0) then do;*/
/*	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MINDOSE., &gamma_a., 1);*/
/*			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MINDOSE.)));*/
/*			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MINDOSE.));*/
/*			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MINDOSE.)));*/
/*			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MINDOSE.));*/
/*			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MINDOSE.) + &ms2_b2. * &MINDOSE.**2)));*/
/*			/* pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MINDOSE.) + &ms3_b2. * &MINDOSE.**2 + &ms3_b3.*&MINDOSE.**3))); ---CHECK PARENTHESES---*/*/
/*			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MINDOSE.);*/
/*			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MINDOSE.**&weibull_a.))));*/
/**/
/*			pi_modelavg_lower1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + */
/*							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + */
/*							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg_lower = pi_modelavg_lower1 / &sum_aic_t.;*/
/*		end;*/
	   ;

/*		call symput("lowerbound_current", pi_modelavg_lower);*/
/**/
/*		if %sysevalf(&MAXDOSE.>0) then do;*/
/*	   		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*&MAXDOSE., &gamma_a., 1);*/
/*			pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*&MAXDOSE.)));*/
/*			pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*&MAXDOSE.));*/
/*			pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(&MAXDOSE.)));*/
/*			pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(&MAXDOSE.));*/
/*			pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (&MAXDOSE.) + &ms2_b2. * &MAXDOSE.**2)));*/
/*			/* pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (&MAXDOSE.) + &ms3_b2. * &MAXDOSE.**2 + &ms3_b3.*&MAXDOSE.**3))); ---CHECK PARENTHESES---*/*/
/*			pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*&MAXDOSE.);*/
/*			pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (&MAXDOSE.**&weibull_a.))));*/
/**/
/*			pi_modelavg_upper1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + */
/*							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + */
/*							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);*/
/**/
/*			pi_modelavg_upper = pi_modelavg_upper1 / &sum_aic_t.;*/
/*		end;*/
/**/
/*		call symput("upperbound_current", pi_modelavg_upper);*/
/**/
/**/
/*		pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*0, &gamma_a., 1);*/
/*		pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*0)));*/
/*		pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*0));*/
/*		pi_log_logistic = &loglogistic_g.; /* specify equal to background at dose=0 */*/
/*		pi_log_probit = &logprobit_g.; /* specify equal to background at dose=0 */*/
/*		pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (0) + &ms2_b2. * 0**2)));*/
/*			/* pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (0) + &ms3_b2. * 0**2 + &ms3_b3.*0**3))); /*---CHECK PARENTHESES---*/*/
/*		pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*0);*/
/*		pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (0**&weibull_a.))));*/
/**/
/*		pi_modelavg1 = (pi_gamma * &gamma_aict.) + (pi_linear * &linear_aict.) + (pi_logistic * &logistic_aict.) + */
/*							(pi_log_logistic * &loglogistic_aict.) + (pi_log_probit * &logprobit_aict.) + (pi_ms2 * &ms2_aict.) + */
/*							(pi_probit * &probit_aict.) + (pi_weibull * &weibull_aict.);*/
/*		pi_zero = pi_modelavg1 / &sum_aic_t.;*/
/**/
/*		pi_bmd_extra = &BMR.*(1-pi_zero) + pi_zero; /* compute probability of response at the unknown BMD for EXTRA RISK */*/
/*		pi_bmd_added = &BMR. + pi_zero; /* compute probability of response at the unknown BMD for ADDED RISK */*/
/**/
/*		call symput ("pi_bmd_e", pi_bmd_extra);*/
/*		call symput ("pi_bmd_a", pi_bmd_added);*/
;

		Put "Pi Gamma = " pi_gamma;
		Put "Pi Linear = " pi_linear;
		Put "Pi Logistic = " pi_logistic;
		Put "Pi Log Logistic = " pi_log_logistic;
		Put "Pi Log Probit = " pi_log_probit;
		Put "Pi MS2 = " pi_ms2;
		Put "Pi Probit = " pi_probit;
		Put "Pi Weibull = " pi_Weibull;
		put "ModelAvg Lower 1 = " pi_modelavg_lower1;
		put "ModelAvg Lower = " pi_modelavg_lower;
	run;

	%put LOWERBOUND = &lowerbound_current.;
	%put UPPERBOUND = &upperbound_current.;
	%put PI(BMD) = &pi_bmd_e.;
