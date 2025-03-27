/*/////////////////////////////////////////////////
///		Combine and check NanoGo database
///			Pieces assembled in Excel by ND and EK
///			
///				
/*/	

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\nanogo_db_02mar2016.xlsx" out=db1 dbms=excel; 
	sheet="Combined";
run;

data db2;
	set db1;

	format material $10.;

	if material="MWCN" then material="MWCNT";
run;


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\NanGo_InVivo_Physchem_data_03mar2016(excel).xlsx" out=pc1 dbms=excel;
	sheet="Restructure";
run;

data pc2;
	set pc1;

	format material $10.;

	if material="MWCN" then material="MWCNT";
run;

proc sort data=db2;  by study_key material material_type;  run;
proc sort data=pc2;  by study_key material material_type;  run;

data all1;
	merge db2 pc2;
	by study_key material material_type;
run;

proc export data=all1 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\NanoGo_Database_03mar2016.xlsx" dbms=excel replace;
run;
