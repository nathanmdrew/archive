/* transform BMDLs, NOAELs to meet OEB guidelines */

options nocenter nonumber nodate ls=80 mprint symbolgen;

proc import datafile="\\cdc.gov\project\NIOSH_EID_NanoRA\CatOEL Data\NTP\Results\_bmd_summary_02OCT2018.xlsx" out=bmd_infl dbms=excel;
   sheet="Inflammation";
run;


proc import datafile="\\cdc.gov\project\NIOSH_EID_NanoRA\CatOEL Data\NTP\Results\_bmd_summary_02OCT2018.xlsx" out=bmd_neo dbms=excel;
   sheet="Lung Cell Neoplasia";
run;


proc import datafile="\\cdc.gov\project\NIOSH_EID_NanoRA\CatOEL Data\NTP\Results\!DRAFT infl_noael_loael - Table 4a.xlsx" out=nolo_infl dbms=excel;
   sheet="FINAL2";
run;

proc import datafile="\\cdc.gov\project\NIOSH_EID_NanoRA\CatOEL Data\NTP\Results\!DRAFT infl_noael_loael - Table 4a.xlsx" out=_index1 dbms=excel;
   sheet="Index Matches";
run;


proc import datafile="\\cdc.gov\project\NIOSH_EID_NanoRA\CatOEL Data\NTP\Results\!DRAFT lungneo_noael_loael_2 - Table 4b.xlsx" out=nolo_neo dbms=excel;
   sheet="FINAL2";
run;



/* First convert mg/m3 to ug/m3 (ignore PPM, same groupings) = *1000 */
/* then take NOAEL or BMDL, divide by 3 IF 28-90 day --- above 90 day remains unchanged */
/* A: >30000   B: 3000-30000   C: 300-3000   D: 30-300   E: <30 */

proc sort data=bmd_infl out=qc1 (keep=duration) nodupkey;
   by duration;
run;

/* fix this */
data bmd_infl2;
	set bmd_infl;

	if bmd_unit="mg/m3" AND duration in ("16 day", "2 week", "2week", "30 day") then do;
		bmdl_adj = bmdl/3 * 1000;
		bmdl_adj_units = "ug/m3";
	end;
	else do;
		bmdl_adj = bmdl * 1000;
		bmdl_adj_units = "ug/m3";
	end;

	* reverse PPM adjustment - ppm ~= ug/m3 ;
	if bmd_unit="ppm" AND duration in ("16 day", "2 week", "2week", "30 day") then do;
		bmdl_adj = bmdl/3;
		bmdl_adj_units = "ppm";
	end;


run;
