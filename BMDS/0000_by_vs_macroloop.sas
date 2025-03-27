data one;
   input dose obs n;
   datalines;
   0.0 2 10
   0.5 2 10
   1.0 2 10
   2.0 6 10
   4.0 9 10
   ;
run;

data two;
   input dose obs n;
   datalines;
   0 5 50
   1 10 50
   2 10 50
   ;
run;

data three;
   input dose obs n;
   datalines;
   0 3 100
   0 1 217
   0 2 79
   0 0 77
   0.02 2 100
   0.03 2 71
   0.07 1 75
   0.18 1 75
   0.28 0 74
   1.16 13 74
   1.20 12 77
   1.31 19 100
   ;
run;

data all;
	set one(in=aa) two(in=bb) three(in=cc);
	if aa then casenum=1;
	if bb then casenum=2;
	if cc then casenum=3;
run;





%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

proc nlmixed data=one maxiter=1000;
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
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull;
run;
data bmd1;
   bmd = &bmd.;
run;
proc nlmixed data=two maxiter=1000;
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
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull;
run;
data bmd2;
   bmd = &bmd.;
run;
proc nlmixed data=three maxiter=1000;
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
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);

      predict p out=prediction_weibull;
run;
data bmd3;
   bmd = &bmd.;
run;
data bmdall;
	set bmd1 bmd2 bmd3;
	casenum=_N_;
run;
%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;



%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

ods output ParameterEstimates(match_all)=pe_
			FitStatistics(match_all)=fitstats_;
proc nlmixed data=all maxiter=1000;

	 by casenum;

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

      predict p out=prediction_weibull;
run;

data pe_all;
	set pe_ pe_1 pe_2;
run;
proc transpose data=pe_all(keep=casenum parameter estimate) out=pe_all_t (drop=_NAME_);
   by casenum;
   id parameter;
run;
data pe_all_t2;
	set pe_all_t;
	bmd = ((-log(1 - (0.1/(1 - _gamma)))) / _bdose)**(1/_alpha);
run;

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;





libname samps "Z:\MyLargeWorkspace Backup\BMDS in SAS\Bootstrap Samples"; /* houses the bootstrap datasets */
data allsamps;
	set samps.bootstrap_sample1-samps.bootstrap_sample500;
	casenum=ceil(_N_/5);
run;


options nocenter nonumber nodate nonotes ls=80 formdlim="*";

%macro indiv;

	%do ii=1 %to 500;
		ods listing close;
	  ods exclude all;
	  ods noresults;
	  proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose > 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**_alpha);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);
      run;

	  ods results;
	  ods exclude none;
      ods listing;

      data bmd&ii.;
         bmd = &bmd.;
      run;

	%end;

	data bmdall_indiv;
		set bmd1-bmd500;
	run;

	proc datasets;
		delete bmd1-bmd500;
	quit;

%mend;


%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

%indiv;

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;

/* 36 seconds */



%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

ods listing close;
	  ods exclude all;
	  ods noresults;
ods output ParameterEstimates(match_all)=pe_;
proc nlmixed data=allsamps maxiter=1000;

	 by casenum;

      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose > 0;
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

data pe_all;
	set pe_ pe_1-pe_499;
run;
proc datasets;
	delete pe_ pe_1-pe_499;
quit;
proc transpose data=pe_all(keep=casenum parameter estimate) out=pe_all_t (drop=_NAME_);
   by casenum;
   id parameter;
run;
data bmdall_by;
	set pe_all_t;
	bmd = ((-log(1 - (0.1/(1 - _gamma)))) / _bdose)**(1/_alpha);
run;

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;
/* 4 seconds */





ods output ParameterEstimates=pe6;
proc nlmixed data=samps.bootstrap_sample6 maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose > 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**_alpha);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);
      run;

      data bmd6;
         bmd = &bmd.;
      run;
	  proc transpose data=pe6(keep=parameter estimate) out=pe6_t (drop=_NAME_);
	id parameter;
run;
data bmd6_by;
	set pe6_t;
	bmd = ((-log(1 - (0.1/(1 - _gamma)))) / _bdose)**(1/_alpha);
run;


data qc;
	merge bmdall_by (rename=(bmd=bmd_by)) bmdall_indiv (rename=(bmd=bmd_indiv));
run;










data allsamps;
	set samps.bootstrap_sample1-samps.bootstrap_sample2000;
	casenum=ceil(_N_/5);
run;


options nocenter nonumber nodate nonotes ls=80 formdlim="*";

%macro indiv;

	%do ii=1 %to 2000;
		ods listing close;
	  ods exclude all;
	  ods noresults;
	  proc nlmixed data=samps.bootstrap_sample&ii. maxiter=1000;
      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose > 0;
      p = _gamma;
      if (dose > 0) then do;
         _link = _bdose * (dose**_alpha);
	     p = _gamma + (1 - _gamma)*(1 - exp(-_link));
      end;
      _x = -log(1 - (0.1/(1 - _gamma)));
      _bmd = (_x / _bdose)**(1/_alpha);
      call symput("BMD", _bmd);

      model obs ~ binomial(n, p);
      run;

	  ods results;
	  ods exclude none;
      ods listing;

      data bmd&ii.;
         bmd = &bmd.;
      run;

	%end;

	data bmdall_indiv;
		set bmd1-bmd2000;
		casenum=_N_;
	run;

	proc datasets;
		delete bmd1-bmd2000;
	quit;

%mend;


%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

%indiv;

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;

/* 2 min 28 seconds */



%let datetime_start_BMDL = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

ods listing close;
	  ods exclude all;
	  ods noresults;
ods output ParameterEstimates(match_all)=pe_;
proc nlmixed data=allsamps maxiter=1000;

	 by casenum;

      parms _gamma = 0.006 
            _bdose = 0.5 
            _alpha=1;
      bounds _gamma >= 0,
             _gamma <= 1,
		     _alpha >= 1,
			 _alpha <= 18,
		     _bdose > 0;
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

data pe_all;
	set pe_ pe_1-pe_1999;
run;
proc datasets;
	delete pe_ pe_1-pe_1999;
quit;
proc transpose data=pe_all(keep=casenum parameter estimate) out=pe_all_t (drop=_NAME_);
   by casenum;
   id parameter;
run;
data bmdall_by;
	set pe_all_t;
	bmd = ((-log(1 - (0.1/(1 - _gamma)))) / _bdose)**(1/_alpha);
run;

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start_BMDL.),mmss.)) (mm:ss) ;
/* 18 seconds */
