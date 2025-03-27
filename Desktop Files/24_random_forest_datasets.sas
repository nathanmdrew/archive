/*/////////////////////////////////////////////////
///		Dataset creation for the Random Forest
///			
/*/	

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */

libname storage2 "Z:\MyLargeWorkspace Backup\ENM Categories\DB\SAS Datasets";


data db1;
	set storage2.skeleton_pchem1_v5;

	if pe_d <= 3;
run;


/*///////////////////////////////////////////////////////////////////////////////
///		Create a separate dataset for each Cluster 1 -4  (hence c1, c2, c3, c4)
///
/*/

/*
Study	Reference		Material	Material Type		Post Exposure	Route	BMD		BMDL	Cluster
100017	ENPRA-RIVM		ZnO(3)		uncoated(14)		1				IT		18.88	11.99	1
100001	Porter2013		TiO2(1)		NB2(2)				1				PA		23.55	12.08	1
100001	Porter2013		TiO2(1)		NB2(2)				3				PA		23.63	13.96	1
100008	ENPRA-NRCWE		MWCNT(5)	long(18)			1				IT		30.35	1.74	1
100011	ENPRA-NRCWE		MWCNT(5)	short(17)			1				IT		37.51	23.11	1
100004	Sager2013		MWCNT(5)	Bare(10)			1				PA		45.79	31.43	1
100001	Porter2013		TiO2(1)		NB1(1)				1				PA		47.63	33.07	1
100009	ENPRA-NRCWE		MWCNT(5)	long(18)			1				IT		78.6	0.80	1
100001	Porter2013		TiO2(1)		NB1(1)				3				PA		82.11	51.09	1
100010	ENPRA-NRCWE		MWCNT(5)	short(17)			1				IT		85.49	1.34	1

100004	Sager2013		MWCNT(5)	Carboxylated(11)	1				PA		140.34	111.42	2
100013	ENPRA-RIVM		MWCNT(5)	short(17)			1				IT		198.22	49.61	2
100016	ENPRA-RIVM		ZnO(3)		coated(13)			1				IT		292.23	68.06	2
100012	ENPRA-RIVM		MWCNT(5)	long(18)			1				IT		476.38	83.13	2

100025	Bermudez2004	TiO2(1)		Ultrafine(16)		0				Inh		661.85	546.55	3
100022	ENPRA-RIVM		TiO2(1)		rutile(21)			1				IT		771.74	184.57	3

100024	Bermudez2002	TiO2(1)		fine(23)			0				Inh		3309.27	3106.32	4
*/

data c4;
	set db1;
	if studyref = "Bermudez2002";

	BMD_Krig  = 3309.21;
	BMDL_Krig = 3106.32;

run;

data c3;
	set db1;

	if study_key in ("100022", "100025");

	if study_key = "100022" then do;
		BMD_Krig = 771.74;
		BMDL_Krig = 184.57;
	end;
	if study_key = "100025" then do;
		BMD_Krig = 661.85;
		BMDL_Krig = 546.55;
	end;

run;

data c2;
	set db1;

	if ( study_key in ("100013", "100016", "100012") ) OR ( study_key = "100004" and material_type in ("Carboxylated", "control") );

	if study_key = "100013" then do;		
		BMD_Krig = 198.22;
		BMDL_Krig = 49.61;
	end;
	if study_key = "100016" then do;		
		BMD_Krig = 292.23;
		BMDL_Krig = 68.06;
	end;
	if study_key = "100012" then do;		
		BMD_Krig = 476.38;
		BMDL_Krig = 83.13;
	end;
	if study_key = "100004" then do;		
		BMD_Krig = 140.34;
		BMDL_Krig = 111.42;
	end;

run;

data c1;
	set db1;
			
	if ( study_key = "100001" and material_type in ("NB1", "NB2", "control") ) OR
	   ( study_key = "100008" ) OR
	   ( study_key = "100017" ) OR
	   ( study_key = "100011" ) OR
	   ( study_key = "100004" and material_type in ("Bare", "control") ) OR
	   ( study_key = "100009" ) OR
	   ( study_key = "100010" );

	   /* NOTE --- BMDs and BMDLs are not transferred to controls used multiple times */
	if study_key = "100001" and material_type = "NB2" and pe_d=1 then do;
		BMD_Krig = 23.55;
		BMDL_Krig = 12.08;
	end;

	if study_key = "100001" and material_type = "NB2" and pe_d=3 then do;
		BMD_Krig = 23.63;
		BMDL_Krig = 13.96;
	end;

	if study_key = "100008" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 30.57;
		BMDL_Krig = 1.74;
	end;

	if study_key = "100017" and material_type = "uncoated" and pe_d=1 then do;
		BMD_Krig = 18.88;	
		BMDL_Krig = 11.99;
	end;

	if study_key = "100011" and material_type = "short" and pe_d=1 then do;
		BMD_Krig = 37.51;	
		BMDL_Krig = 23.11;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=1 then do;
		BMD_Krig = 47.63;
		BMDL_Krig = 33.07;
	end;

	if study_key = "100004" and material_type = "Bare" and pe_d=1 then do;
		BMD_Krig = 45.79;	
		BMDL_Krig = 31.43;
	end;

	if study_key = "100009" and material_type = "long" and pe_d=1 then do;
		BMD_Krig = 78.60;		
		BMDL_Krig = 0.80;
	end;

	if study_key = "100001" and material_type = "NB1" and pe_d=3 then do;
		BMD_Krig = 82.11;		
		BMDL_Krig = 51.09;
	end;

	if study_key = "100010" and material_type = "short" and pe_d=1 then do;
		BMD_Krig = 85.49;		
		BMDL_Krig = 1.34;
	end;


run;


proc sort data=c1 out=qc (keep=study_key studyref material material_type pe_d bmd_krig bmdl_krig) nodupkey;
	by study_key studyref material material_type pe_d bmd_krig bmdl_krig;
run;




/*///////////////////////////////////////////////////////////////////////////////
///		Create a dataset of unique pchem for the 17 materials
///
/*/

* Diameter
Crystal Type
Length
Surface Area
Material
Density
Modificaiton
Functionalized Type
Zeta Potential
Median Aerodynamic Diameter
Aerodynamic Diameter GSD
Structural Form
Crystal Structure
Scale
Material Category
Purification Type
;

proc contents data=db1;
run;

proc sort data=db1 out=pchem1(keep=study_key studyref material material_type pe_d route diameter crystal_type length surface_area density modification functionalized_type
		zeta_potential median_aerodynamic_diameter aerodynamic_diameter_gsd structural_form crystal_structure_ scale material_category 
		purification_type Coated_Type) nodupkey;
	by study_key studyref material material_type pe_d route diameter crystal_type length surface_area density modification functionalized_type
		zeta_potential median_aerodynamic_diameter aerodynamic_diameter_gsd structural_form crystal_structure_ scale material_category 
		purification_type Coated_Type;
run;

data pchem2;
	set pchem1;
	if material_category = "Control" then delete;
run;

data pchem3;
	set pchem2;

	cluster=0;
	if studyref = "Bermudez2002" then cluster=4;

	if study_key in ("100022", "100025") then cluster=3;

	if ( study_key in ("100013", "100016", "100012") ) OR ( study_key = "100004" and material_type in ("Carboxylated") )then cluster=2;

	if ( study_key = "100001" and material_type in ("NB1", "NB2") ) OR
	   ( study_key = "100008" ) OR
	   ( study_key = "100017" ) OR
	   ( study_key = "100011" ) OR
	   ( study_key = "100004" and material_type in ("Bare") ) OR
	   ( study_key = "100009" ) OR
	   ( study_key = "100010" )then cluster=1;
run;

proc freq data=pchem3;
	table cluster;
run;

data pchem4;
	set pchem3;
	
	if cluster > 0;
	drop study_key studyref material_type pe_d route ;

	if median_aerodynamic_diameter="" then median_aerodynamic_diameter="N/A";
	if aerodynamic_diameter_gsd="" then aerodynamic_diameter_gsd="N/A";
	if length="" then length=-99;
	if surface_area=. then surface_area=-99;
	if density=. then density=-99;
	if zeta_potential=. then zeta_potential=-99;

run;

proc export data=pchem4 outfile="Z:\MyLargeWorkspace Backup\ENM Categories\BMD Cluster Random Forest\clusters_pchems_26jul2016.csv" replace;
run;



