/*

step 3: fit the models used in the avg
step 4: get the model average and bmd
step 5: repeat to get a BMD distribution, select appropriate percentile
*/

%macro modelavg_BMDL_percentile(datain=, num_samples=, BMR=, CL=, maxiterations=, convergence=,
								weibull=, logistic=, loglogistic=, gamma=, 
								linear=, probit=, logprobit=, ms2=, ms3=, quadratic=,
								all_results=, pe_weibull=, pe_logistic=, pe_log_logistic=, pe_gamma=, pe_linear=, 
			  					pe_probit=, pe_log_probit=, pe_ms2=, pe_ms3=, pe_quadratic=);

/* initialize weight parameters */
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

/* initialize dataset to hold all the model average bmd estimates for the NUM_SAMPLES bootstrap samples */
data ma_bmd_distribution;
			format ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
			informat ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
run;

/* calculate required weight parameters */
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

/* set up necessary model parameters for the model average */
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


/*//////		Get probability of response at each dose group using the model average	/////////////////*/

data ma_probabilities (keep=dose n pi_modelavg);
	set &DATAIN. (drop=obs);

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

					
	   if dose=0 then do;
	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);
			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));
			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose**2))));
			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));
			if useloglogistic=1 then pi_loglogistic = &loglogistic_g.; /* specify equal to background at dose=0 */
			if uselogprobit=1 then pi_logprobit = &logprobit_g.; /* specify equal to background at dose=0 */
			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));
			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp( -(&ms3_b1. * (dose) + &ms3_b2. * dose**2 + &ms3_b3.*dose**3)));
			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);
			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));

			pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + 
						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + 
						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);

			pi_modelavg = pi_modelavg1 / &sum_aic_t.;
	   end;

	   if dose>0 then do;
	   		if usegamma=1 then pi_gamma = &gamma_g. + (1 - &gamma_g.)*cdf('GAMMA', &gamma_b.*dose, &gamma_a., 1);
			if uselinear=1 then pi_linear = &linear_g. + (1 - &linear_g.)*(1 - exp(-(&linear_b.*dose)));
			if usequadratic=1 then pi_quadratic = &quadratic_g. + (1 - &quadratic_g.)*(1 - exp(-(&quadratic_b. * (dose**2))));
			if uselogistic=1 then pi_logistic = 1 / (1 + exp(-&logistic_a. - &logistic_b.*dose));
			if useloglogistic=1 then pi_log_logistic = &loglogistic_g. + (1 - &loglogistic_g.) / (1 + exp(-&loglogistic_a. - &loglogistic_b.*log(dose)));
			if uselogprobit=1 then pi_log_probit = &logprobit_g. + (1 - &logprobit_g.) * CDF('NORMAL', &logprobit_a. + &logprobit_b.*log(dose));
			if usems2=1 then pi_ms2 = &ms2_g. + (1 - &ms2_g.)*(1 - exp(-(&ms2_b1. * (dose) + &ms2_b2. * dose**2)));
			if usems3=1 then pi_ms3 = &ms3_g. + (1 - &ms3_g.)*(1 - exp(-(&ms3_b1. * (dose) + &ms3_b2. * dose**2 + &ms3_b3.*dose**3)));
			if useprobit=1 then pi_probit = CDF('NORMAL', &probit_a. + &probit_b.*dose);
			if useweibull=1 then pi_weibull = &weibull_g. + (1 - &weibull_g.)*(1 - exp(-(&weibull_b. * (dose**&weibull_a.))));

			pi_modelavg1 = usegamma*(pi_gamma * &gamma_aict.) + uselinear*(pi_linear * &linear_aict.) + usequadratic*(pi_quadratic * &quadratic_aict.) + 
						   uselogistic*(pi_logistic * &logistic_aict.) + useloglogistic*(pi_log_logistic * &loglogistic_aict.) + uselogprobit*(pi_log_probit * &logprobit_aict.) + 
						   usems2*(pi_ms2 * &ms2_aict.) + usems3*(pi_ms3 * &ms3_aict.) + useprobit*(pi_probit * &probit_aict.) + useweibull*(pi_weibull * &weibull_aict.);

			pi_modelavg = pi_modelavg1 / &sum_aic_t.;
		end;
run;


/* generate the bootstrap samples */
%do jj=1 %to &NUM_SAMPLES.;

	data samps.bootstrap_sample&jj.;
		set ma_probabilities;
		obs = rand('BINOMIAL', pi_modelavg, n);
	run;

%end; /* END bootstrap sample generation */



/* fit the specified individual models to each bootstrap dataset
   fit the model average and estimate the bmd*/
%do ii=1 %to &NUM_SAMPLES.;

/* initialize all next step datasets so that they exist when called */
data pe_weibull_sample&ii. pe_logistic_sample&ii. pe_log_logistic_sample&ii. pe_gamma_sample&ii. pe_linear_sample&ii. pe_probit_sample&ii. 
	pe_log_probit_sample&ii. pe_ms2_sample&ii. pe_ms3_sample&ii. pe_quadratic_sample&ii.
	fitstats_weibull_sample&ii fitstats_logistic_sample&ii. fitstats_log_logistic_sample&ii. fitstats_gamma_sample&ii. fitstats_linear_sample&ii. fitstats_probit_sample&ii. 
	fitstats_log_probit_sample&ii. fitstats_ms2_sample&ii. fitstats_ms3_sample&ii. fitstats_quadratic_sample&ii.;
	set _null_;
run;

%if &WEIBULL.=1 %then %do;
   ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_weibull_sample&ii.
              ParameterEstimates=pe_weibull_sample&ii.;

   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**_alpha);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      model obs ~ binomial(n, p);
   run;

   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &LOGISTIC.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_logistic_sample&ii.
              ParameterEstimates=pe_logistic_sample&ii.;

   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _bdose = 0.5 
            _alpha=1;

      bounds _bdose >= 0;
      p = 1 / (1 + exp(-_alpha));
      if (dose > 0) then do;
	     p = 1 / (1 + exp(-_alpha - _bdose*dose));
      end;
      model obs ~ binomial(n, p);
   run;

   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &LOGLOGISTIC.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_log_logistic_sample&ii.
              ParameterEstimates=pe_log_logistic_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _bdose = 2
            _alpha=1
			_gamma=0.5;
      bounds _bdose >= 1, _gamma >=0, _gamma <= 1; /* _alpha >=0, _alpha <= 18;*/
      p = _gamma;
      if (dose > 0) then do;
	     p = _gamma + (1 - _gamma) / (1 + exp(-_alpha - _bdose*log(dose)));
      end;
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &GAMMA.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_gamma_sample&ii.
              ParameterEstimates=pe_gamma_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma=0.1
			_beta=1
			_alpha=2;
      bounds _gamma >= 0, _gamma <= 1, _beta >= 0, _alpha >= 1, _alpha <= 18;
      p = _gamma + (1 - _gamma)*cdf('GAMMA', _beta*dose, _alpha, 1);
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &LINEAR.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_linear_sample&ii.
              ParameterEstimates=pe_linear_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _bdose >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &PROBIT.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults;
   ods output fitstatistics = fitstats_probit_sample&ii.
              ParameterEstimates=pe_probit_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _beta =  0.1
            _alpha = 0.1;
      bounds _beta >= 0;
      p = CDF('NORMAL', _alpha + _beta*dose);
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &LOGPROBIT.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_log_probit_sample&ii.
              ParameterEstimates=pe_log_probit_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _beta =  0.1
            _alpha = 0.1
			_gamma = 0.1;
      bounds _beta >= 0, _beta <= 18, _gamma >= 0, _gamma <= 1;
	  p = _gamma;
	  if dose > 0 then do;
      	p = _gamma + (1 - _gamma) * CDF('NORMAL', _alpha + _beta*log(dose));
	  end;	
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &MS2.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_ms2_sample&ii.
              ParameterEstimates=pe_ms2_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose1 = 0.5
			_bdose2 = 0.5;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _bdose1 >= 0,
			 _bdose2 >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose1 * (dose) + _bdose2 * dose**2;
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &MS3.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_ms3_sample&ii.
              ParameterEstimates=pe_ms3_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose1 = 0
			_bdose2 = 0
            _bdose3 = 0;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _bdose1 >= 0,
			 _bdose2 >= 0,
             _bdose3 >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose1 * (dose) + _bdose2 * dose**2 + _bdose3 * dose**3;
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

%if &QUADRATIC.=1 %then %do;
	ods listing close;
	  ods exclude all;
	  ods noresults; 
   ods output fitstatistics = fitstats_quadratic_sample&ii.
              ParameterEstimates=pe_quadratic_sample&ii.;
   proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _bdose >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**2);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      model obs ~ binomial(n, p);
   run;
   ods results;
	  ods exclude none;
      ods listing;
%end;

data out_all_sample&ii. (keep=model AIC);
	format AIC best12.;
	informat AIC best12.;
	set fitstats_weibull_sample&ii. (in=aa) fitstats_logistic_sample&ii. (in=bb) fitstats_log_logistic_sample&ii. (in=cc) 
		fitstats_gamma_sample&ii. (in=dd) fitstats_linear_sample&ii. (in=ee) fitstats_probit_sample&ii. (in=ff) 
		fitstats_log_probit_sample&ii. (in=gg) fitstats_ms2_sample&ii. (in=hh) fitstats_ms3_sample&ii. (in=kk) 
		fitstats_quadratic_sample&ii. (in=ll);

	if (descr = "AIC (smaller is better)");

	if aa=1 then model="WEIBULL";
	if bb=1 then model="LOGISTIC";
	if cc=1 then model="LOG-LOGISTIC";
	if dd=1 then model="GAMMA";
	if ee=1 then model="LINEAR";
	if ff=1 then model="PROBIT";
	if gg=1 then model="LOG PROBIT";
	if hh=1 then model="MULTISTAGE 2";
	if kk=1 then model="MULTISTAGE 3";
	if ll=1 then model="QUADRATIC";

	AIC = value;
run;

%include "Z:\MyLargeWorkspace Backup\BMDS in SAS\20_model_averaging_added.sas";
%modelaverage(datain=samps.bootstrap_sample&ii., maxiterations=&maxiterations., convergence=&convergence., bmr=&BMR., dataout=out_modelavg&ii.,
			  weibull=&weibull., logistic=&logistic., loglogistic=&loglogistic., gamma=&gamma., linear=&linear., probit=&probit., logprobit=&logprobit., ms2=&ms2., ms3=&ms3., quadratic=&quadratic.,
			  pe_weibull=pe_weibull_sample&ii., pe_logistic=pe_logistic_sample&ii., pe_log_logistic=pe_log_logistic_sample&ii., pe_gamma=pe_gamma_sample&ii., pe_linear=pe_linear_sample&ii., 
			  pe_probit=pe_probit_sample&ii., pe_log_probit=pe_log_probit_sample&ii., pe_ms2=pe_ms2_sample&ii., pe_ms3=pe_ms3_sample&ii., pe_quadratic=pe_quadratic_sample&ii.,
			  all_results=out_all_sample&ii.);

data ma_bmd_distribution;
	set ma_bmd_distribution out_modelavg&ii.;
run;

proc datasets library=work;
	delete pe_weibull_sample&ii. pe_logistic_sample&ii. pe_log_logistic_sample&ii. pe_gamma_sample&ii. pe_linear_sample&ii. pe_probit_sample&ii. 
	pe_log_probit_sample&ii. pe_ms2_sample&ii. pe_ms3_sample&ii. pe_quadratic_sample&ii.
	fitstats_weibull_sample&ii fitstats_logistic_sample&ii. fitstats_log_logistic_sample&ii. fitstats_gamma_sample&ii. fitstats_linear_sample&ii. fitstats_probit_sample&ii. 
	fitstats_log_probit_sample&ii. fitstats_ms2_sample&ii. fitstats_ms3_sample&ii. fitstats_quadratic_sample&ii.
	out_modelavg&ii. out_all_sample&ii.;
run;
quit;

%end; /* END model fits to each bootstrap sample */








%mend; /* modelavg_BMDL_percentile() */
