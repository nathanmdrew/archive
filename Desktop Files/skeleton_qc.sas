data qc;
   set skeleton;

   if pmncount=.;
run;
/* looks good */

proc univariate data=skeleton;
   var pmncount;
   histogram pmncount;
run;

data qc;
	set skeleton;

	if pmncount >= 41538000;
run;
/* porter 97 very high, EDK mentioned coulter count problem */

data skeleton;
	set skeleton;

	pmncount_transf = log(pmncount);
	pmncount_transf2 = log10(pmncount);
run;
/* response is Norm, see how residuals look */

proc univariate data=skeleton;
   var pmncount_transf;
   histogram pmncount_transf;
run;


proc univariate data=skeleton;
   var samppmnper;
   histogram samppmnper;
run;
proc univariate data=skeleton;
   var samppmnper_transf;
   histogram samppmnper_transf;
run;
data qc;
	set skeleton;
	if samppmnper > .9;
run;


/****************
  some differences in NOAELs & LOAELS between the 2 responses
     Questions:
		How to relatively rank NOAELs LOAELs of responses, LN(responses), BMDs, maybe LN(BMDs)?
		
*****************/
data data_1_t;
	set data_1;
	pmncount_transf = log(pmncount);
	pmncount_transf2 = log10(pmncount);
	dose_transf = log10(dep_dose_amount2+1);
	dose_transf2 = sqrt(dep_dose_amount2);
	samppmnper_transf = log10(samppmnper+(0.0062893082/2));
run;
proc univariate data=data_1_t;
   var samppmnper;
   histogram samppmnper;
run;
proc gplot data=data_1_t;
   plot samppmnper * dep_dose_amount2;
run;
proc univariate data=data_1_t;
   var samppmnper_transf;
   histogram samppmnper_transf;
run;
proc gplot data=data_1_t;
   plot samppmnper_transf * dep_dose_amount2;
run;

title ;
ods graphics on;
proc glm data=data_1 plots=diagnostics;
			    class dep_dose_amount2;
				model pmncount = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
/* nonconst var, also supported by Levene's test */

ods graphics on;
proc glm data=data_1 plots=diagnostics;
			    class dep_dose_amount2;
				model pmncount_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
/* LN transform looks much better --- residuals are roughly uniform */
ods graphics on;
proc glm data=data_1 plots=diagnostics;
			    class dep_dose_amount2;
				model pmncount_transf2 = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
/* log10 also looks good w.r.t. constant variance */
/* Levene's test supports homogeneous variances */

/* what if we transform DOSE?  may be able to interpret/back transform easier */
ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dose_transf;
				model samppmnper = dose_transf;
				means dose_transf / dunnett hovtest;
				*ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dose_transf2;
				model samppmnper = dose_transf2;
				means dose_transf2 / dunnett hovtest;
				*ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;


ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				*ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
/* nonconst var */
ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				*ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;



ods graphics on;
ods pdf file="Y:\ENM Categories\DB\noael_loael_diagnostics\Data1_Diagnostics.pdf";
proc glm data=data_1 plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett hovtest;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods pdf close;
ods graphics off;

proc means data=data_1 min;
	where samppmnper>0;
	var samppmnper;
run;
data data_1_t;
	set data_1;
	samppmnper_transf = log(samppmnper + (0.0062893/2)); * add 1/2 min value, alleviates zeroes? ;
run;
ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;
/* residuals may not be quite normal */
data data_1_t;
	set data_1;
	samppmnper_transf = log(samppmnper + 1)); * add 1, 0's stay zero, ;
run;
ods graphics on;
proc glm data=data_1_t plots=diagnostics;
			    class dep_dose_amount2;
				model samppmnper_transf = dep_dose_amount2;
				means dep_dose_amount2 / dunnett;
				ODS output CLDiffs=qc_Means_1  CLDiffsInfo=qc_Means2_1;
			quit;
ods graphics off;





proc sgplot data=skeleton;
	title "Bermudez Fine TiO2 - Dose vs. PMN Proportion";
	where study_key in ("100024");
	scatter x=dep_dose_amount2 y=samppmnper / group=study_key;
run;
proc sgplot data=skeleton;
	title "Bermudez Fine TiO2 - Dose vs. Total PMN Count";
	where study_key in ("100024");
	scatter x=dep_dose_amount2 y=pmncount / group=study_key;
run;
proc sgplot data=skeleton;
	title "Bermudez Fine TiO2 - Dose vs. Total PMN Count, LN Transformed";
	where study_key in ("100024");
	scatter x=dep_dose_amount2 y=pmncount_transf / group=study_key;
run;


proc sgplot data=skeleton;
	title "Bermudez Ultrafine TiO2 - Dose vs. PMN Proportion";
	where study_key in ("100025");
	scatter x=dep_dose_amount2 y=samppmnper / group=study_key;
run;
proc sgplot data=skeleton;
	title "Bermudez Ultrafine TiO2 - Dose vs. Total PMN Count";
	where study_key in ("100025");
	scatter x=dep_dose_amount2 y=pmncount / group=study_key;
run;
proc sgplot data=skeleton;
	title "Bermudez Ultrafine TiO2 - Dose vs. Total PMN Count, LN Transformed";
	where study_key in ("100025");
	scatter x=dep_dose_amount2 y=pmncount_transf / group=study_key;
run;
