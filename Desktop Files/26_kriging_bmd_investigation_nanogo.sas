/*/////////////////////////////////////////////////////////////////
///		Check if the 3 weird BMD cases even have a trend to model
///			Levene's test for homogeneity will be used
///			alpha = 0.05
/*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

* read in the dataset ;
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\BMR BG plus 4 pct\NanoGo.csv" out=d1 dbms=csv replace;
run;


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

	%do ii=1 %to 36;

		/* Raw Data */
		ods graphics on;
		ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMRbg4\NanoGo\Trend Diagnostics\Study_Case_&ii._Diagnostics.pdf";
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
		/* %if &pval. < 0.05 %then %do; */

			/* Log10 Transformed Response --- To get equal variances for ANOVA */
			ods graphics on;
			ods pdf file="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMRbg4\NanoGo\Trend Diagnostics\Study_Case_&ii._T_Diagnostics.pdf";
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

		/* %end; */

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

/* add case 9 back in, p-value was <0.0001 so the format didnt match and didnt merge */
data qc;
	casenumber=9;
	hovtest=0.0001;
	ftest="0.0550";
	hovtest_transformed=0.1144;
	ftest_transformed="0.2637";
run;

data trends;
	set trends qc;
run;

proc sort data=trends;
	by casenumber;
run;

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





proc sort data=d1 out=d5(keep=casenumber study_key studyref material material_type pe_d scale) nodupkey;
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
%macro trendplots;

	data tp1 (keep=casenumber);
		set trends3;
		if trend="N";
	run;

	proc sql noprint;
		select count(casenumber)
		into :counter
		from tp1;
	quit;
	
	%do kk=1 %to &counter.;
		data _null_;
			set tp1 (firstobs=&kk. obs=&kk.);

			call symput('current_num', casenumber);
		run;

		proc sgplot data=d1 (where=(casenumber=&current_num.));
			title "Visual Trend Check for Case Number &current_num.";
			scatter x=dep_dose_amount2 y=samppmnper;
		run;
	%end;

%mend;

%trendplots;


/*  all 12 cases with no trend also visually appear to lack a trend */

proc export data=d6 outfile="C:\Users\vom8\Desktop\Stuff\86case code\86case code\32 Case Output BMRbg4\NanoGo\Trend Tests.xlsx" dbms=excel replace;
run;

