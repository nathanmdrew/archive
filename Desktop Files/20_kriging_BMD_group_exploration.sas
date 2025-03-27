options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
*libname storage  "Y:\ENM Categories\DB\SAS Datasets";
libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";
libname storage3 "Z:\MyLargeWorkspace Backup\ENM Categories\PoD Stratification and Cluster";

data db1;
	set storage2.skeleton_pchem1_v3;
	if pe_d <= 3;
run;

/*
Using Kriging BMDs from Feng Yang (Kriging_BMD_Clusters_w_NIOSHlabels.xlsx), create groups and datasets
for Random Forest exploration

Hierarchical Cluster (k=4)	Reference	Route	Post Exposure Days	Material	Material Type	Study Key
--------------------------	---------	-----	------------------	--------	-------------	---------
1							Porter2013	PA			1					TiO2	NB2				100001
1							Porter2013	PA			3					TiO2	NB2				100001
1							ENPRA-NRCWE	IT			1					MWCNT	long			100008
1							ENPRA-RIVM	IT			1					ZnO		uncoated		100017
1							ENPRA-NRCWE	IT			1					MWCNT	short			100011
1							Porter2013	PA			1					TiO2	NB1				100001
1							Sager2013	PA			1					MWCNT	Bare			100004
1							ENPRA-RIVM	IT			1					ZnO		coated			100016
1							Porter2013	PA			3					TiO2	NB1				100001
1							ENPRA-NRCWE	IT			1					MWCNT	long			100009
1							ENPRA-NRCWE	IT			1					MWCNT	short			100010

2							ENPRA-RIVM	IT			1					MWCNT	short			100013
2							Bermudez2004	Inh		0					TiO2	Ultrafine		100025
2							Sager2013	PA			1					MWCNT	Carboxylated	100004

3							ENPRA-RIVM	IT			1					TiO2	rutile			100022
3							ENPRA-RIVM	IT			1					MWCNT	long			100012

4							Bermudez2002	Inh		0					TiO2	Fine			100024

*/

proc sort data=db1 out=table1 (keep=study_key studyref material material_type pe_d species strain)
          nodupkey;
	by study_key studyref material material_type pe_d;
run;


/*///////////////////////////////////////////////////////////////////////////////
///		Create a separate dataset for each Cluster 1 -4  (hence c1, c2, c3, c4)
///
/*/

data c4;
	set db1;
	if studyref = "Bermudez2002";

	BMD_Krig  = 10.9276;
	BMDL_Krig = 9.4177;

run;

data c3;
	set db1;

	if study_key in ("100022", "100012");

	if study_key = "100022" then do;
		BMD_Krig = 6.83;
		BMDL_Krig = 1.8244;
	end;
	if study_key = "100012" then do;
		BMD_Krig = 7.39;
		BMDL_Krig = 1.9174;
	end;

run;

data c2;
	set db1;

	if ( study_key in ("100013", "100025") ) OR ( study_key = "100004" and material_type in ("Carboxylated", "control") );

	if study_key = "100013" then do;	
		BMD_Krig = 1.54;
		BMDL_Krig = 0.2785;
	end;
	if study_key = "100025" then do;	
		BMD_Krig = 2;
		BMDL_Krig = 1.9405;
	end;
	if study_key = "100004" then do;	
		BMD_Krig = 2.17;
		BMDL_Krig = 1.0489;
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
	   ( study_key = "100009" ) OR
	   ( study_key = "100010" );

	   /* NOTE --- BMDs and BMDLs are not transferred to controls */
	if study_key = "100001" and material_type = "NB2" and pe_d=1 then do;
		BMD_Krig = 0.23;
		BMDL_Krig = 0.1949;
	end;

	if study_key = "100001" and material_type = "NB2" and pe_d=3 then do;
		BMD_Krig = 0.25;
		BMDL_Krig = 0.1455;
	end;

	if study_key = "100008" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 0.27;
		BMDL_Krig = 0.0583;
	end;

	if study_key = "100017" and material_type = "uncoated" and pe_d=1 then do;
		BMD_Krig = 0.32;	
		BMDL_Krig = 0.2509;
	end;

	if study_key = "100011" and material_type = "short" and pe_d=1 then do;
		BMD_Krig = 0.38;	
		BMDL_Krig = 0.2622;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=1 then do;
		BMD_Krig = 0.46;
		BMDL_Krig = 0.3108;
	end;

	if study_key = "100004" and material_type = "Bare" and pe_d=1 then do;
		BMD_Krig = 0.46;
		BMDL_Krig = 0.358;
	end;

	if study_key = "100016" and material_type = "coated" and pe_d=1 then do;
		BMD_Krig = 0.7;	
		BMDL_Krig = 0.4591;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=3 then do;
		BMD_Krig = 0.82;	
		BMDL_Krig = 0.6058;
	end;

	if study_key = "100009" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 0.83;	
		BMDL_Krig = 0.1661;
	end;

	if study_key = "100010" and material_type = "short" and pe_d=1 then do;
		BMD_Krig = 0.91;	
		BMDL_Krig = 0.1617;
	end;

run;

proc sort data=c1 out=qc (keep=study_key studyref material material_type pe_d bmd_krig bmdl_krig) nodupkey;
	by study_key studyref material material_type pe_d bmd_krig bmdl_krig;
run;

/* drop the previously identified trouble makers (dupe pos and neg controls, bad Xia controls)  */
data c1_2;
	set c1;
	if ind_drop=0;
	/* 30 to drop --- 24 are missing Samp PMN %
					   6 are Negative Controls and have the alternate controls in the data */
			

	/* adjust Porter lengths */
	if material_type="NB1" then length=3; /* from pub, Mode/Median/Mean in 2-3 */
	if material_type="NB2" then length=9; /* from pub, Median/Mode=8-10, Mean = 9 */

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
		length="N/A";
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
	if length="" then length="N/A";
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
		length="N/A";
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
	if length="" then length="N/A";
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
		length="N/A";
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
	if length="" then length="N/A";
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
		length="N/A";
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
	if length="" then length="N/A";
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

/**** clean up the useless vars, like UNITS ****/;
data c1_3;
	set c1_2;

	cluster=1;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units;
run;

data c2_3;
	set c2_2;

	cluster=2;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units;
run;

data c3_3;
	set c3_2;

	cluster=3;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units;
run;

data c4_3;
	set c4_2;

	cluster=4;

	drop Aerodynamic_Diameter_Units Diameter_Units Length_Units Material_Lot_Number Material_Manufacturer Surface_Area_Method
	     Surface_Area_Units Zeta_Potential_Units;
run;

proc export data=c1_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust1.csv"
			replace dbms=csv;
run;
proc export data=c2_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust2.csv"
			replace dbms=csv;
run;
proc export data=c3_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust3.csv"
			replace dbms=csv;
run;
proc export data=c4_3 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\bmd_krig_clust4.csv"
			replace dbms=csv;
run;



/*///////////////////////////////////////////////////////////////////////////////
///		Plot the separate datasets for each Cluster 1 -4  (hence c1, c2, c3, c4)
///
///			Includes duplicate controls, but aren't visible (overlap)
/*/

proc sgplot data=c1;
	title "Dose-Response for Hierarchical Cluster 1";
	title2 "Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c2;
	title "Dose-Response for Hierarchical Cluster 2";
	title2 "Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c3;
	title "Dose-Response for Hierarchical Cluster 3";
	title2 "Kriging BMDs";
	scatter x=dep_dose_amount2 y=samppmnper;
run;

proc sgplot data=c4;
	title "Dose-Response for Hierarchical Cluster 4";
	title2 "Kriging BMDs";
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

/* (1) Length was the Most Important */
proc sgplot data=c_all;
	scatter x=cluster y=length;
run;
****	Oh boy, only Cluster 1 has lengths	***;

/* (2) Material Category */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * material_category / list missing nocum;
run;
****	Again, not insightful --- Carbon and Metal Oxide in each group		****;

/* (3) Crystal Type */
proc freq data=c_all;
	where material_category ne "Control";
	table cluster * crystal_type / list missing nocum;
run;
****	Some differences here in crystal types	****;

/* (4) Diameter */
proc sgplot data=c_all;
	scatter x=cluster y=diameter;
run;
proc sgplot data=c_all;
	where diameter > -99;
	scatter x=cluster y=diameter;
run;
****	Kind of interesting --- a negative association between Cluster and Diameter
		The bigger the diameter, the smaller the cluster = smaller BMD
		Does that make sense?															**** ;


/* (5) Material */
proc freq data=c_all;
	*where material_category ne "Control";
	table cluster * material / list missing nocum;
run;
****	Yep, not insightful		****;

/* (6) Surface Area */
proc sgplot data=c_all;
	scatter x=cluster y=surface_area;
run;
proc sgplot data=c_all;
	where surface_area > -99;
	scatter x=cluster y=surface_area;
run;

proc freq data=c_all;
	table surface_area / missing list nocum;
run;
****	Not a whole lot happening here	****;


proc freq data=storage2.db28;
	where studyref="Bermudez2002";
	table Dep_LB_alv__v__2_90_1_ * dep_dose_amount / missing list nocum;
run;
