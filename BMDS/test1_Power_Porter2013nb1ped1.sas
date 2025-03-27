/*  Implement a Continuous Model from BMDS 

	Porter et al. 2013 - NB1, 1 day post exposure
	Dose is ug/g lung (deposited dose)
	Response is PMN Proportion
*/

/*
	RESULTS
	=======
	05oct2016: parameter estimates match BMDS
*/

/*
	TO DO
	=====
	Quality of Life
		Plots
		Predictions
		Fit tests as in BMDS
			Test 1 - 4
				Fit other models for LL tests
		BMR input
		BMD/BMDL estimation

	Initialization
		Defaults?
			Pull MSE from PROC REG for sd?
			Overall SD from PROC MEANS?

	Other models
		Log normal option for models other than exponential?
*/

data dr1;
	input dose response;
	datalines;
	0	0.018867925
	0	0.006289308
	0	0.047619048
	0	0.016260163
	0	0.015625
	0	0
	0	0
	0	0.010309278
	50	0.056818182
	50	0.160377359
	50	0.173913044
	50	0.121794872
	50	0.133757962
	50	0.017142857
	50	0.073684211
	100	0.287179487
	100	0.346938776
	100	0.266129032
	100	0.297297297
	100	0.117318436
	100	0.075268817
	200	0.333333333
	200	0.655737705
	200	0.367741936
	200	0.352112676
	200	0.720670391
	200	0.423913044
	200	0.285714286
	;
run;

proc sgplot data=dr1;
	scatter x=dose y=response;
run;

proc means data=dr1 std;
	var response;
run;


/* 
	mock up the Power Model
		mean(dose) = gamma + beta*(dose)^delta
			background: 0 <= gamma <= 1
			slope:      0 <= beta
			power:      0 < delta <= 18  (default restriction >= 1 to eliminate infinite slope)
*/

proc nlmixed data=dr1;
	parms _gamma=0.2 _beta=0.5 _delta=1
		  sd=0.1952202; /*0.01  initialize SD using MSE from a simple linear regression?  ends up working well here */
		  				/* so does overall SD of response */

	bounds _gamma >= 0, _gamma <= 1, _beta >= 0, _delta >= 1, _delta <= 18;

	if dose>0 then do;
		mean = _gamma + _beta * (dose**_delta); /* model form */
	end;
	else if dose=0 then do; /* resolve execution errors */
		mean = _gamma;
	end;

	model response ~ normal(mean, sd); /* distributional assumption for response at each dose */

	predict mean out=dr1_pred;

	*ods output Fitting=dr1_fits;
run;

data dr1_pred;
	set dr1_pred;
	residual = response - pred;
run;

proc sgplot data=dr1_pred;
	scatter x=pred y=residual;
run;

data dr2;
	set dr1;

	dose2 = dose/200;
	resp2 = response/0.720670391;

	drop dose response;
run;
proc nlmixed data=dr2;
	parms _gamma=0.2 _beta=0.5 _delta=1
		  sd=0.1952202; /*0.01  initialize SD using MSE from a simple linear regression?  ends up working well here */
		  				/* so does overall SD of response */

	bounds _gamma >= 0, _gamma <= 1, _beta >= 0, _delta >= 1, _delta <= 18;

	if dose2>0 then do;
		mean = _gamma + _beta * (dose2**_delta); /* model form */
	end;
	else if dose2=0 then do; /* resolve execution errors */
		mean = _gamma;
	end;

	model resp2 ~ normal(mean, sd); /* distributional assumption for response at each dose */

	predict mean out=dr2_pred;

	ods output FitStatistics=dr2_fits;
run;
/* Rescale
		DoseT = Dose/Max Dose
		ResponseT = Response/Max Response

		Original Scale		Normalized Scale	Transformation
		--------------		----------------	--------------
		Gamma				GammaT				Gamma=(Max Response)*GammaT
		Beta				BetaT				Beta={(Max Response)/(Max Dose ^ Delta)} * BetaT
		Delta				DeltaT				Delta=DeltaT
*/


/*
	BMDS
	=====
                                 Parameter Estimates

                                                         95.0% Wald Confidence Interval
       Variable         Estimate        Std. Err.     Lower Conf. Limit   Upper Conf. Limit
          alpha       0.00911309       0.00243557          0.00433945           0.0138867
        control          0.01247        0.0330265          -0.0522608           0.0772008
          slope       0.00160518       0.00217396          -0.0026557          0.00586606
          power          1.05857         0.251692             0.56526             1.55187
*/

/*
	SAS
	====
								Parameter Estimates 
	Parameter 	Estimate 	Standard Error  
	_gamma 		0.01247 	0.03368  
	_beta 		0.001605 	0.002285  
	_delta 		1.0586 		0.2645  
	sd 			0.009113 	0.002436 
*/ 



proc nlmixed data=dr1;
	parms _beta0=0.5 _beta1=0.5 _beta2=0.5 _beta3=0.5 /* nothing higher than Poly3 fit */
		  sd=0.1; /* initialize SD using MSE from a simple linear regression?  ends up working well here */

	/*bounds NO BOUNDS*/

	if dose>0 then do;
		mean = _beta0 + _beta1*(dose) + _beta2*(dose**2) + _beta3*(dose**3);
	end;
	else if dose=0 then do;
		mean = _beta0;
	end;

	model response ~ normal(mean, sd);

run;













