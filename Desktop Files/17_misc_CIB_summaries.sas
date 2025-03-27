options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
*libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";


/* Data Summary Tables */
proc freq data=storage2.skeleton_pchem1_v2_impute noprint;
	table study_key* studyref * route * species * material * material_type / missing list nocum out=summ1;
run;

proc freq data=storage2.db30 noprint;
	table study_key* studyref * route * species * chemical * treatment / missing list nocum out=summ2;
run;

proc freq data=storage2.db30 noprint;
	table study_key * studyref * chemical * treatment * target_dose_amount / missing list nocum out=summ3;
run;

proc freq data=storage2.skeleton_pchem1_v2_impute noprint;
	table study_key * species * strain * gender / missing list nocum out=summ4;
run;





/* Examine controls for Duplicates */
* Likely by lab, particularly ENPRA ;
* Positive Controls are duplicates for certain ;

data db1;
	set storage2.skeleton_pchem1_v2;
run;

data rivm1;
	set db1;
	if dep_dose_amount2=0 and studyref="ENPRA-RIVM";
run;
proc sort data=rivm1;
	by totcell pmncount;
run;
/* no dupes */
/* 2 MWCNT animals with missing counts are explained in raw data --- different animals */


data nrcwe1;
	set db1;
	if dep_dose_amount2=0 and studyref="ENPRA-NRCWE";
run;
proc sort data=nrcwe1;
	by pe_d strain samppmnper;
run;
proc sort data=nrcwe1;
	by totcell;
run;
data nrcwe2;
	set nrcwe1;
	keep strain pe_d totcell pmncount samppmnper animal_key;
run;
proc freq data=nrcwe2;
	table strain * pe_d * totcell * pmncount / missing list nocum;
run;
/* 7 dupes? */
/* manual inspection agrees with FREQ */
data nrcwe3;
	set nrcwe1;

	if (totcell=786000 AND pmncount=70740) or
	   (totcell=2016000 AND pmncount=100800) or
	   (totcell=2412000 AND pmncount=156780) or
	   (totcell=2658000 AND pmncount=106320) or
	   (totcell=3540000 AND pmncount=389400) or
	   (totcell=6924000 AND pmncount=969360) or
	   (totcell=186000 AND pmncount=930);
run;
/* NRCWE Control Dupes (Animal_Key)
		226 = 236
		214 = 230
		213 = 229
		218 = 234
		216 = 232
		217 = 233
		215 = 231
*/



data uc1;
	set db1;
	if dep_dose_amount2=0 and studyref="ENPRA-UC";
run;
proc sort data=uc1;
	by totcell pmncount;
run;
/* manual inspection - 5 to 7 dupes, 2 unclear */
proc freq data=uc1;
	table totcell * pmncount / missing list nocum;
run;
/* 7 dupes --- the 2 unclear dupes have TotCell=24500 and PMNCount=0 */
/* manual inspection of the original data files shows that there are 2 different mice in each study (100014, 100015) 
   with the TotCell=24500 and PMNCount=0.  These are the same 2 mice in both studies, however. */
/* Mouse 615 and 621 = 622 and 628 */
/* 7 dupes total */
data uc2 (keep=strain pe_d totcell pmncount samppmnper animal_key);
	set uc1;
	if (totcell=16500 and pmncount=165) or
	   (totcell=23000 and pmncount=115) or
	   (totcell=24500 and pmncount=0)   or
	   (totcell=29500 and pmncount=295) or
	   (totcell=32000 and pmncount=160) or
	   (totcell=36000 and pmncount=540);
run;

/* UC Control Dupes (Animal_Key)
		616 = 623
		615 = 622
		621 = 628
		619 = 626
		617 = 624
		620 = 627
		618 = 625
*/

data uc3;
	set db1;
	if studyref="ENPRA-UC" and material="Silica";
run;
proc sort data=uc3;
	by totcell pmncount;
run;
proc freq data=uc3;
	table totcell * pmncount / missing list nocum;
run;
/* 8 unique mice, 16 dupes = 24 */
data uc4;
	set uc3;
	keep totcell animal_key;
run;

/* UC Positive Control Dupes (Animal_Key)
		689 = 697 = 705
		688 = 696 = 704
		684 = 692 = 700
		691 = 699 = 707
		687 = 695 = 703
		685 = 693 = 701
		686 = 694 = 702
		690 = 698 = 706
*/


data berm1;
	set db1;
	if dep_dose_amount2=0 and study_key in ("100024", "100025");
run;
proc sort data=berm1;
	by totcell samppmnper;
run;
proc freq data=berm1;
	table totcell * samppmnper / list missing nocum;
run;

/* SUMMARY 

	Porter2013 - 0
	Xia2011	    -0
	Roberts2013 -0
	Sager2013   -0
	Porter2001  -0
	Porter2004  -0

	RIVM        -0
	NRCWE       -7
	UC	        -7
                -16 positive control

    Bermudez    -0
    ==========================
                -30 animals
		        1929 - 30 = 1899 unique animals

*/







/* PMN flow chart */

data db2;
	set db1;

	if studyref="Xia2011" and material_type="control" and dep_dose_amount2 NE 0 then delete;
	if animal_key in (236, 230, 229, 234, 232, 233, 231, 623, 622, 628, 626, 624, 627, 625, 697, 
					  696, 692, 699, 695, 693, 694, 698, 705, 704, 700, 707, 703, 701, 702, 706) then delete;
run;

data db3;
	set db2;
	if samppmnper NE .;
run;

data qc (keep=samppmnper pmnper totcell pmncount sampcell samppmncount);
	set db2;
	if samppmnper = .;
run;







/* number of animals */
data qc1;
	set storage2.skeleton_pchem1_v3;
	if pe_d <=3;
run;

proc freq data=qc1;
	table studyref * material * material_type * pe_d * administered_dose / missing list;
run;
/* sort of works --- ENPRA data is easiest to look at the Excel files (different animal strains used, for example) */







/*//////////////////////////////////////////////////////
///
///		Variable Summary for NTRC Biannual Meeting
///
/*/

proc freq data=storage2.skeleton_pchem1_v4;
	where material_type NOT IN ("control", "control1", "control2", "control3", "control4", "control5", "control6",
								 "control7", "control8", "controlIonized1", "controlIonized2", "controlColloid1",
								 "controlColloid2");
	table material*material_type / missing list nocum;
run;

proc contents data=storage2.skeleton_pchem1_v4 out=qc noprint;
run;
 
proc means data=storage2.skeleton_pchem1_v4 nmiss;
	where material_type NOT IN ("control", "control1", "control2", "control3", "control4", "control5", "control6",
								 "control7", "control8", "controlIonized1", "controlIonized2", "controlColloid1",
								 "controlColloid2");
	class material material_type;
	var totcell pmncount pmnper sampcell samppmncount samppmnper;
run; 




/*//////////////////////////////////////////////////////
///
///		Risk Assessment Guidance Presentation
///
/*/

proc sort data=storage2.skeleton_pchem1_v4 nodupkey out=sort1;
	where (pe_d <= 3) AND (material_type not in ("control", "controlColloid1", "controlIonized1", "control1", "control2",
												 "control3", "control4", "control5", "control6", "control7", "control8"));
	by study_key material material_type pe_d;
run;





/*//////////////////////////////////////////////////////
///
///		Data summary for potentially analyzing more post exposures
///
/*/

data qc;
	set storage2.skeleton_pchem1_v4;
	if pe_d > 3 and pe_d <= 14;
	if samppmnper = . then delete;
run;
data qc;
	set storage2.skeleton_pchem1_v4;
	if pe_d > 14 and pe_d <= 60;
	if samppmnper = . then delete;
run;
