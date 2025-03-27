/*/////////////////////////////////////////////////////////////////
///		Check if the 3 weird BMD cases even have a trend to model
///			Levene's test for homogeneity will be used
///			alpha = 0.05
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

* read in the dataset ;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\Data Correction\NIOSHdosedata_postexp_0_3_v3.csv" out=d1 dbms=csv replace;
run;

data d2;
	set d1;

	if study_key in (100013, 100012, 100016);

	if samppmnper NE 0 then log10_samppmnper = log10(samppmnper);
	if samppmnper = 0 then log10_samppmnper = log10(samppmnper + 0.0025/2);  * 0 response = 1/2 min response ;
run;

data d3;
	set d2;

	if dep_dose_amount2 < 500; *drop the positive control Silica group ;
run;




/*////////////////////////   Trend tests for 100012 //////////////////////////////*/

* --- Raw data --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100012_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100012)) plots=diagnostics;
	class dep_dose_amount2;
	model samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100012  CLDiffsInfo=Means2_100012;
quit;
ods pdf close;
ods graphics off;

* --- Log transformed response --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100012_T_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100012)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100012_T  CLDiffsInfo=Means2_100012_T;
quit;
ods pdf close;
ods graphics off;


* --- Log transformed response, no positive control --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100012_T_NoSil_Diagnostics.pdf";
proc glm data=d3 (where=(study_key=100012)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100012_T_NoSil  CLDiffsInfo=Means2_100012_T_NoSil;
quit;
ods pdf close;
ods graphics off;
**********  No trend exists *************** ;




/*////////////////////////   Trend tests for 100013 //////////////////////////////*/

* --- Raw data --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100013_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100013)) plots=diagnostics;
	class dep_dose_amount2;
	model samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100013  CLDiffsInfo=Means2_100013;
quit;
ods pdf close;
ods graphics off;

* --- Log transformed response --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100013_T_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100013)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100013_T  CLDiffsInfo=Means2_100013_T;
quit;
ods pdf close;
ods graphics off;


* --- Log transformed response, no positive control --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100013_T_NoSil_Diagnostics.pdf";
proc glm data=d3 (where=(study_key=100013)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100013_T_NoSil  CLDiffsInfo=Means2_100013_T_NoSil;
quit;
ods pdf close;
ods graphics off;
**********  No trend exists *************** ;







/*////////////////////////   Trend tests for 100016 //////////////////////////////*/

* --- Raw data --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100016_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100016)) plots=diagnostics;
	class dep_dose_amount2;
	model samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100016  CLDiffsInfo=Means2_100016;
quit;
ods pdf close;
ods graphics off;

* --- Log transformed response --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100016_T_Diagnostics.pdf";
proc glm data=d2 (where=(study_key=100016)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100016_T  CLDiffsInfo=Means2_100016_T;
quit;
ods pdf close;
ods graphics off;


* --- Log transformed response, no positive control --- ;
ods graphics on;
ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_100016_T_NoSil_Diagnostics.pdf";
proc glm data=d3 (where=(study_key=100016)) plots=diagnostics;
	class dep_dose_amount2;
	model log10_samppmnper = dep_dose_amount2;
	means dep_dose_amount2 / dunnett hovtest;
	ODS output CLDiffs=Means_100016_T_NoSil  CLDiffsInfo=Means2_100016_T_NoSil;
quit;
ods pdf close;
ods graphics off;
**********  No trend exists *************** ;







proc summary data=d1 nway;
	class casenumber;
	var samppmnper;
	where samppmnper>0;
	output out=summ1 (drop=_type_ _freq_) min()=minresp;
run;

data d4;
	merge d1(in=aa) summ1;
	by casenumber;
	if aa;

	if samppmnper NE 0 then log10_samppmnper = log10(samppmnper);
	if samppmnper = 0 then log10_samppmnper = log10(samppmnper + minresp/2);  * 0 response = 1/2 min response ;
run;


%macro trend();

	%do ii=1 %to 32;

		/* Raw Data */
		ods graphics on;
		ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_Case_&ii._Diagnostics.pdf";
		proc glm data=d4 (where=(CaseNumber=&ii.)) plots=diagnostics;
			class dep_dose_amount2;
			model samppmnper = dep_dose_amount2;
			means dep_dose_amount2 / hovtest;
			ODS output HOVFTest=HOV_Case_&ii. OverallANOVA=ANOVA_Case_&ii.;
		quit;
		ods pdf close;
		ods graphics off;

		proc sql noprint;
			select probf
			into :pval
			from HOV_Case_&ii.
			where source="dep_dose_amount2";

			select probf
			into :ftest
			from ANOVA_Case_&ii.
			where source="Model";
		quit;


		/* if HOV test fails, then try log transforming the response */
		%if &pval. < 0.05 %then %do;

			/* Log10 Transformed Response --- To get equal variances for ANOVA */
			ods graphics on;
			ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMR10\Study_Case_&ii._T_Diagnostics.pdf";
			proc glm data=d4 (where=(CaseNumber=&ii.)) plots=diagnostics;
				class dep_dose_amount2;
				model log10_samppmnper = dep_dose_amount2;
				means dep_dose_amount2 /  hovtest;
				ODS output HOVFTest=HOV_T_Case_&ii. OverallANOVA=ANOVA_T_Case_&ii.;
			quit;
			ods pdf close;
			ods graphics off;

			proc sql noprint;
				select probf
				into :pval2
				from HOV_T_Case_&ii.
				where source="dep_dose_amount2";

				select probf
				into :ftest2
				from ANOVA_T_Case_&ii.
				where source="Model";
			quit;

		%end;

		data trend_&ii. (drop=pvalcheck);
			casenumber=&ii.;
			
			HOVTest=&pval.;
			FTest="&ftest.";

			HOVTest_Transformed=&pval2.;
			FTest_Transformed="&ftest2.";
		run;

		data trends;
			set trends trend_&ii.;
		run;

	%end;

%mend;

data trends;
	casenumber=0;
	transform="N";
	HOVTest=0;
	FTest="test12345";
run;

%trend();



data trends2;
	set trends;

	transform="N";
	if hovtest < 0.05 then transform="Y";

	if ftest="<.0001" then ftest2=0.000099;
	else ftest2 = ftest*1;

	if FTest_Transformed="<.0001" then FTest_Transformed2=0.000099;
	else FTest_Transformed2 = FTest_Transformed*1;

	if casenumber=0 then delete;

run;

data trends3;
	set trends2;

	trend="N";
	if transform="N" and ftest2 < 0.05 then trend="Y";
	if transform="Y" and HOVTest_Transformed > 0.05 and FTest_Transformed2 < 0.05 then trend="Y";
run;

proc freq data=trends3;
	table trend;
run;

proc sort data=d1 out=d5(keep=casenumber study_key material material_type pe_d scale) nodupkey;
	by casenumber study_key material material_type pe_d scale;
run;

data d5;
	set d5;
	if material_type="control" then delete;
run;

data d6;
	merge d5 trends3;
	by casenumber;
run;

/* investigate some of the No Trends */
proc sgplot data=d1;
	where casenumber=31;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	where casenumber=31;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;
data qc;
	set d6;

	if transform="Y" and HOVTest_Transformed < 0.05;
run;
/* Fine TiO2 doesn't have equal variances, but there's a clear difference in mean response */



data d7;
	set d6;
	if casenumber=31 then trend="Y";
run;

data d4;
	set d4;

	label dep_dose_amount2 = "Deposited Dose (ug / g lung)"
		  samppmnper = "PMN Proportion"
		  log10_samppmnper = "log10(PMN Proportion)";
run;




proc sgplot data=d4;
	where casenumber=29;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	where casenumber=29;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;


proc sgplot data=d4;
	where casenumber=25;
	scatter x=dep_dose_amount2 y=samppmnper;
run;


/* Get plots for the write-up of 5 cases with a BMD, but no trend */
proc sgplot data=d4;
	title "100012 - Long MWCNT";
	title2 "Dose vs. Response";
	where casenumber=22;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	title "100012 - Long MWCNT";
	title2 "Dose vs. Transformed Response (log10)";
	where casenumber=22;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;



proc sgplot data=d4;
	title "100013 - Short MWCNT";
	title2 "Dose vs. Response";
	where casenumber=23;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	title "100013 - Short MWCNT";
	title2 "Dose vs. Transformed Response (log10)";
	where casenumber=23;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;



proc sgplot data=d4;
	title "100016 - Coated ZnO";
	title2 "Dose vs. Response";
	where casenumber=24;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	title "100016 - Coated ZnO";
	title2 "Dose vs. Transformed Response (log10)";
	where casenumber=24;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;



proc sgplot data=d4;
	title "100017 - Uncoated ZnO";
	title2 "Dose vs. Response";
	where casenumber=25;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	title "100017 - Uncoated ZnO";
	title2 "Dose vs. Transformed Response (log10)";
	where casenumber=25;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;



proc sgplot data=d4;
	title "100022 - Rutile TiO2";
	title2 "Dose vs. Response";
	where casenumber=29;
	scatter x=dep_dose_amount2 y=samppmnper;
run;
proc sgplot data=d4;
	title "100022 - Rutile TiO2";
	title2 "Dose vs. Transformed Response (log10)";
	where casenumber=29;
	scatter x=dep_dose_amount2 y=log10_samppmnper;
run;
