options nocenter nonumber nodate ls=80 mprint symbolgen formdlim="*";
/*options nocenter nonumber nodate ls=80 formdlim="*";*/


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

data out_weibull out_logistic out_log_logistic out_gamma out_linear out_probit out_log_probit
	 out_multistage2 out_multistage3 out_quadratic;
	set _NULL_;
run;

%include "Z:\BMDS in SAS\11_dichotomous_weibull_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_weibull, ESTIMATES=pe_weibull);

%include "Z:\BMDS in SAS\12_dichotomous_logistic_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_logistic, ESTIMATES=pe_logistic);

%include "Z:\BMDS in SAS\13_dichotomous_log_logistic_added.sas";
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_log_logistic, ESTIMATES=pe_loglogistic);

%include "Z:\BMDS in SAS\14_dichotomous_gamma_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_gamma, ESTIMATES=pe_gamma);

%include "Z:\BMDS in SAS\15_dichotomous_linear_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_linear, ESTIMATES=pe_linear);

%include "Z:\BMDS in SAS\16_dichotomous_probit_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_probit, ESTIMATES=pe_probit);

%include "Z:\BMDS in SAS\17_dichotomous_log_probit_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_log_probit, ESTIMATES=pe_logprobit);

%include "Z:\BMDS in SAS\18_dichotomous_multistage2_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_multistage2, ESTIMATES=pe_ms2);

%include "Z:\BMDS in SAS\19_dichotomous_multistage3_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_multistage3, ESTIMATES=pe_ms3);

%include "Z:\BMDS in SAS\155_dichotomous_quadratic_added.sas"; 
%boundBMD(BMR=0.1, CL=0.95, DATAIN=dataset, DATAOUT=out_quadratic, ESTIMATES=pe_quadratic);

data out_all;
	format ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
	informat ChiSq best12. GoF_pvalue best12. AIC best12. BMR best12. BMD best12. BMDL best12. Model $17. Risk $5.;
	set out_weibull out_logistic out_log_logistic out_gamma out_linear out_probit out_log_probit out_multistage2 out_multistage3 out_quadratic;
run;
proc sort data=out_all out=out_all2;
	where GoF_pvalue > 0.1;
	by AIC;
run;
proc print data=out_all2;
run;

/* MADr BMD:  1.050778866746
   MADr BMDL: 0.285140122287
*/

%include "Z:\MyLargeWorkspace Backup\BMDS in SAS\20_model_averaging_added.sas";
%modelaverage(datain=dataset, maxiterations=60, convergence=0.00001, bmr=0.1, dataout=out_modelavg,
			  weibull=1, logistic=0, loglogistic=0, gamma=0, linear=0, probit=0, logprobit=1, ms2=1, ms3=0, quadratic=0,
			  pe_weibull=pe_weibull, pe_logistic=, pe_log_logistic=, pe_gamma=, pe_linear=, 
			  pe_probit=, pe_log_probit=pe_logprobit, pe_ms2=pe_ms2, pe_ms3=, pe_quadratic=,
			  all_results=out_all);


data out_all3;
	set out_all2 out_modelavg;
run;



libname samps "Z:\MyLargeWorkspace Backup\BMDS in SAS\Bootstrap Samples Added"; /* houses the bootstrap datasets */

%include "Z:\MyLargeWorkspace Backup\BMDS in SAS\21_model_averaging_added_BMDL_percentile.sas";

proc printto log="Z:\MyLargeWorkspace Backup\BMDS in SAS\Bootstrap Samples Added\BMDL_Log.txt" NEW;
run;
%let datetime_start = %sysfunc(TIME()) ;
%put START TIME: %sysfunc(datetime(),datetime14.);

%modelavg_BMDL_percentile(datain=dataset, num_samples=2000, BMR=0.1, CL=0.95, maxiterations=100, convergence=0.00001,
			  			weibull=1, logistic=0, loglogistic=0, gamma=0, linear=0, probit=0, logprobit=1, ms2=1, ms3=0, quadratic=0,
						all_results=out_all, pe_weibull=pe_weibull, pe_logistic=, pe_log_logistic=, pe_gamma=, pe_linear=, 
			  		    pe_probit=, pe_log_probit=pe_logprobit, pe_ms2=pe_ms2, pe_ms3=, pe_quadratic=);

%put END TIME: %sysfunc(datetime(),datetime14.);
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss) ;
proc printto log=log;
run;
%put PROCESSING TIME:  %sysfunc(putn(%sysevalf(%sysfunc(TIME())-&datetime_start.),mmss.)) (mm:ss) ;
