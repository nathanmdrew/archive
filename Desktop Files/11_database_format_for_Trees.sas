/*

   Create a dataset with no missing responses
		summarize change

   fill in missings with an indicator
		categorical = "Missing"
		quantitative = -999, 999, 0, etc.

   save dataset

   boost and randomForest (and tree)

*/

options nocenter nonumber nodate ls=80 formdlim="*" mprint symbolgen;

/*  Repository for various versions of the SAS database and other datasets */
libname storage "Y:\ENM Categories\DB\SAS Datasets";


data one;
	set storage.skeleton_pchem1_v2;
	if samppmnper=. then delete;
	/* 336 missing response - details found in data background doc */
run;

proc contents data=one out=contents;
run;

proc freq data=one;
	table material_type / missing list nocum;
run;

data qc;
	set one;
	if Coated_Type="";
run;

/* begin filling in missing values of "useful" vars i.e. not UNITS vars */
data two;
	set one;

	if material_type in ("control1", "control2", "control3", "control4", "control5", "control1", 
						 "control1", "control1", "controlIonized1", "controlIonized2", "controlColloid1",
						 "controlColloid2") then material_type = "control";

	***** Often missings represent controls *******;
	if Aerodynamic_Diameter_GSD = "" then Aerodynamic_Diameter_GSD = "MISSING";
	if Aerodynamic_Diameter_Units = "" then Aerodynamic_Diameter_Units = "N/A";
	if Agglomerated_ = "" then Agglomerated_ = "MISSING";
	if Coated_Type = "" then Coated_Type = "N/A"; *match other missings;
	if Contaminant_Amount = . then Contaminant_Amount = -99;
	if Contaminant_Type = "" then Contaminant_Type = "N/A"; *match other missings;
	if Contaminants_ = "" then Contaminants_="N"; *match other missings - N is default;
	if Crystal_Structure_ = "" then Crystal_Structure_ = "N"; 
	if Crystal_Type = "" then Crystal_Type = "N/A";
	if Density = . then Density = -99;
	if Diameter = . then Diameter = -99;
	if Diameter_Units = "" then Diameter_Units = "N/A";
	if Entangled = "" then Entangled = "N";
	if Functionalized_Type = "" then Functionalized_Type = "N/A";
	if Ground_Type = "" then Ground_Type = "N/A"; *all are N/A;
	if Length = "" then Length = "MISSING"; * could convert this to numeric, use a middle value for the ranges ;
	if Length_Units = "" then Length_Units = "N/A";
	if Material_Lot_Number = "" then Material_Lot_Number = "N/A";
	if Material_Manufacturer = "" then Material_Manufacturer = "N/A";
	if Median_Aerodynamic_Diameter = "" then Median_Aerodynamic_Diameter = "MISSING";
	if Modification = "" then Modification = "N/A";
	if Purification_Type = "" then Purification_Type = "N/A";
	if Rigidity = "" then Rigidity = "MISSING"; *all obs;
	if Scale = "" then Scale = "N/A"; *reflects control scale ;
	if Solubility = "" then Solubility = "MISSING"; *all obs;
	if Solubility_Method = "" then Solubility_Method = "N/A";
	if Structural_Form = "" then Structural_Form = "N/A";
	if Surface_Area = . then Surface_Area = -99;
	if Surface_Area_Method = "" then Surface_Area_Method = "N/A";
	if Surface_Area_Units = "" then Surface_Area_Units = "N/A";
	if Surface_Charge = "" then Surface_Charge = "MISSING"; *all obs;
	if Volume = "" then Volume = "MISSING"; *all obs;
	if Zeta_Potential = . then Zeta_Potential = -999; * trickier, since ZP is continuous.  -999 should be different enough ;
	if Zeta_Potential_Units = "" then Zeta_Potential_Units = "N/A";
run;

data storage.skeleton_pchem1_v2_IMPUTE;
	set two;
run;

proc export data=two outfile="Y:\ENM Categories\DB\skeleton_and_physiochemical_30oct2015_IMPUTE.csv" dbms=csv replace;
run;

























