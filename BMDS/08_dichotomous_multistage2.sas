
%macro boundBMD(BMR, CL,DATAIN, DATAOUT, ESTIMATES);
   ods listing close; 
   ods output fitstatistics = fitstatistics
              ParameterEstimates=ParameterEstimates;

   proc nlmixed data=&DATAIN.;
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


	  call symput("BETA1", _bdose1);
	  call symput("BETA2", _bdose2);

      model obs ~ binomial(n, p);

      predict p out=prediction_ms2;  
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

   data prediction_ms2_2;
	  set prediction_ms2;

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

   proc summary data=prediction_ms2_2 nway;
	  var sq_residual;
	  output out=prediction_ms2_3 (drop=_type_ _freq_) sum()= n=dosegroups;
   run;

   data prediction_ms2_3;
	  set prediction_ms2_3;
	  file print;
	  pval = 1 - probchi(sq_residual, dosegroups-&num_parameters.); 
	  call symput("ChiSq_Stat", sq_residual);
	  call symput("GoF_pval", pval);
   run; 

   /* Get initial guess for BMD --- just using middle dose */
   proc sql noprint;
      select max(dose)/2
      into :INITIAL_BMD
      from &DATAIN.;
   quit;

   /*   Solve for BMD (root)  */
   /*   Beta1*BMD + BETA2*BMD^2 + log(1-BMR) = 0   */
   proc iml;
      start Func(x);
	     BMD = x[1]; /* one dimensional vector */
	     f = &BETA1.*BMD + &BETA2.*BMD**2 + log(1-&BMR.);
		 return(f);
	  finish Func;

	  start Deriv(x);
	     BMD = x[1];
		 dfdx = &BETA1. + 2*&BETA2.*BMD;
		 return(dfdx);
	  finish Deriv;

	  start Newton(x, x0, optn);
	     maxii = optn[1];
		 converge = optn[2];
		 x = x0;
		 f = Func(x);

		 do ii=1 to maxii while(max(abs(f)) > converge);
		    J = Deriv(x);
			delta = -solve(J, f);
			x = x + delta;
			f = Func(x);
		 end;

		 if ii > maxii then x=j(nrow(x0), ncol(x0),.);

	  finish Newton;
	     
	  x0 = {&INITIAL_BMD.};
	  optn = {1000, 1E-6};
	  run Newton(root, x0, optn);
	  f = Func(root);
	  /*print root f;*/

	  call symput("BMD", left(char(root)));
   quit;


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

   data _null_; 
      val = cinv(1-2*(1-&CL),1)*0.5;
      call symput("CRITVAL",val);
   run;

   data ParameterEstimates2;
   	  set ParameterEstimates;
   run;

   %LET CRITLIKE = &MLIKE;

   %DO %WHILE (%SYSEVALF(&CRITLIKE - &MLIKE < &CRITVAL));
   *set up the initial parameters for the new likelihood;

      %LET COUNTER = %SYSEVALF(&COUNTER+1);
      %LET LASTBMDL = &BMDL;
      %LET BMDL = %SYSEVALF(0.98*&LASTBMDL);
      %LET BOUNDS = _gamma >= 0, _gamma <= 1, _bdose2 >= 0;
      /*%LET SMODEL = ;*/

      data pe; 
         set ParameterEstimates2; 
         if(Parameter='_bdose1')then delete;
      run;

      data pe;
         set pe;
      run;

      ods listing close; 
      ods output fitstatistics = fitstatistics
                 ParameterEstimates=ParameterEstimates2;

      *fit this new “constrained” likelihood;
      proc nlmixed data= &DATAIN maxiter=1000;
         parms /data=pe;
         bounds &bounds;

         
         _BDOSE1 = (log(1-&BMR.) + _bdose2*&BMDL.**2)/(-&BMDL.);

         p = _gamma;

         if (dose > 0) then do;
            _link = _bdose1 * (dose) + _bdose2 * dose**2;
	        p = _gamma + (1 - _gamma)*(1 - exp(-_link));
         end;

         MODEL OBS ~ BINOMIAL(N,P); 
      run;
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


   %END;

   data &DATAOUT.;
   		ChiSq = &ChiSq_Stat.;
		GoF_pvalue = &GoF_pval.;
		AIC = &AIC.;
        BMR = &BMR.;
		BMD = &BMD.;
		BMDL = &BMDL.;
		MODEL = "MULTISTAGE 2";
		RISK = "EXTRA";
	run;

	/*////////////////////////////////////////////
	/*  Plot the model, BMD, and BMDL together
	/*/

   /* Save parameter maximum likelihood estimates */
   data _null_;
	  set parameterestimates;

	  if parameter="_gamma" then do;
	  	call symput ("GG", estimate);
	  end;
	  if parameter="_bdose1" then do;
		  call symput ("BB1", estimate);
	  end;
	  if parameter="_bdose2" then do;
		  call symput ("BB2", estimate);
	  end;
   run;

   /* Create points to plot the model fit */
   proc sql noprint;
     select max(dose)
	 into :maxdose
	 from dataset;

	 select min(dose)
	 into :mindose
	 from dataset;
   quit;

   data plot_model;
	  do dose1=&MINDOSE. to &MAXDOSE. by ((&MAXDOSE. - &MINDOSE.)/100);
		  if dose1 = 0 then resp1 = &GG.;
		  else if dose1 > 0 then do;
	     	  resp1 = &GG. + (1 - &GG.)*(1 - exp(-(&BB1. * (dose1) + &BB2. * dose1**2)));
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
	
	  pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-(&BB1. * (&BMD.) + &BB2. * &BMD.**2)));

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
	
	  pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-(&BB1. * (&BMD.) + &BB2. * &BMD.**2)));

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
	
	  pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-(&BB1. * (&BMD.) + &BB2. * &BMD.**2)));
	  bmdround = 1*round(&BMD.,0.001);
	
	  do ii=0 to bmdround by 0.001;
		  if ii<=&BMD. then dose4 = ii;
		  else if ii>&BMD. then delete;
		  resp4=pi_bmd;
		  output;
	  end;
   run;

   data plot_ms2;
	  set prediction_ms2_2 plot_model plot_bmd plot_BMDL plot_BMR;
	  label dose="Dose"
	        obs_prop="Proportion Responding";
   run;

   data _null_;
      bmd_round = compress(round(&BMD., 0.01));
	  bmdl_round = compress(round(&BMDL., 0.01));
	  call symput("BMD_ROUND", bmd_round);
	  call symput("BMDL_ROUND", bmdl_round);
   run;

   proc sgplot data=plot_ms2 noautolegend;
	  scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); /* obs proportion w/ error bars */
	  series x=dose1 y=resp1 / markerattrs=(color=red); /* model fit */
	  series x=dose2 y=resp2 / datalabel=label datalabelpos=right lineattrs=(color=black); /* vertical BMD line to curve */
	  series x=dose3 y=resp3 / datalabel=label datalabelpos=left lineattrs=(color=black); /* vertical BMDL line to curve */
	  series x=dose4 y=resp4 / lineattrs=(color=black); /* horizontal BMR line to curve */
	  title1 "Multistage (Degree 2) Model, with BMR of &BMR. Extra Risk for the BMD and &CL. Lower Confidence Limit for the BMDL";
	  title2 "BMD = &BMD_ROUND.    BMDL = &BMDL_ROUND.";
   run;

%mend;
