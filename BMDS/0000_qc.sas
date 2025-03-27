options nocenter nonumber nodate ls=80 mprint symbolgen formdlim="*";

data dataset;
   input dose obs n;
   datalines;
   0.0 2 10
   0.5 2 10
   1.0 2 10
   2.0 6 10
   4.0 9 10
   ;
run;

%let BMR=0.1;
%let cl = 0.95;

ods listing close; 
   ods output fitstatistics = fitstatistics
              ParameterEstimates=ParameterEstimates;
ods graphics on;
proc nlmixed data=dataset noprint;
      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
		     _bdose >= 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**_alpha);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      _x = -log(1 - &BMR);
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull;   
   run;
   ods graphics off;
   ods listing;

   data prediction_weibull2;
	set prediction_weibull;
	file print;

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

data _null_;
	set parameterestimates;

	if parameter="_gamma" then do;
		call symput ("GG", estimate);
	end;
	if parameter="_alpha" then do;
		call symput ("AA", estimate);
	end;
	if parameter="_bdose" then do;
		call symput ("BB", estimate);
	end;
run;

data plot_weibull;
	do dose1=0 to 4 by 0.1;
		if dose1=0 then resp1=&GG.;
		else if dose1>0 then do;
	     	resp1 = &GG. + (1 - &GG.)*(1 - exp(-1*(&BB. * (dose1**&AA.))));
		end;
		output;
	end;
run;

proc sgplot data=plot_weibull;
	scatter x=dose1 y=resp1;
	series x=dose1 y=resp1;
run;


data plot_weibull2;
	set prediction_weibull2 plot_weibull;
	label dose="Dose"
	      obs_prop="Proportion Responding";

run;

%let BMD=0.87761;
%let BMDL=0.26211;
/* final plot */
proc sgplot data=plot_weibull2 noautolegend;
	scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond);
	series x=dose1 y=resp1;
	title1 "Weibull Model, with BMR of &BMR. Extra Risk for the BMD and &CL. Lower Confidence Limit for the BMDL";
	title2 "BMD = &BMD.    BMDL = &BMDL.";
run;


	/* set up vertical and horizontal lines to illustrate BMD and BMDL */
	/* BMD veritical:  x=BMD from y=0 to y=BMR
	/* BMDL vertical: x=BMDL fromy=0 to y=BMR
	/* BMR horizontal: y=BMR from x=0 to x=BMD */
data plot_weibull_BMD (keep = dose2 resp2 label);
	format label $4.; informat label $4.;
	
	pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-1*(&BB. * (&BMD.**&AA.))));

	do ii=0 to 1 by 0.001;
		if ii<=pi_bmd then resp2 = ii;
		else if ii>pi_bmd then delete;
		dose2=&BMD.;
		if ii=0 then label="BMD";
		if ii>0 then label="";
		output;
	end;
run;

data plot_weibull_BMDL (keep = dose3 resp3 label);
	format label $4.; informat label $4.;
	
	pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-1*(&BB. * (&BMD.**&AA.))));

	do ii=0 to 1 by 0.001;
		if ii<=pi_bmd then resp3 = ii;
		else if ii>pi_bmd then delete;
		dose3=&BMDL.;
		if ii=0 then label="BMDL";
		if ii>0 then label="";
		output;
	end;
run;

data plot_weibull_BMR (keep = dose4 resp4);
	
	pi_bmd = &GG. + (1 - &GG.)*(1 - exp(-1*(&BB. * (&BMD.**&AA.))));
	
	do ii=0 to 1 by 0.001;
		if ii<=&BMD. then dose4 = ii;
		else if ii>&BMD. then delete;
		resp4=pi_bmd;
		output;
	end;
run;

data plot_weibull3;
	set plot_weibull2 plot_weibull_bmd plot_weibull_BMDL plot_weibull_BMR;
run;

proc sgplot data=plot_weibull3 noautolegend;
	scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond); /* obs proportion w/ error bars */
	series x=dose1 y=resp1 / markerattrs=(color=red); /* model fit */
	series x=dose2 y=resp2 / datalabel=label lineattrs=(color=black); /* vertical BMD line to curve */
	series x=dose3 y=resp3 / datalabel=label lineattrs=(color=black); /* vertical BMDL line to curve */
	series x=dose4 y=resp4 / lineattrs=(color=black); /* horizontal BMR line to curve */
	title1 "Weibull Model, with BMR of &BMR. Extra Risk for the BMD and &CL. Lower Confidence Limit for the BMDL";
	title2 "BMD = &BMD.    BMDL = &BMDL.";
run;
		
	




proc summary data=prediction_weibull2 nway;
	var sq_residual;
	output out=prediction_weibull3 (drop=_type_ _freq_) sum()= n=dosegroups;
run;
data prediction_weibull3;
	set prediction_weibull3;
	file print;
	pval = 1 - probchi(sq_residual, dosegroups-3); /* manually enter # params */
	put "Goodness-of-Fit X2 Statistic: " sq_residual;
	put "Goodness-of-Fit P-value: " pval;
run; 

proc sgplot data=prediction_weibull2 noautolegend;
   scatter x=dose y=obs_prop / yerrorlower=lowerlimit yerrorupper=upperlimit markerattrs=(color=green symbol=diamond);
   series x=dose y=obs_prop / lineattrs=(color=red pattern=2);
   title "Weibull Model, with BMR of &BMR. Extra Risk for the BMD and 0.95 Lower Confidence Limit for the BMDL";
run;



data one;
	file print;
	cl=0.95;
	z=probit(1-(cl/2));
	put "Z = " z;
run;
