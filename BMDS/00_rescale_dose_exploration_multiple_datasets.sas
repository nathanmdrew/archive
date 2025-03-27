/* rescale data where multiple datasets are used/BY modeling */



data dataset;
   input index dose obs n;
   datalines;
   1 0.0 2 10
   1 0.5 2 10
   1 1.0 2 10
   1 2.0 6 10
   1 4.0 9 10
   2 0.0 0 10
   2 2.0 0 10
   2 4.0 1 10
   2 8.0 8 10
   2 10.0 10 10
   ;
run;

proc sql;
	create table maxdoses as
	select index, 
           max(DOSE) as maxdose
	from DATASET
	group by index
	;
quit;

data rescale1;
	merge dataset maxdoses;
	by index;
	DOSE_rescale = dose/maxdose;
	drop dose;
	rename dose_rescale=dose;
run;

ods listing close; 
   ods output fitstatistics = fitstatistics
              ParameterEstimates=ParameterEstimates;
proc nlmixed data=dataset maxiter=1000;
	by index;

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
	   /*
      _x = -log(1 - 0.1);
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);
	  */

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull;
   run;
   ods listing;


proc transpose data=parameterestimates out=pe_t_orig(drop=_LABEL_ where=(_NAME_="Estimate")); /*(rename=(COL1=_gamma COL2=_bdose;*/
   by index;
   id parameter;
run;
data bmd_orig;
	set pe_t_orig;
	_x = -log(1 - 0.1);  /* BMR */
    _bmd = (_x / _bdose)**(1/_alpha);
run;





/* rescaled */
ods listing close; 
   ods output fitstatistics = fitstatistics
              ParameterEstimates=ParameterEstimates;
proc nlmixed data=rescale1 maxiter=1000;
	by index;

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
      _x = -log(1 - 0.1);
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull_rs;
   run;
      ods listing;

	proc transpose data=parameterestimates out=pe_t(drop=_LABEL_ where=(_NAME_="Estimate")); /*(rename=(COL1=_gamma COL2=_bdose;*/
   by index;
   id parameter;
run;
data bmd1;
	set pe_t;
	_x = -log(1 - 0.1);  /* BMR */
    _bmd = (_x / _bdose)**(1/_alpha);
run;

data bmd2;
	merge bmd1 maxdoses;
	by index;
	origBMD = _bmd*maxdose;
run;




/* speed */
proc nlmixed data=dataset maxiter=1000;
	by index;

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
   /* index 1 - 14 steps */
   /* index 2 - 30 steps */


proc nlmixed data=rescale1 maxiter=1000;
	by index;

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
   /* index 1 - 11 steps */
   /* index 2 - 11 steps */
   /* rescaling saved 3+19 = 22 steps --- neat */
