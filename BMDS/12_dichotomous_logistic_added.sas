
%macro boundBMD(BMR, CL,DATAIN, DATAOUT, ESTIMATES);
   ods listing close; 
   ods output fitstatistics = fitstatistics
              ParameterEstimates=ParameterEstimates;

   proc nlmixed data=&DATAIN maxiter=1000;
      parms _bdose = 0.5 
            _alpha=1;

      bounds _bdose >= 0;

      p = 1 / (1 + exp(-_alpha));

      if (dose > 0) then do;
	     p = 1 / (1 + exp(-_alpha - _bdose*dose));
      end;

	  _Z = &BMR. * (1 + exp(-_alpha)) / exp(-_alpha);
      _bmd = (-1) * log( (1-_Z) / (1 + _Z * exp(-_alpha)) ) / _bdose;
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_logistic;
   run;

   ods listing;

   /* copy of estimates for model-averaging */
   data &ESTIMATES.;
      set parameterestimates;
   run;

   proc sql noprint;
      select count(Parameter)
	  into :num_parameters
	  from parameterestimates;
   quit;

   data prediction_logistic2;
	  set prediction_logistic;

	  expected = n*pred;
	  SE = sqrt(n*pred*(1-pred));
	  scaledresidual = (obs-expected)/SE; /* pearson residual --- 2 is unusual */
	  sq_residual = scaledresidual**2; /* for Goodness of Fit */

	  /* --- Get coordinates for error bars --- */
	  /*		Modified Wilson interval with continuity correction */
	  /*		BMDS 2.6 User Manual, pg. 141 */
	  obs_prop = obs/n;
	  z=probit(1-((1-&CL.)/2));
	  lowerlimit = ( (2*obs + z**2 - 1) - z * sqrt(z**2 - (2 + (1/n)) + 4*(obs/n)*(n*(1-(obs/n))+1)) ) / (2 * (n + z**2) );
	  upperlimit = ( (2*obs + z**2 + 1) + z * sqrt(z**2 + (2 - (1/n)) + 4*(obs/n)*(n*(1-(obs/n))-1)) ) / (2 * (n + z**2) );
   run;

   proc summary data=prediction_logistic2 nway;
	  var sq_residual;
	  output out=prediction_logistic3 (drop=_type_ _freq_) sum()= n=dosegroups;
   run;

   data prediction_logistic3;
	  set prediction_logistic3;
	  file print;
	  pval = 1 - probchi(sq_residual, dosegroups-&num_parameters.); 
	  call symput("ChiSq_Stat", sq_residual);
	  call symput("GoF_pval", pval);
   run; 

   /* Get AIC */
   data fitstatisticsAIC;
	   set fitstatistics;
	   if (Descr = "AIC (smaller is better)");
	   call symput("AIC", value);
   run;
 
   /* Get initial likelihood */
   data fitstatistics;
      set fitstatistics; 
      format value best16.;
      informat value best16.;
      if (Descr = "-2 Log Likelihood");
     /* NegLogLike = value/2; */
      call symput("MLIKE", value);
      /* keep value NegLogLike; */
   run;

   %let MLIKE = %sysevalf(&mlike/2); /* looks like its representing the negative log likelihood */
   %LET BMDL = &BMD; /* initializes BMDL to be the BMD maximum likelhihood estimate */
   %LET COUNTER = 0;

   data _temp_; 
      val = cinv(1-2*(1-&CL),1)*0.5;
      call symput("CRITVAL",val);
   run;

   data parameterestimates2;
      set parameterestimates;
   run;

   %LET CRITLIKE = &MLIKE;
   %LET NOTES = "";

   %DO %WHILE (%SYSEVALF(&CRITLIKE - &MLIKE < &CRITVAL));
   *set up the initial parameters for the new likelihood;

      %LET COUNTER = %SYSEVALF(&COUNTER+1);
      %LET LASTBMDL = &BMDL;
      %LET BMDL = %SYSEVALF(0.98*&LASTBMDL);
      /*%LET BOUNDS = ; *//* no bounds for Logistic after initializations */
      /*%LET SMODEL = ;*/

      data pe; 
         set ParameterEstimates2; 
         if(Parameter='_bdose')then delete;
      run;

      data pe;
         set pe;
      run;

      ods listing close;
	  ods exclude all;
	  ods noresults; 
      ods output fitstatistics = fitstatistics
                 ParameterEstimates=ParameterEstimates2;

      *fit this new “constrained” likelihood;
      proc nlmixed data= &DATAIN. maxiter=1000;
         parms /data=pe; 
         /*bounds &bounds;*/

         
         *solve for the BETA parameter BDOSE as a function of the BMD;
		 _Z = &BMR. * (1 + exp(-_alpha)) / exp(-_alpha);
         _BDOSE = (-1) * log( (1-_Z) / (1 + _Z * exp(-_alpha)) ) / &BMDL.;

         p = 1 / (1 + exp(-_alpha));

         if (dose > 0) then do;
	        p = 1 / (1 + exp(-_alpha - _bdose*dose));
         end;

         MODEL OBS ~ BINOMIAL(N,P); 

      run;

      ods results;
	  ods exclude none;
      ods listing;

      *obtain the Fit statistics to determine if the algorithm has bounded the BMDL;
      data fitstatistics;
         set fitstatistics; 
         format value best16.;
         informat value best16.;
         if (Descr = "-2 Log Likelihood");
         NegLogLike = value/2; 
         keep value NegLogLike;
      run;

      data _temp_;
         set fitstatistics;
         call symput("CRITLIKE",NegLogLike);
      run;

	  /* force exit after 250 iterations */
	  %if &counter.=250 %then %do;
	     %let CRITLIKE = 1000;
		 %let NOTES = "Forced Exit of BMDL Estimation";
	  %end;


   %END;

   data &DATAOUT.;
   		ChiSq = &ChiSq_Stat.;
		GoF_pvalue = &GoF_pval.;
		AIC = &AIC.;
        BMR = &BMR.;
		BMD = &BMD.;
		BMDL = &BMDL.;
		MODEL = "LOGISTIC";
		RISK = "ADDED";
		NOTES = &NOTES.;
	run;

	/*////////////////////////////////////////////
	/*  Plot the model, BMD, and BMDL together
	/*/

   /* Save parameter maximum likelihood estimates */
   data _null_;
	  set parameterestimates;

	  if parameter="_alpha" then do;
		  call symput ("AA", estimate);
	  end;
	  if parameter="_bdose" then do;
		  call symput ("BB", estimate);
	  end;
   run;

   /* Create points to plot the model fit */
   proc sql noprint;
     select max(dose)
	 into :maxdose
	 from &DATAIN.;

	 select min(dose)
	 into :mindose
	 from &DATAIN.;
   quit;

   data plot_model;
	  do dose1=&MINDOSE. to &MAXDOSE. by ((&MAXDOSE. - &MINDOSE.)/100);
		  if dose1 = 0 then resp1 = 1 / (1 + exp(-&AA.));
		  else if dose1 > 0 then do;
	     	  resp1 = 1 / (1 + exp(-&AA. - &BB.*dose1));
		  end;
		  output;
	  end;
   run;


	/* set up vertical and horizontal lines to illustrate BMD and BMDL */
	/* BMD  vertical:   x=BMD from  y=0 to y=BMR
	/* BMDL vertical:   x=BMDL from y=0 to y=BMR
	/* BMR  horizontal: y=BMR from  x=0 to x=BMD */
   data plot_BMD (keep = dose2 resp2 label);
	  format label $4.; informat label $4.;
	
	  pi_bmd = 1 / (1 + exp(-&AA. - &BB.*&BMD.));

	  do ii=0 to 1 by 0.001;
		  if ii<=pi_bmd then resp2 = ii;
		  else if ii>pi_bmd then delete;
		  dose2=&BMD.;
		  /* create label to indicate the BMD on the plot */
		  if ii=0 then label="BMD";
		  if ii>0 then label="";
		  output;
	  end;
   run;

   data plot_BMDL (keep = dose3 resp3 label);
	  format label $4.; informat label $4.;
	
	  pi_bmd = 1 / (1 + exp(-&AA. - &BB.*&BMD.));

	  do ii=0 to 1 by 0.001;
		  if ii<=pi_bmd then resp3 = ii;
		  else if ii>pi_bmd then delete;
		  dose3=&BMDL.;
		  /* create label to indicate the BMDL on the plot */
		  if ii=0 then label="BMDL";
		  if ii>0 then label="";
		  output;
	  end;
   run;

   data plot_BMR (keep = dose4 resp4);
	
	  pi_bmd = 1 / (1 + exp(-&AA. - &BB.*&BMD.));
	  bmdround = 1*round(&BMD.,0.001);
	
	  do ii=0 to bmdround by 0.001;
		  if ii<=&BMD. then dose4 = ii;
		  else if ii>&BMD. then delete;
		  resp4=pi_bmd;
		  output;
	  end;
   run;

   data plot_logistic;
	  set prediction_logistic2 plot_model plot_bmd plot_BMDL plot_BMR;
	  label dose="Dose"
	        obs_prop="Proportion Responding";
   run;

   data _null_;
      bmd_round = compress(round(&BMD., 0.01));
	  bmdl_round = compress(round(&BMDL., 0.01));
	  call symput("BMD_ROUND", bmd_round);
	  call symput("BMDL_ROUND", bmdl_round);
   run;

   proc sgplot data=plot_logistic noautolegend;
	  scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); /* obs proportion w/ error bars */
	  series x=dose1 y=resp1 / markerattrs=(color=red); /* model fit */
	  series x=dose2 y=resp2 / datalabel=label datalabelpos=right lineattrs=(color=black); /* vertical BMD line to curve */
	  series x=dose3 y=resp3 / datalabel=label datalabelpos=left lineattrs=(color=black); /* vertical BMDL line to curve */
	  series x=dose4 y=resp4 / lineattrs=(color=black); /* horizontal BMR line to curve */
	  title1 "Logistic Model, with BMR of &BMR. Added Risk for the BMD and &CL. Lower Confidence Limit for the BMDL";
	  title2 "BMD = &BMD_ROUND.    BMDL = &BMDL_ROUND.";
   run;

%mend;
