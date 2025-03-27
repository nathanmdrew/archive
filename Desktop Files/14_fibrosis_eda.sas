options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


data fibrosis1;
	set storage2.db30;

	if (fibrosis_dist_score ne .) or (fibrosis_severity_score ne .) or (fibrosis_composite_score ne .);
run;

proc freq data=fibrosis1 noprint;
   table fibrosis_dist_score   / missing list out=freqs1;
   table fibrosis_severity_score  / missing list out=freqs2;
   table fibrosis_composite_score / missing list out=freqs3;
run;

proc export data=storage2.db30 outfile="C:\Users\vom8\Desktop\Complete Rodent in vivo database 25nov2015.csv" dbms=csv;
run;
