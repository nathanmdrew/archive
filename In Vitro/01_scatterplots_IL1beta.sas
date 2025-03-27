/*///////////////////////////////////////////
///			In Vitro
///		February 14th, 2017
///
///		Create exploratory scatter plots
///		for the dose-response associations
///		in the ENPRA and NanoGo datasets.
///
///		Response = IL-1 Beta
///
///		Use these to choose BMR for modeling.
/*/

proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\db_IL1b_v1.xlsx" out=enpra1 dbms=excel;
	sheet="ENPRA";
run;

data enpra1;
	set enpra1;
	label dose="Dose (ug/cm2)"
		  response="IL-1 Beta (pg/mL)";
run;

ods graphics on;
ods pdf file="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\enpra_plots.pdf";
proc sgplot data=enpra1 (where=(case=7));
	title "ENPRA --- ZnO";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);
run;
proc sgplot data=enpra1 (where=(case=8));
	title "ENPRA --- Coated ZnO";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);;
run;
proc sgplot data=enpra1 (where=(case=9));
	title "ENPRA --- PC-MWCNT";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);;
run;
proc sgplot data=enpra1 (where=(case=10));
	title "ENPRA --- MWCNT";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);;
run;
proc sgplot data=enpra1 (where=(case=11));
	title "ENPRA --- Rutile TiO2 #1";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);;
run;
proc sgplot data=enpra1 (where=(case=12));
	title "ENPRA --- Rutile TiO2 #2";
	scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  markerattrs=(symbol=circlefilled size=13);;
run;
ods pdf close;


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\db_IL1b_v1.xlsx" out=ngo1 dbms=excel;
	sheet="NanoGo";
run;

data ngo1;
	set ngo1;
	label dose="Dose (ug/mL)"
		  response="IL-1 Beta (pg/mL)";
run;

proc sort data=ngo1 out=ngo_uniq(keep=case lab material) nodupkey;
	by case lab material;
run;

%macro ngo_plot();

   %do ii=1 %to 42;
		data temp;
			set ngo_uniq (firstobs=&ii. obs=&ii.);
			call symput('lab', compress(lab));
			call symput('material', material);
		run;

		proc sgplot data=ngo1(where=(case=&ii. AND lab=&lab. AND material="&material."));
			title "NanoGo --- Material=&material.  Lab#=&lab.";
			scatter x=dose y=response / filledoutlinedmarkers markerfillattrs=(color=blue) markeroutlineattrs=(color=black)
													  		  markerattrs=(symbol=circlefilled size=13);;
		run;

	%end;

%mend;

ods pdf file="Z:\MyLargeWorkspace Backup\ENM Categories\In Vitro\nanogo_plots.pdf";
%ngo_plot;
ods pdf close;
