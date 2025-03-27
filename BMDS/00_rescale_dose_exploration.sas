/* rescale data */
/*   see if model fitting improves (converges, speed, etc.)
	 see if original scale BMD can be recovered */

data dataset;
   input index dose obs n;
   datalines;
   1 0.0 2 10
   1 0.5 2 10
   1 1.0 2 10
   1 2.0 6 10
   1 4.0 9 10
   ;
run;


proc sql;
	select max(DOSE)
	into :maxdose
	from DATASET;
quit;

data rescale1;
	set dataset;
	DOSE_rescale = dose/&maxdose.;
	drop dose;
	rename dose_rescale=dose;
run;



/* original scale */
proc nlmixed data=dataset maxiter=1000;
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

      predict p out=prediction_weibull;
   run;

   %put BMD = &BMD.;
   /* BMD = 0.8776287941*/

/* rescaled */
proc nlmixed data=rescale1 maxiter=1000;
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
   /* converged faster (11 vs 14 steps) */

     %put Rescale BMD = &BMD.;
	 /* Rescale BMD = 0.2194067738 */
	data _null_;
		file print;
		x = &bmd.;
		y = x*&maxdose.;
		put y;
	run;
/* 0.8776270952   */
	/* correct to 5 places */



/* Conclusion
	For this one case, Weibull model fitting was faster on the rescaled data (not noticeable in this one case, but saved time would
	likely accumulate when fitting many cases/models per case)

	The original scale BMD was mostly recovered by transforming the rescaled BMD by a factor of the largest dose, to 5 decimal places.

	Why isn't it 1-to-1?
*/
