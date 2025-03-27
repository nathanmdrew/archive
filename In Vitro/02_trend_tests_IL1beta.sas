/*/////////////////////////////////////////
///		in vitro NanoGo Trend Tests
///			Endpoint: IL-1 Beta
///			Cell Line: THP-1
///			Multiple materials, labs
///
/*/

options nocenter nonumber nodate ls=80 formdlim="*" symbolgen mprint;

proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\db_IL1b_v1.xlsx" out=nanogo1 dbms=excel;
	sheet="NanoGo";
run;

data nanogo1;
	set nanogo1;
	label dose="Dose (ug/cm2)"
		  response="IL-1 Beta (pg/mL)";
	rename case=casenumber;
run;

proc means data=nanogo1;
	var response;
run;
/* no responses of 0 */

data temp(keep=probf ind);
	set hov_case_1 - hov_case_42;
	if source="dose";
	if probf<0.05 then ind="TRANSFORM";
run;
/* 2 will need transformed */

%macro trend(dose=, response=, outdir=, datain=, casenum=);
	/*/////////////////////////////////
	///		Macro Variables
	///			dose: independent var of interest
	///			response: dependent var of interest *** make sure a log10 transformation would be valid ***
	///			outdir: directory for output of PDF plots, fits, etc.  *** make sure this exists ***
	///			datain: input dataset to run tests on, contains dose-response by case number
	///			casenum: case number variable from the dataset in DATAIN *** cannot be called CASE ***
	/*/

	data &datain.;
		set &datain.;
		tresponse = log10(&response.);
	run;

	data trends;
		set _NULL_;
	run;

	proc sql noprint;
		select max(&casenum.)
		into :num_cases
		from &datain.;
	quit;

	%do ii=1 %to &num_cases;

		

		/* Raw Data */
		/* 		Get ANOVA p-value and HoV p-value */
		/*    		All is good if ANOVA < 0.05 & HoV > 0.05   */
		ods graphics on;
		ods pdf file="&outdir.\Case_&ii._Diagnostics.pdf";
		proc glm data=&datain. (where=(casenumber=&ii.)) plots=diagnostics;
			class &dose.;
			model &response. = &dose.;
			means &dose. / hovtest;
			ODS output HOVFTest=HOV_Case_&ii. OverallANOVA=ANOVA_Case_&ii.;
		quit;
		ods pdf close;
		ods graphics off;
	

		/* Extract p-values for ANOVA and HoV */
		proc sql noprint;
			select probf
			into :pval
			from HOV_Case_&ii.
			where source="&dose.";

			select probf
			into :ftest
			from ANOVA_Case_&ii.
			where source="Model";
		quit;

		%if &pval=. %then %do;
			%let pval=0;
		%end;

		%if &pval. < 0.05 %then %do; 
			/* Log10 Transformed Data */
			/* 		Get ANOVA p-value and HoV p-value */
			/*    		All is good if ANOVA < 0.05 & HoV > 0.05   */
			ods graphics on;
			ods pdf file="&outdir.\Case_&ii._T_Diagnostics.pdf";
			proc glm data=&datain. (where=(casenumber=&ii.)) plots=diagnostics;
				class &dose.;
				model tresponse = &dose.;
				means &dose. / hovtest;
				ODS output HOVFTest=HOV_T_Case_&ii. OverallANOVA=ANOVA_T_Case_&ii.;
			quit;
			ods pdf close;
			ods graphics off;

			proc sql noprint;
				select probf
				into :pval2
				from HOV_T_Case_&ii.
				where source="&dose.";

				select probf
				into :ftest2
				from ANOVA_T_Case_&ii.
				where source="Model";
			quit;
			
		%end;

		data trend_&ii.;
			casenumber=&ii.;
			
			HOVTest="&pval.";
			FTest="&ftest.";

			HOVTest_Transformed="&pval2.";
			FTest_Transformed="&ftest2.";
		run;

		data trends;
			set trends trend_&ii.;
		run;

	%end;

%mend;

%trend(dose=dose, response=response, outdir=Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\IL1B Trend Diagnostics, 
	   datain=nanogo1, casenum=casenumber);


data trends2 (keep=casenumber hov1 ftest1 hov2 ftest2);
	set trends;

	if HOVTest_Transformed="&pval2." then HOVTest_Transformed="0";
	if FTest_Transformed="&ftest2." then FTest_Transformed="0";
	if FTest="<.0001" then FTest=0.00009;
	if HOVTest_Transformed="." then HOVTest_Transformed="0";
	if FTest_Transformed="<.0001" then FTest_Transformed=0.00009;

	hov1=hovtest*1;
	ftest1=FTest*1;
	hov2=HOVTest_Transformed*1;
	ftest2=FTest_Transformed*1;
run;


data trends3;
	set trends2;
	transformed="N";
	trend="N";
	

	if HOV1 < 0.05 then transformed="Y";

	if HOV1 > 0.05 AND FTest1 < 0.05 then trend="Y";
	if HOV1 < 0.05 AND HOV2 > 0.05 and FTest2 < 0.05 then trend="Y";	
run;

proc export data=trends3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\IL1B Trend Diagnostics\trend_summary.xlsx" dbms=excel;
run;
	
