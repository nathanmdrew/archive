/* try a continuous BMDS model - Exp5 */
/* constant variance and nonconstant variance */

data d1 (type=corr);
   input _type_ $ _name_ $ dose pmn;
   datalines;
   mean . 0.0005143 15.29572
   std  . 0.0004646 17.28534
   n    . 25        25
   corr dose 1 0.89308
   corr pmn 0.89308 1
;
run;
 
 data temp;
    do i=1 to 5;
	   dose=0;
	   pmn = rand("Normal", 1.41, 0.704);
	   output;

	   dose=0.0002005;
	   pmn = rand("Normal", 4.58, 2.46);
	   output;

	   dose=0.0004423;
	   pmn = rand("Normal", 9.15, 6.34);
	   output;

	   dose=0.0006015;
	   pmn=rand("Normal", 24, 7.39);
	   output;

	   dose=0.001327;
	   pmn=rand("Normal", 47.5, 8.1);
	   output;
	end;
run;

proc sort data=temp (drop=i);
   by dose;
run;

proc sgplot data=temp;
   scatter x=dose y=pmn;
run;

proc corr data=temp;
   var dose pmn;
run;


proc nlin data=temp maxiter=1000;
	  parms _a=1
			_b=100
			_c=12
			_d=2;

	  bounds _a>0,
	         _b>0,
			 _c>1,
			 _d>1;

      _mean  = _a;

      if (dose > 0) then do;
         _mean = _a*(_c - (_c-1)*exp(-1 * (_b*dose)**_d) );
      end;


	  /* BMD for BMR=Abs Dev of 4 */
	  /* invert the model formula and solve for BMD ->  BMR ~ exp5(BMD) */
	  _expo=1/_d;
      _BMD1 =  ( (-1)*log((1/(_c-1)) * (_c - (_a+4)/_a)) );
      _BMD2 = _BMD1**_expo;
      _BMD = _BMD2/_b;
	  call symput("BMD", _bmd);

      model pmn = _mean;

      output predicted=prediction_exp5;
run;

%put BMD is &BMD.;

data test;
   _a=2.3744;
   _b=1483.0;
   _c=18.1421;
   _d=4.5657;

   do dose=0 to 0.001327 by 0.00001;
       pmn = _a*(_c - (_c-1)*exp(-1 * (_b*dose)**_d) );
	   output;
   end;
run;

data plot;
	set temp (rename=(pmn=pmn1 dose=dose1)) test (rename=(pmn=pmn2 dose=dose2));
run;

proc sgplot data=plot;
   scatter x=dose1 y=pmn1;
   series x=dose2 y=pmn2;
run;



/* nonconstant variance */
/* sigma2(i) = alpha * mean(dosei)^rho */
proc nlin data=temp maxiter=1000;
	  parms _a=1
			_b=100
			_c=12
			_d=2
			_alpha=1
			_rho=1;

	  bounds _a>0,
	         _b>0,
			 _c>1,
			 _d>1,
			 _alpha>0,
			 _rho>0;

      _mean  = _a;

      if (dose > 0) then do;
         _mean = _a*(_c - (_c-1)*exp(-1 * (_b*dose)**_d) );
      end;


	  /* BMD for BMR=Abs Dev of 4 */
	  /* invert the model formula and solve for BMD ->  BMR ~ exp5(BMD) */
	  _expo=1/_d;
      _BMD1 =  ( (-1)*log((1/(_c-1)) * (_c - (_a+4)/_a)) );
      _BMD2 = _BMD1**_expo;
      _BMD = _BMD2/_b;
	  call symput("BMD", _bmd);

	  _weight_ = _alpha*(_mean**_rho);

      model pmn = _mean;
run;

/* try nlmixed
   https://blogs.sas.com/content/iml/2017/06/14/maximum-likelihood-estimates-in-sas.html
   define LL and use GENERAL distribution
*/
