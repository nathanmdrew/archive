options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";

data db1;
	set storage2.skeleton_pchem1_v4;
	*if pe_d <= 3;
run;

/*
•	Lengths added to ENPRA-RIVM Short and Long MWCNT in the NIOSH/CIIT/ENPRA database 
o	Same material as ENPRA-NRCWE Short and Long MWCNT, which did report length
*/


data db2;
	set db1;

	if structural_form = "Fiber-like" then structural_form = "Belt";

	if material_type = "NS" then do;
		length = diameter/1000;
		length_units = "um";
	end;

	if studyref="ENPRA-RIVM" and material="MWCNT" and material_type="long" then do;
		length = 20;
		length_units= "um";
	end;

	if studyref="ENPRA-RIVM" and material="MWCNT" and material_type="short" then do;
		length=5;
		length_units="um";
	end;
run;

data storage2.skeleton_pchem1_v5;
	set db2;
run;
