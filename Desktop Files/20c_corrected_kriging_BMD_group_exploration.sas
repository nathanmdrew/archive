options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";

data db1;
	set storage2.skeleton_pchem1_v5; * uses the DB changes from May 16th (label changes, lengths) ;
	if pe_d <= 3;
run;

/*
Using CORRECTED Kriging BMDs from Feng Yang, create groups and datasets
for Random Forest exploration

Hierarchical Cluster (k=4)	Reference	Route	Post Exposure Days	Material	Material Type	Study Key	BMD		BMDL
--------------------------	---------	-----	------------------	--------	-------------	---------	-----	-----
1							ENPRA-RIVM	IT			1				ZnO(3)		uncoated(14)	100017		18.88	12.99
1							Porter2013	PA			1				TiO2(1)		NB2(2)			100001		23.55	12.87
1							Porter2013	PA			3				TiO2(1)		NB2(2)			100001		23.63	15.07
1							ENPRA-RIVM	IT			1				MWCNT(5)	short(17)		100013		25.86	18.1
1							ENPRA-NRCWE	IT			1				MWCNT(5)	long(18)		100008		30.57	7.38
1							ENPRA-NRCWE	IT			1				MWCNT(5)	short(17)		100011		35.04	24.2
1							Sager2013	PA			1				MWCNT(5)	Bare(10)		100004		45.79	33.08
1							Porter2013	PA			1				TiO2(1)		NB1(1)			100001		47.63	31.06
1							ENPRA-RIVM	IT			1				ZnO(3)		coated(13)		100016		69.42	53.18
1							Porter2013	PA			3				TiO2(1)		NB1(1)			100001		82.11	54.81

2							ENPRA-NRCWE	IT			1				MWCNT(5)	long(18)		100009		115.28	21.12
2							ENPRA-NRCWE	IT			1				MWCNT(5)	short(17)		100010		123.54	22.41
2							Sager2013	PA			1				MWCNT(5)	Carboxylated(11)	100004	140.33	116.59
2							ENPRA-RIVM	IT			1				MWCNT(5)	long(18)		100012		190.86	100.89

3							Bermudez2004	Inh		0				TiO2(1)		Ultrafine(16)	100025		661.86	548.67
3							ENPRA-RIVM	IT			1				TiO2(1)		rutile(21)		100022		771.74	53.64

4							Bermudez2002	Inh		0				TiO2(1)		fine(23)		100024		3309.21	3158.14


*/

/*proc sort data=db1 out=table1 (keep=study_key studyref material material_type pe_d species strain)*/
/*          nodupkey;*/
/*	by study_key studyref material material_type pe_d;*/
/*run;*/


/*///////////////////////////////////////////////////////////////////////////////
///		Create a separate dataset for each Cluster 1 -4  (hence c1, c2, c3, c4)
///
/*/

data c4;
	set db1;
	if studyref = "Bermudez2002";

	BMD_Krig  = 3309.21;
	BMDL_Krig = 3158.14;

run;

data c3;
	set db1;

	if study_key in ("100022", "100025");

	if study_key = "100022" then do;
		BMD_Krig = 771.74;
		BMDL_Krig = 53.64;
	end;
	if study_key = "100025" then do;
		BMD_Krig = 661.86;
		BMDL_Krig = 548.67;
	end;

run;

data c2;
	set db1;

	if ( study_key in ("100009", "100010", "100012") ) OR ( study_key = "100004" and material_type in ("Carboxylated", "control") );

	if study_key = "100009" then do;		
		BMD_Krig = 115.28;
		BMDL_Krig = 21.12;
	end;
	if study_key = "100010" then do;		
		BMD_Krig = 123.54;
		BMDL_Krig = 22.41;
	end;
	if study_key = "100012" then do;		
		BMD_Krig = 190.86;
		BMDL_Krig = 100.89;
	end;
	if study_key = "100004" then do;		
		BMD_Krig = 140.33;
		BMDL_Krig = 116.59;
	end;

run;

data c1;
	set db1;
			
	if ( study_key = "100001" and material_type in ("NB1", "NB2", "control") ) OR
	   ( study_key = "100008" ) OR
	   ( study_key = "100017" ) OR
	   ( study_key = "100011" ) OR
	   ( study_key = "100004" and material_type in ("Bare", "control") ) OR
	   ( study_key = "100016" ) OR
	   ( study_key = "100013" );

	   /* NOTE --- BMDs and BMDLs are not transferred to controls */
	if study_key = "100001" and material_type = "NB2" and pe_d=1 then do;
		BMD_Krig = 23.55;
		BMDL_Krig = 12.87;
	end;

	if study_key = "100001" and material_type = "NB2" and pe_d=3 then do;
		BMD_Krig = 23.63;
		BMDL_Krig = 15.07;
	end;

	if study_key = "100008" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 30.57;
		BMDL_Krig = 7.38;
	end;

	if study_key = "100017" and material_type = "uncoated" and pe_d=1 then do;
		BMD_Krig = 18.88;	
		BMDL_Krig = 12.99;
	end;

	if study_key = "100011" and material_type = "short" and pe_d=1 then do;
		BMD_Krig = 35.04;	
		BMDL_Krig = 24.2;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=1 then do;
		BMD_Krig = 47.63;
		BMDL_Krig = 31.06;
	end;

	if study_key = "100004" and material_type = "Bare" and pe_d=1 then do;
		BMD_Krig = 45.79;	
		BMDL_Krig = 33.08;
	end;

	if study_key = "100016" and material_type = "coated" and pe_d=1 then do;
		BMD_Krig = 69.42;		
		BMDL_Krig = 53.18;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=3 then do;
		BMD_Krig = 82.11;		
		BMDL_Krig = 54.81;
	end;

	if study_key = "100013" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 25.86;		
		BMDL_Krig = 18.1;
	end;


run;

proc sort data=c1 out=qc (keep=study_key studyref material material_type pe_d bmd_krig bmdl_krig) nodupkey;
	by study_key studyref material material_type pe_d bmd_krig bmdl_krig;
run;
data qc;
	set c1;
	if ind_drop=1;
	/* all 26 missing response */
run;
data qc;
	set c2;
	if ind_drop=1;
	/* 8 */
	/* 6 dupes --- originals in the data
	   2 missing response */
run;
data qc;
	set c3;
	if ind_drop=1;
	/* 1 - no response */
run;
data qc;
	set c4;
	if ind_drop=1;
	/* none */
run;

/* drop the previously identified trouble makers (dupe pos and neg controls, bad Xia controls)  */
data c1_2;
	set c1;
	if ind_drop=0;
	/* 30 to drop --- 24 are missing Samp PMN %
					   6 are Negative Controls and have the alternate controls in the data */
			

	/* adjust Porter lengths */
	*if material_type="NB1" then length=3; /* from pub, Mode/Median/Mean in 2-3 */
	*if material_type="NB2" then length=9; /* from pub, Median/Mode=8-10, Mean = 9 */

	if material_category="Control" then do;
		material_manufacturer="Control";
		material_lot_number="Control";
		scale="Control";
		Agglomerated_="M";
		structural_form="Control";
		Crystal_Structure_="M";
		crystal_type="N/A";
		diameter=-99;
		diameter_units="N/A";
		length=.;
		length_units="N/A";
		rigidity="M";
		entangled="M";
		median_aerodynamic_diameter="N/A";
		aerodynamic_diameter_gsd="N/A";
		aerodynamic_diameter_units="N/A";
		surface_area=-99;
		surface_area_units="N/A";
		surface_area_method="N/A";
		volume="M";
		density=-99;
		surface_charge="M";
		zeta_potential=-99;
		zeta_potential_units="N/A";
		solubility="M";
		solubility_method="N/A";
		modification="N/A";
		purification_type="N/A";
		coated_type="N/A";
		functionalized_type="N/A";
		ground_type="N/A";
		contaminants_="M";
		contaminant_type="N/A";
		contaminant_amount=-99;
	end;

	if median_aerodynamic_diameter="" then median_aerodynamic_diameter="N/A";
	if aerodynamic_diameter_gsd="" then aerodynamic_diameter_gsd="N/A";
	if diameter=. then diameter=-99;
	*if length="." then length=".";
	if rigidity="" then rigidity="M";
	if surface_area=. then surface_area=-99;
	if volume="" then volume="M";
	if density=. then density=-99;
	if surface_charge="" then surface_charge="M";
	if zeta_potential=. then zeta_potential=-99;
	if solubility="" then solubility="M";
	if contaminant_amount=. then contaminant_amount=-99;

run;

data qc (keep=animal_key ind_drop);
	set c1;
	if dep_dose_amount2=0 and samppmnper NE .;
run;

data c2_2;
	set c2;
	if ind_drop=0;
	/* 2 to drop --- both are missing Sample PMN % */

	if material_category="Control" then do;
		material_manufacturer="Control";
		material_lot_number="Control";
		scale="Control";
		Agglomerated_="M";
		structural_form="Control";
		Crystal_Structure_="M";
		crystal_type="N/A";
		diameter=-99;
		diameter_units="N/A";
		length=.;
		length_units="N/A";
		rigidity="M";
		entangled="M";
		median_aerodynamic_diameter="N/A";
		aerodynamic_diameter_gsd="N/A";
		aerodynamic_diameter_units="N/A";
		surface_area=-99;
		surface_area_units="N/A";
		surface_area_method="N/A";
		volume="M";
		density=-99;
		surface_charge="M";
		zeta_potential=-99;
		zeta_potential_units="N/A";
		solubility="M";
		solubility_method="N/A";
		modification="N/A";
		purification_type="N/A";
		coated_type="N/A";
		functionalized_type="N/A";
		ground_type="N/A";
		contaminants_="M";
		contaminant_type="N/A";
		contaminant_amount=-99;
	end;

	if median_aerodynamic_diameter="" then median_aerodynamic_diameter="N/A";
	if aerodynamic_diameter_gsd="" then aerodynamic_diameter_gsd="N/A";
	if diameter=. then diameter=-99;
	*if length="" then length="N/A";
	if rigidity="" then rigidity="M";
	if surface_area=. then surface_area=-99;
	if volume="" then volume="M";
	if density=. then density=-99;
	if surface_charge="" then surface_charge="M";
	if zeta_potential=. then zeta_potential=-99;
	if solubility="" then solubility="M";
	if contaminant_amount=. then contaminant_amount=-99;
run;

data c3_2;
	set c3;
	if ind_drop=0;
	/* 3 to drop --- both are missing Sample PMN % */

	if material_category="Control" then do;
		material_manufacturer="Control";
		material_lot_number="Control";
		scale="Control";
		Agglomerated_="M";
		structural_form="Control";
		Crystal_Structure_="M";
		crystal_type="N/A";
		diameter=-99;
		diameter_units="N/A";
		length=.;
		length_units="N/A";
		rigidity="M";
		entangled="M";
		median_aerodynamic_diameter="N/A";
		aerodynamic_diameter_gsd="N/A";
		aerodynamic_diameter_units="N/A";
		surface_area=-99;
		surface_area_units="N/A";
		surface_area_method="N/A";
		volume="M";
		density=-99;
		surface_charge="M";
		zeta_potential=-99;
		zeta_potential_units="N/A";
		solubility="M";
		solubility_method="N/A";
		modification="N/A";
		purification_type="N/A";
		coated_type="N/A";
		functionalized_type="N/A";
		ground_type="N/A";
		contaminants_="M";
		contaminant_type="N/A";
		contaminant_amount=-99;
	end;

	if median_aerodynamic_diameter="" then median_aerodynamic_diameter="N/A";
	if aerodynamic_diameter_gsd="" then aerodynamic_diameter_gsd="N/A";
	if diameter=. then diameter=-99;
	*if length="" then length="N/A";
	if rigidity="" then rigidity="M";
	if surface_area=. then surface_area=-99;
	if volume="" then volume="M";
	if density=. then density=-99;
	if surface_charge="" then surface_charge="M";
	if zeta_potential=. then zeta_potential=-99;
	if solubility="" then solubility="M";
	if contaminant_amount=. then contaminant_amount=-99;
run;

data c4_2;
	set c4;
	if ind_drop=0;
	/* none to drop */

	if material_category="Control" then do;
		material_manufacturer="Control";
		material_lot_number="Control";
		scale="Control";
		Agglomerated_="M";
		structural_form="Control";
		Crystal_Structure_="M";
		crystal_type="N/A";
		diameter=-99;
		diameter_units="N/A";
		length=.;
		length_units="N/A";
		rigidity="M";
		entangled="M";
		median_aerodynamic_diameter="N/A";
		aerodynamic_diameter_gsd="N/A";
		aerodynamic_diameter_units="N/A";
		surface_area=-99;
		surface_area_units="N/A";
		surface_area_method="N/A";
		volume="M";
		density=-99;
		surface_charge="M";
		zeta_potential=-99;
		zeta_potential_units="N/A";
		solubility="M";
		solubility_method="N/A";
		modification="N/A";
		purification_type="N/A";
		coated_type="N/A";
		functionalized_type="N/A";
		ground_type="N/A";
		contaminants_="M";
		contaminant_type="N/A";
		contaminant_amount=-99;
	end;

	if median_aerodynamic_diameter="" then median_aerodynamic_diameter="N/A";
	if aerodynamic_diameter_gsd="" then aerodynamic_diameter_gsd="N/A";
	if diameter=. then diameter=-99;
	*if length="" then length="N/A";
	if rigidity="" then rigidity="M";
	if surface_area=. then surface_area=-99;
	if volume="" then volume="M";
	if density=. then density=-99;
	if surface_charge="" then surface_charge="M";
	if zeta_potential=. then zeta_potential=-99;
	if solubility="" then solubility="M";
	if contaminant_amount=. then contaminant_amount=-99;
run;

/* check for duplicate animals, maybe controls were read in multiple times */
proc sort data=c1_2 out=qc nodupkey;
	by animal_key;
run;
proc sort data=c2_2 out=qc nodupkey;
	by animal_key;
run;
proc sort data=c3_2 out=qc nodupkey;
	by animal_key;
run;
proc sort data=c4_2 out=qc nodupkey;
	by animal_key;
run;
/*			looks good			*/

proc contents data=c1_2;
run;

/**** clean up the useless vars, like UNITS ****/
/*		also, vars with 1 level (Ground Type)  */
data c1_3;
	set c1_2;

	cluster=1;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units

		 Agglomerated_ reported_length reported_diameter Ground_Type Solubility_Method surface_charge volume Rigidity Solubility;
run;

data c2_3;
	set c2_2;

	cluster=2;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units

		 Agglomerated_ reported_length reported_diameter Ground_Type Solubility_Method surface_charge volume Rigidity Solubility;
run;

data c3_3;
	set c3_2;

	cluster=3;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units

		 Agglomerated_ reported_length reported_diameter Ground_Type Solubility_Method surface_charge volume Rigidity Solubility;
run;

data c4_3;
	set c4_2;

	cluster=4;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units

		 Agglomerated_ reported_length reported_diameter Ground_Type Solubility_Method surface_charge volume Rigidity Solubility;
run;

proc export data=c1_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust1_correct_v2.csv"
			replace dbms=csv;
run;
proc export data=c2_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust2_correct_v2.csv"
			replace dbms=csv;
run;
proc export data=c3_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust3_correct_v2.csv"
			replace dbms=csv;
run;
proc export data=c4_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust4_correct_v2.csv"
			replace dbms=csv;
run;



/*///////////////////////////////////////////////////////////////////////////////
///		Plot the separate datasets for each Cluster 1 -4  (hence c1, c2, c3, c4)
///
///			Includes duplicate controls, but aren't visible (overlap)
/*/

proc sgplot data=c1;
	title "Dose-Response for Hierarchical Cluster 1";
	title2 "Corrected Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c2;
	title "Dose-Response for Hierarchical Cluster 2";
	title2 "Corrected Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c3;
	title "Dose-Response for Hierarchical Cluster 3";
	title2 "Corrected Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c4;
	title "Dose-Response for Hierarchical Cluster 4";
	title2 "Corrected Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

title;

proc freq data=c1;
	table ind_drop / missing list nocum;
run;

proc freq data=c2;
	table ind_drop / missing list nocum;
run;

proc freq data=c3;
	table ind_drop / missing list nocum;
run;

proc freq data=c4;
	table ind_drop / missing list nocum;
run;



/*///////////////////////////////////////////////////////
///		explore important factors from R random forests
///
/*/

/* cluster 4 important factors -- mtry=9 -- % Var explained: 24.87
   ---------------------------------------------------------------
	crystal type
	agglomerated
	density
	crystal_structure_
	contaminants
	structural form
	material type
	entangled
	aerodynamic diameter gsd
	scale
	median aerodynamic diameter
	material category
*/
proc freq data=c4_3;
	table crystal_type 
		  agglomerated_ 
		  density 
		  crystal_structure_ 
		  contaminants_
		  structural_form 
		  material_type 
		  entangled
		  aerodynamic_diameter_gsd 
		  scale
		  median_aerodynamic_diameter
		  material_category / missing list nocum;
run;

proc freq data=c4_3;
	table material_category*agglomerated_ 
		  material_category*crystal_structure_ 
		  material_category*crystal_type / missing list nocum;
run;

/* since this has just one material, these important factors are picking up the difference between control and TiO2 */
/* a unique characteristic of this group is that its Micro sized */



data c_all;
	set c1_3 c2_3 c3_3 c4_3;
run;
/*
Physico-Chemical Property	MeanDecreaseAccuracy
-------------------------	--------------------
Diameter						20.98991052
Surface_Area					20.86419285
Crystal_Type					18.1890469
material						16.15257695
Density							15.57639573
Modification					15.03456918
Zeta_Potential					13.02728238
Functionalized_Type				12.67450613
Structural_Form					11.0280062
Aerodynamic_Diameter_GSD		10.32132199
Material_Category				9.926163659
Crystal_Structure_				9.561035223
Median_Aerodynamic_Diameter		9.467142095
Scale							9.290938062
Length							7.582224507
Purification_Type				6.225754514

*/

/* (1) Diameter was the Most Important */
proc sgplot data=c_all;
	scatter x=cluster y=diameter;
run;
proc means data=c_all;
	where diameter>0;
	class cluster;
	var diameter;
run;


/* (2) Surface Area */
proc sgplot data=c_all;
	scatter x=cluster y=surface_area;
run;
proc freq data=c_all;
	table cluster * surface_area / list missing nocum;
run;
proc means data=c_all;
	where surface_area>0;
	class cluster;
	var surface_area;
run;


/* (3) Crystal Type */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * crystal_type / list missing nocum;
run;


/* (4) Material */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * material / list missing nocum;
run;



/* (5) Density */
proc sgplot data=c_all;
	scatter x=cluster y=density;
run;
proc freq data=c_all;
	*where material_category ne "Control";
	table cluster * density / list missing nocum;
run;
proc means data=c_all;
	where density>0;
	class cluster;
	var density;
run;


/* (6) Modification */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * modification / list missing nocum;
run;


/* (7) Zeta Potential */
proc means data=c_all;
	where zeta_potential ne -99;
	class cluster;
	var zeta_potential;
run;


/* (8) Functionalized Type */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * functionalized_type / list missing nocum;
run;


/* (9) Structural Form */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * structural_form / list missing nocum;
run;


/* (10) GSD */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * aerodynamic_diameter_gsd / list missing nocum;
run;



/* (11) Material Category */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * material_category / list missing nocum;
run;



/* (12) Crystal Structure */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * crystal_structure_ / list missing nocum;
run;


/* (13) MAD */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * median_aerodynamic_diameter / list missing nocum;
run;


/* (14) Scale */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * scale / list missing nocum;
run;


/* (15) Length */
proc means data=c_all;
	where length ne -99;
	class cluster;
	var length;
run;


/* (16) Purification Type */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * purification_type / list missing nocum;
run;
