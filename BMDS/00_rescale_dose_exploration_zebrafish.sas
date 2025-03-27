/* rescale data where multiple datasets are used/BY modeling */
/*	Army Zebrafish */
/*  See how it works on current data of interest */

proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\Army\Zebrafish\zebrafish\Data\ezmetric_tox_for_analysis.xlsx" out=data1 dbms=excel replace;
	sheet="Data";
run;

data data2;
	set data1 (keep=z1 z4 z5 z3);
	rename z1=index
	       z4=dose
		   z5=obs
		   z3=n;
	if z1="" then delete;
run;

proc sql noprint;
	create table maxdoses as
	select index, 
           max(DOSE) as maxdose
	from data2
	group by index
	;
quit;

data rescale1;
	merge data2 maxdoses;
	by index;
	DOSE_rescale = dose/maxdose;
	drop dose maxdose;
	rename dose_rescale=dose;
run;



/* rescaled */
ods listing close; 
ods output fitstatistics = fitstatistics
           ParameterEstimates=ParameterEstimates;
proc nlmixed data=rescale1 maxiter=1000;
	by index;

	  /* right initial values? */
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

      predict p out=prediction_weibull_rs;
run;

ods listing;

proc transpose data=parameterestimates out=pe_t(drop=_LABEL_ where=(_NAME_="Estimate"));
   by index;
   id parameter;
run;

data bmd1;
	set pe_t;
	_x = -log(1 - 0.5);  /* BMR */
    _bmd = (_x / _bdose)**(1/_alpha);
run;

data bmd2;
	merge bmd1 maxdoses;
	by index;
	origBMD = _bmd*maxdose;
run;

/* BMD estimates are close to those from BMDS, except for N82750
      39.4576 in BMDS
	  28.96 in SAS (on original scale)

   This only fits Weibull, which wasn't a best model for any of the Army Data
*/

data qc;
	set data2;
	if index="N82750";
	prop = obs/n;
run;

proc sgplot data=qc;
   scatter x=dose y=prop;
run;

 data plot_model;
	  do dose1=0 to 50 by 0.5;
		  if dose1=0 then resp1=0.181792858;
		  else if dose1>0 then do;
	     	  resp1 = 0.181792858 + (1 - 0.181792858)*(1 - exp(-1*((1.1967442453/50) * (dose1**1))));
		  end;
		  output;
	  end;
   run;

   data plot;
      set qc plot_model;
	run;

   proc sgplot data=plot;
   scatter x=dose y=prop;
   series x=dose1 y=resp1 / markerattrs=(color=red);
run;
