/*/////////////////////////////////////////////////
///		Database updates and corrections
///			Fix BMD list
///			Get a working, one piece dataset with all known changes
///				Porter, Sager pchem info;  dupe control animals;
/*/	

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";


/*//////////////////////////////////////////////////////////
///		Update the list of BMDs
///		Combine with other Points-of-Departure (PoDs)
/*/

/* Import the BMD summary */
proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\BMDS Best Model Fit Summary v2.2.xlsx" out=bmd1 dbms=excel replace;
	sheet="Results";
run;

data storage2.bmd_final_v2;
	set bmd1;
run;

proc univariate data=bmd1;
	var BMD;
run;
/* 34 BMDs, 55 missing */
/* Missing due to Extrapolation, No Association, or Inadequate Models */

data bmd2;
	set bmd1;

	rename post_exposure_days = pe_d
		   bmd = bmd_pct_pmn
		   bmdl = bmdl_pct_pmn;
run;


proc import datafile="Z:\MyLargeWorkspace Backup\ENM Categories\NOAEL_LOAEL_BMD_19OCT2015.xlsx" out=nolo1 dbms=excel;
run;

data nolo2;
	set nolo1;

	rename post_exposure_days = pe_d
		   __PMN___NOAEL = noael_pct_pmn
		   __PMN___LOAEL = loael_pct_pmn
		   Total_PMN___LOAEL = loael_total_pmn
		   Total_PMN___NOAEL = noael_total_pmn
		   __PMN___BMD = bmd_pct_pmn
		   __PMN___BMDL = bmdl_pct_pmn;
run;

proc sort data=nolo2; by study_key material material_type pe_d; run;
proc sort data=bmd2;  by study_key material material_type pe_d; run;

data nolo3;
	merge nolo2 (in=aa)
		  bmd2  (in=bb keep=study_key material material_type pe_d bmd_pct_pmn bmdl_pct_pmn);
	by study_key material material_type pe_d;

	if study_key = "" then delete;

	*duplicate caused by Porter 1997 --- delete in next step;
	index = _N_;
run;

data nolo4 (drop=index);
	set nolo3;

	if index=47 then delete;
run;

data storage2.PoD_final;
	set nolo4;
run;

proc export data=nolo4 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\NOAEL_LOAEL_BMD_21JAN2016.xlsx" dbms=excel replace label;
run;



/*//////////////////////////////////////////////////////////
///		Update database with latest known changes/fixes
///				Indicator and Reason for deletion
///					Xia non-control dose "control" animals
///					ENPRA duplicate negative/positive controls
///					PChem for Porter TiO2, Sager MWCNT
/*/

data db1;
	set storage2.skeleton_pchem1_v2;

	ind_drop=0;
	if studyref="Xia2011" and material_type="control" and dep_dose_amount2 > 0 then ind_drop=1;
	if animal_key in (236, 230, 229, 234, 232, 233, 231, 623, 622, 628, 626, 624, 627, 625, 697, 
					  696, 692, 699, 695, 693, 694, 698, 705, 704, 700, 707, 703, 701, 702, 706) then ind_drop=1;
	if samppmnper = . then ind_drop=1;

run;

proc freq data=db1;
	table ind_drop / missing list;
run;
/* 1,557 unique animals with PMN data and no known issues --- good */

proc freq data=db1;
	where studyref="Porter2013";
	table material_type * diameter * length / missing list;
run;
proc freq data=db1;
	where studyref="Sager2013";
	table material_type * diameter * length / missing list;
run;

data db2;
	set db1;

	/* these are Count Median Diameters --- not sure if equivalent to the other diameters */
	if studyref="Sager2013" then do;
		if material_type="Bare" then do;
			diameter=42;
			diameter_units="nm";
		end;

		if material_type="Carboxylated" then do;
			diameter=44;
			diameter_units="nm";
		end;
	end;

	if studyref="Porter2013" then do;
		/* the publication histograms are binned, so the true median/mode isn't known.
	       for NB1, the median occurs in the 60-80 bin, so maybe 70 is the median?
	       since the authors report a range of 40-120, 80 is the median. 
	       this process is used for get a single diameter for the 3 material types */

		if material_type="NB1" then diameter=80; 
		if material_type="NB2" then diameter=100;
		if material_type="NS" then diameter=130;
	end;

run;

proc freq data=db2;
	where studyref in ("Porter2013", "Sager2013");
	table material_type * diameter * length / missing list;
run;

data storage2.skeleton_pchem1_v3;
	set db2;
run;

proc freq data=db2;
	table studyref * material* material_type * surface_area / missing list nocum;
run;
proc freq data=db2;
	table species strain / missing list nocum;
run;
proc freq data=db2;
	where studyref="Porter2013";
	table diameter length / missing nocum list;
run;

/* feb29 2016 --- continue updates */
data db3 (drop=est_LWstart rename=(length2=Length));
	set db2;

	* ### add a note about why ind_drop=1 ### ;
	format drop_note $30.;
	if studyref="Xia2011" and material_type="control" and dep_dose_amount2 > 0 then drop_note="control with non-zero dose";
	if animal_key in (236, 230, 229, 234, 232, 233, 231, 623, 622, 628, 626, 624, 627, 625, 697, 
					  696, 692, 699, 695, 693, 694, 698, 705, 704, 700, 707, 703, 701, 702, 706) then drop_note="duplicate animal";
	if samppmnper = . then drop_note="no response measured";


	* ### surface areas ### ;
	if studyref="Bermudez2002" then do;
		surface_area = 6; *Reported in Warheit et al. 2005, Table 2, “Base TiO2” --- see studies cited in earlier email (021616 EDK to ND) which support that the 
    						 pigmentary TiO2 in Bermudez et al. 2002 is the same material as reported in Warheit et al. 2005..  ;

		surface_area_units="m2/g";
		surface_area_method = "BET";
	end;

	if studyref="ENPRA-UC" and material="Silica" then do;
		surface_area = 4.57; 
		*Estimated from Porter et al 2001, 2004, per ND email (022216, above) since ENPRA silica was also Min-U-Sil [to verify].;

		surface_area_units = "m2/g";
		surface_area_method = "BET";
	end;

	* ### lung weight normalization factors ### ;
	gram_lung_factor = 0;
	if species="Mouse" then gram_lung_factor = 0.15;
	*[source:  Shvedova et al. 2005 and Murray et al. 2012 CNT studies --- pers comm AS to EDK, reported in CNT CIB --- consistent
	with values reported in several other studies in male or female mice from a focused literature search --- see 022316 email 
	EDK]. ;

	if species="Rat" then do;
		if strain="F344" then gram_lung_factor = 0.9;
		*[source:  Porter et al. 2001, 2004 (1999 silica data) --- consistent with values reported in several other studies 
		from a focused literature search --- see 022316 email EDK]. ;

		if strain="Sprague-Dawley" and gender="M" then gram_lung_factor=1.3;
		* [estimate to be checked (& revised) by ND, from papers sent in email EDK to ND 022516]. ;
	end;

	surf_area_m2_lung_factor=0;
	if species="Mouse" then surf_area_m2_lung_factor=0.055;
	if species="Rat" then surf_area_m2_lung_factor=0.4;

	* ### include column(s) for factors "as reported" --- allows for original and modified versions to be seen ### ;
	if studyref = "Bermudez2002" then do;
		diameter=300;
		diameter_units="nm";
	end;;

	reported_diameter = put(diameter, 10.1);
	if studyref="Porter2013" then do;
		if material_type="NB1" then reported_diameter="40 to 120"; 
		if material_type="NB2" then reported_diameter="60 to 140";
		if material_type="NS" then reported_diameter="70 to 190";
	end;

	format reported_length $10.;
	reported_length = length;
	if reported_length = "1 - 5" then do;
		reported_length = "1 to 5";
		length2 = 3;
	end;
	if reported_length = "6 - 12" then do;
		reported_length = "6 to 12";
		length2=9;
	end;
	if reported_length not in ("1 to 5", "6 to 12") then length2=put(length, 10.1);

	drop length;

	* ###  change ENPRA Silica from Nano to Micro ### ;
	if studyref="ENPRA-UC" and material="Silica" then scale="Micro";

	* ### correct deposited doses ### ;
	if species="Mouse" then do;
		dep_dose_amount = dep_dose_amount * 15 / gram_lung_factor;
		dep_dose_amount2 = dep_dose_amount2 * 15 / gram_lung_factor;
	end;

	if species="Rat" then do;
		dep_dose_amount = dep_dose_amount * 300 / gram_lung_factor;
		dep_dose_amount2 = dep_dose_amount2 * 300 / gram_lung_factor;
	end;

run;

/*proc freq data=db3;*/
/*	table ind_drop * drop_note / missing list nocum;*/
/*	table species * strain * gender * gram_lung_factor / missing list nocum;*/
/*run;*/

proc freq data=db3;
	*table studyref * length * reported_length / missing list nocum;
	*table studyref * diameter * reported_diameter / missing list nocum;
	table studyref * material * material_type * diameter * reported_diameter / missing list nocum;
	*table studyref * material * scale / missing list nocum;
run;

data storage2.skeleton_pchem1_v4;
	set db3;
run;

* save physical copy of database ;
proc export data=db3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\skeleton_and_physiochemical_29feb2016.csv" dbms=csv replace;
run;

proc contents data=db3 out=contents;
run;

proc sort data=db3 out=db3_pchem (keep=study_key studyref Aerodynamic_Diameter_GSD
Aerodynamic_Diameter_Units
Agglomerated_
Coated_Type
Contaminant_Amount
Contaminant_Type
Contaminants_
Crystal_Structure_
Crystal_Type
Density
Diameter
Diameter_Units
Entangled
Functionalized_Type
Ground_Type
Length
Length_Units
Material_Category
Material_Lot_Number
Material_Manufacturer
Median_Aerodynamic_Diameter
Modification
Purification_Type
Rigidity
Scale
Solubility
Solubility_Method
Structural_Form
Surface_Area
Surface_Area_Method
Surface_Area_Units
Surface_Charge
Volume
Zeta_Potential
Zeta_Potential_Units
material
material_type
reported_diameter
reported_length

) nodupkey;
	by study_key studyref Aerodynamic_Diameter_GSD
Aerodynamic_Diameter_Units
Agglomerated_
Coated_Type
Contaminant_Amount
Contaminant_Type
Contaminants_
Crystal_Structure_
Crystal_Type
Density
Diameter
Diameter_Units
Entangled
Functionalized_Type
Ground_Type
Length
Length_Units
Material_Category
Material_Lot_Number
Material_Manufacturer
Median_Aerodynamic_Diameter
Modification
Purification_Type
Rigidity
Scale
Solubility
Solubility_Method
Structural_Form
Surface_Area
Surface_Area_Method
Surface_Area_Units
Surface_Charge
Volume
Zeta_Potential
Zeta_Potential_Units
material
material_type
reported_diameter
reported_length

;
run;

data db3_pchem2;
	set db3_pchem;
	if material_category="Control" then delete;
run;

proc export data=db3_pchem2 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\DB\physiochemical_database_29feb2016.csv" dbms=csv replace;
run;




